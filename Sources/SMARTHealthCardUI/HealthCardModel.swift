//
//  HealthCardModel.swift
//  SMARTHealthCardDemo
//
//  Created by David Carlson on 11/19/25.
//

import SwiftUI
import SMARTHealthCard
import class ModelsR4.Resource
import CryptoKit

@Observable public class HealthCardModel {
	
	public init(numericSerialization: String? = nil) {
		self.numericSerialization = numericSerialization
	}
	
	/// JWS Size = ((Total Data Bits - 76 bits reserved) * 6/20 bits per numeric character * 1/2 JWS character per numeric character = (Total Data Bits - 76)*3/20
	public var jwsCharacterCount: Int {
		if let dataBits = numericSerialization {
			return (dataBits.count - 76) * 3 / 20
		}
		return 0
	}
	
	public var numericSerialization: String? {
		didSet {
			self.error = nil
			do {
				if let data = numericSerialization {
					let jws = try JWS(fromNumeric: data)
					self.jws = jws
					self.smartHealthCard = try JSONDecoder().decode(SMARTHealthCardPayload.self, from: jws.payload)
					self.jwsHeader = try JSONDecoder().decode(JWSHeader.self, from: Base64URL.decode(jws.header))
//					verifySignature()
				}
				else {
					jws = nil
					smartHealthCard = nil
					jwsHeader = nil
					hasVerifiedSignature = nil
				}
			}
			catch {
				self.error = error
			}
		}
	}
	
	public private(set) var jws: JWS?
	
	public private(set) var jwsHeader: JWSHeader?
	
	public private(set) var smartHealthCard: SMARTHealthCardPayload?
	
	public private(set) var hasVerifiedSignature: Bool?
	
	public private(set) var error: Error?
	
	public var fhirResources: [Resource] {
		smartHealthCard?.vc.credentialSubject.fhirBundle?.entry?.compactMap { $0.resource?.get() } ?? []
	}
	
	public var resourceModels: [ResourceModel] {
		fhirResources.map { ResourceModel($0) }
	}
	
	@MainActor
	public func verifySignature() async throws {
		do {
			self.hasVerifiedSignature = try await verifySignatureAsync()
		}
		catch {
			self.error = error
		}
	}
	
	@MainActor
	private func verifySignatureAsync() async throws -> Bool {
		guard let payload = smartHealthCard, let header = jwsHeader else {
			return false
		}
//		let issuerIdentifier = smartHealthCard.iss
//        guard URLIsTrusted(url: issuerIdentifier) else {
//            throw VerificationError.untrustedIssuer(issuerIdentifier)
//        }
		
		// The standard URL to locate an issuer's signing public keys is
		// constructed by appending `/.well-known/jwks.json` to
		// the issuer's identifier.
		let urlString = payload.iss + "/.well-known/jwks.json"
		guard let url = URL(string: urlString) else {
			throw VerificationError.unableToParseIssuerURL(urlString)
		}
		
		let configuration = URLSessionConfiguration.ephemeral
		configuration.timeoutIntervalForResource = 5.0
		let session = URLSession(configuration: configuration)
		let (data, _) = try await session.data(from: url, delegate: nil)
		let keySet = try JSONDecoder().decode(JWKSet.self, from: data)
		let signingKey = try keySet.key(with: header.kid)
		
		return try signatureIsValid(signingKey: signingKey)
	}
	
	/*
	 TODO: lookup registered issuers
	 */
	private func URLIsTrusted(url: String) -> Bool {
		// The set of issuers to trust.
		let trustedURLs: Set = [
			"https://smarthealth.cards/examples/issuer",
			"https://spec.smarthealth.cards/examples/issuer"
		]
		return trustedURLs.contains(url)
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
