//
//  TrustManager.swift
//  SMARTHealthCardUI
//
//  Created by David Carlson on 12/10/25.
//

import SwiftUI
import OSLog

@Observable
open class TrustManager {
	
	public private(set) var issuerDirectory: IssuerDirectory?
	
	/// key = iss, value = TrustedIssuer
	public private(set) var issuerMap: [String: TrustedIssuer] = [:]
	
	public init() {}
	
	public func issuer(iss: String?) -> TrustedIssuer? {
		iss != nil ? issuerMap[iss!] : nil
	}
	
	public func isTrusted(iss: String?) -> Bool {
		if let iss = iss, let issuer = issuerMap[iss], issuer.isTrusted == true {
			return true
		}
		return false
	}
	
	public func addIssuer(_ issuer: TrustedIssuer) {
		issuerMap[issuer.iss] = issuer
		if let canonical_iss = issuer.canonical_iss {
			issuerMap[canonical_iss] = issuer
		}
	}
	
	public func loadIssuerDirectory() async throws {
		guard let fileURL = Bundle.module.url(forResource: "vci-issuers", withExtension: "json")
		else {
			Logger.verification.error("Failed to read Issuer Directory file from app bundle.")
			//TODO: throw error
			return
		}
		
		issuerDirectory = try JSONDecoder().decode(IssuerDirectory.self, from: try! Data(contentsOf: fileURL))
		for var issuer in issuerDirectory?.participating_issuers ?? [] {
			issuer.isTrusted = true
			addIssuer(issuer)
		}
		
		Logger.statistics.info("Loaded Issuer Directory with \(self.issuerDirectory?.participating_issuers.count ?? 0) entries.")
	}
	
}
