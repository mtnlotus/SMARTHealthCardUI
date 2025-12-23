//
//  VerificationView.swift
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
	
	@ViewBuilder private var trustedImage: some View {
		if true == trustManager.isTrusted(iss: healthCardModel.smartHealthCard?.issuer) {
			Image(systemName: "checkmark.seal")
				.font(.title3)
				.foregroundStyle(.green)
		}
	}
	
	@ViewBuilder private var unknownTrustImage: some View {
		if false == trustManager.isTrusted(iss: healthCardModel.smartHealthCard?.issuer) {
			Image(systemName: "xmark.seal")
				.font(.title3)
				.foregroundStyle(.red)
		}
	}
	
	@ViewBuilder private var verifiedSignatureView: some View {
		HStack {
			if healthCardModel.hasVerifiedSignature == true {
				Image(systemName: "key.shield")
					.font(.title3)
					.foregroundStyle(.green)
				Text("Valid Signature")
			}
			else {
				Image(systemName: "xmark.shield")
					.font(.title3)
					.foregroundStyle(.red)
				Text("Not Verified")
			}
		}
	}
	
	@ViewBuilder private func issuerNameView(iss: String) -> some View {
		let issuer = trustManager.issuer(iss: iss)
		let name = issuer?.name ?? URL(string: iss)?.host() ?? iss
		var nameLink = name
		if let website = issuer?.website {
			nameLink = "[\(name)](\(website))"
		}
		return HStack {
			trustedImage
			// Use LocalizedStringKey to render markdown in nameLink.
			Text(LocalizedStringKey(nameLink))
		}
	}
	
    var body: some View {
		if let smartHealthCard = healthCardModel.smartHealthCard {
			Section(header: Text("Record Verification"), footer: Text(verificationFooter)) {
				VStack(alignment: .leading) {
					Text("Credentials signed by")
						.foregroundStyle(.secondary)
					issuerNameView(iss: smartHealthCard.issuer)
				}
				HStack {
					Text("Status")
						.foregroundStyle(.secondary)
					Spacer()
					verifiedSignatureView
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
				do {
					try await healthCardModel.verifySignature()
				}
				catch {
					healthCardModel.addMessage(error)
				}
			}
		}
    }
}

#Preview {
	@Previewable @State var terminologyManager = TerminologyManager()
	@Previewable @State var trustManager = TrustManager()
	@Previewable @State var healthCareModel = HealthCardModel(numericSerialization: PreviewData.qrCodeNumeric)
	
	List {
		VerificationView()
	}
	.environment(terminologyManager)
	.environment(trustManager)
	.environment(healthCareModel)
}
