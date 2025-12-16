//
//  SwiftUIView.swift
//  SMARTHealthCardUI
//
//  Created by David Carlson on 12/11/25.
//

import SwiftUI
import SMARTHealthCard

struct VerificationView: View {
	@Environment(HealthCardModel.self) private var healthCardModel
	@Environment(TrustManager.self) private var trustManager
	
	private var verificationFooter: String {
		guard healthCardModel.hasVerifiedSignature == true else { return "" }
		return "Verified records have not been changed since originally created."
	}
	
    var body: some View {
		Section(header: Text("Record Verification"), footer: Text(verificationFooter)) {
			   let issuerName = trustManager.trustedIssuer(iss: smartHealthCard.issuer)?.name ?? smartHealthCard.issuer
			   VStack(alignment: .leading) {
				   Text("Source").foregroundStyle(.secondary)
				   HStack {
					   if trustManager.isTrusted(iss: smartHealthCard.issuer) {
						   Image(systemName: "checkmark.shield")
							   .bold().foregroundStyle(.green)
					   }
					   Text("\(issuerName)")
				   }
			   }
			   HStack {
				   Text("Status").foregroundStyle(.secondary)
				   Spacer()
				   Text("\(healthCardModel.hasVerifiedSignature == true ? "✅ Valid Signature" : "❌ Not Verified")")
			   }
			   if let issueDate = smartHealthCard.issueDate {
				   HStack {
					   Text("Issued").foregroundStyle(.secondary)
					   Spacer()
					   Text("\(issueDate.mediumDateTimeFormat)")
				   }
			   }
			   if let expiresDate = smartHealthCard.expiresDate {
				   HStack {
					   Text("Expires").foregroundStyle(.secondary)
					   Spacer()
					   Text("\(expiresDate.mediumDateTimeFormat)")
				   }
			   }
		   }
		   .task {
			   try? await healthCardModel.verifySignature()
		   }
    }
}

#Preview {
    SwiftUIView()
}
