//
//  HealthCardModel.swift
//  SMARTHealthCardDemo
//
//  Created by David Carlson on 11/19/25.
//

import SwiftUI
import SMARTHealthCard
import class ModelsR4.Resource
import class ModelsR4.Bundle
import CryptoKit
import OSLog

@Observable public class HealthCardModel {
	
	public init(numericSerialization: String? = nil) {
		self.numericSerialization = numericSerialization
	}
	
	/// JWS character size, where each character is represented by 2 digits.
	public var jwsCharacterCount: Int {
		if let numericData = numericSerialization {
			let dataString = String(numericData.trimmingPrefix("shc:/"))
			let characterCount: Int = dataString.count / 2
			return characterCount
		}
		return 0
	}
	
	public var numericSerialization: String? {
		didSet {
			self.messages = []
			do {
				if let data = numericSerialization {
					let dataString = String(data.trimmingPrefix("shc:/"))
					Logger.statistics.debug("Numerical serialization contains \(dataString.count) digits")
					Logger.statistics.debug("Numerical serialization contains \(self.jwsCharacterCount) characters of data")
					
					let jws = try JWS(fromNumeric: data)
					self.jws = jws
					self.healthCardPayload = try JSONDecoder().decode(HealthCardPayload.self, from: jws.payload)
					self.jwsHeader = try JSONDecoder().decode(JWSHeader.self, from: Base64URL.decode(jws.header))
				}
				else {
					jws = nil
					healthCardPayload = nil
					jwsHeader = nil
					hasVerifiedSignature = nil
				}
			}
			catch {
				addMessage(error)
			}
		}
	}
	
	public private(set) var jws: JWS?
	
	public private(set) var jwsHeader: JWSHeader?
	
	public private(set) var healthCardPayload: HealthCardPayload? {
		didSet {
			// TODO: delegate call-back
			// Maybe use a @Published var that will trigger Summary view .task
			
			if healthCardPayload != nil {
				Logger.statistics.info("Completed parsing SMART Health Card, found \(self.fhirResources.count) FHIR resources")
			}
		}
	}
	
	public private(set) var hasVerifiedSignature: Bool?
	
	public private(set) var messages: [ErrorMessage] = []
	
	public func addMessage(_ message: String) {
		self.messages.append(.init(message: message))
	}
	public func addMessage(_ error: Error) {
		self.messages.append(.init(error: error))
	}
	
	public var fhirResources: [Resource] {
		healthCardPayload?.vc.credentialSubject.fhirBundle?.entry?.compactMap { $0.resource?.get() } ?? []
	}
	
	public var resourceModels: [ResourceModel] {
		fhirResources.map { ResourceModel($0) }
	}
	
	@MainActor
	public func verifySignature() async {
		if hasVerifiedSignature == nil {
			do {
				self.hasVerifiedSignature = try await verifySignatureAsync()
			}
			catch {
				self.hasVerifiedSignature = false
				addMessage(error)
			}
		}
	}
	
	@MainActor
	private func verifySignatureAsync() async throws -> Bool {
		guard let payload = healthCardPayload, let header = jwsHeader else {
			return false
		}
		
		// The standard URL to locate an issuer's signing public keys is
		// constructed by appending `/.well-known/jwks.json` to
		// the issuer's identifier.
		let urlString = payload.iss + "/.well-known/jwks.json"
		guard let url = URL(string: urlString) else {
			throw VerificationError.unableToParseIssuerURL(urlString)
		}
		
		let signingKey: JWK
		do {
			let configuration = URLSessionConfiguration.ephemeral
			configuration.timeoutIntervalForResource = 5.0
			let session = URLSession(configuration: configuration)
			let (data, _) = try await session.data(from: url, delegate: nil)
			let keySet = try JSONDecoder().decode(JWKSet.self, from: data)
			signingKey = try keySet.key(with: header.kid)
		}
		catch {
			throw VerificationError.noPublicKeyFound
		}
		
		return try signatureIsValid(signingKey: signingKey)
	}
	
	private func signatureIsValid(signingKey: JWK) throws -> Bool {
		guard let jws = jws else {
			return false
		}
		let headerAndPayloadString = jws.header + "." + jws.payloadString
		guard let message = headerAndPayloadString.data(using: .utf8) else {
			throw VerificationError.failedToCreateUTF8DataFromString
		}
		
		let signingPublicKey = try signingKey.asP256PublicKey()
		let decodedSignature = try Base64URL.decode(jws.signature)
		let parsedECDSASignature = try P256.Signing.ECDSASignature(rawRepresentation: decodedSignature)
		return signingPublicKey.isValidSignature(parsedECDSASignature, for: message)
	}
}
