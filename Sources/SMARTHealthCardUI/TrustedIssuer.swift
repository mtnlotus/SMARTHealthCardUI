//
//  TrustedIssuer.swift
//  SMARTHealthCardUI
//
//  Created by David Carlson on 12/10/25.
//

public struct IssuerDirectory: Codable {
	public let participating_issuers: [TrustedIssuer]
}

public struct TrustedIssuer: Codable {
	public let iss: String
	public let canonical_iss: String?
	public let name: String
	public let website: String?
}
