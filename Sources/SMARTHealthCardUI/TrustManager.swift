//
//  TrustManager.swift
//  SMARTHealthCardUI
//
//  Created by David Carlson on 12/10/25.
//

import SwiftUI

@Observable
public class TrustManager {
	
	public private(set) var issuerDirectory: IssuerDirectory?
	
	/// key = iss, value = TrustedIssuer
	public private(set) var issuerMap: [String: TrustedIssuer] = [:]
	
	public init() {}
	
	public func trustedIssuer(iss: String?) -> TrustedIssuer? {
		iss != nil ? issuerMap[iss!] : nil
	}
	
	public func isTrusted(iss: String?) -> Bool {
		iss != nil && issuerMap[iss!] != nil ? true : false
	}
	
	public func loadIssuerDirectory() async throws {
		guard let fileURL = Bundle.module.url(forResource: "vci-issuers", withExtension: "json")
		else {
			//TODO: throw error
			return
		}
		
		issuerDirectory = try JSONDecoder().decode(IssuerDirectory.self, from: try! Data(contentsOf: fileURL))
		for issuer in issuerDirectory?.participating_issuers ?? [] {
			issuerMap[issuer.iss] = issuer
			if let canonical_iss = issuer.canonical_iss {
				issuerMap[canonical_iss] = issuer
			}
		}
		
		//TODO: debug logger
		print("Loaded Issuer Directory with \(issuerDirectory?.participating_issuers.count ?? 0) entries.")
	}
	
}
