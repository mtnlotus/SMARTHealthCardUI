//
//  VerificationView.swift
//  SMARTHealthCardUI
//
//  Created by David Carlson on 12/11/25.
//

import SwiftUI
import SMARTHealthCard

struct VerificationView: View {
	@Environment(TrustManager.self) private var trustManager

	private let healthCardModel: HealthCardModel
	
	init(for healthCardModel: HealthCardModel) {
		self.healthCardModel = healthCardModel
	}
	
	private var verificationFooter: String {
		guard healthCardModel.hasVerifiedSignature == true else { return "" }
		return "Verified records have not been changed since originally created."
	}
	
	@ViewBuilder private var trustedImage: some View {
		if true == trustManager.isTrusted(iss: healthCardModel.healthCardPayload?.issuer) {
			Image(systemName: "checkmark.seal")
				.font(.title3)
				.foregroundStyle(.green)
		}
	}
	
	@ViewBuilder private var unknownTrustImage: some View {
		if false == trustManager.isTrusted(iss: healthCardModel.healthCardPayload?.issuer) {
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
		let nameLink = issuer?.website != nil ? "[\(name)](\(issuer!.website!))" : name
		HStack {
			trustedImage
			// Use LocalizedStringKey to render markdown in nameLink.
			Text(LocalizedStringKey(nameLink))
		}
	}
	
	@ViewBuilder private var qrCodeImage: some View {
		if let uiImage = healthCardModel.qrCodeImage {
			Section {
				HStack {
					Spacer()
					Image(uiImage: uiImage)
						.interpolation(.none)
						.resizable()
						.scaledToFit()
						.frame(width: 200, height: 200)
					Spacer()
				}
			}
		}
	}
	
    var body: some View {
		if let smartHealthCard = healthCardModel.healthCardPayload {
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
				
				qrCodeImage
			}
			.task {
				await healthCardModel.verifySignature()
			}
		}
    }
}

#Preview {
	@Previewable @State var terminologyManager = TerminologyManager()
	@Previewable @State var trustManager = TrustManager()
	@Previewable @State var healthCardModel = HealthCardModel(numericSerialization: PreviewData.qrCodeNumeric)
	
	List {
		VerificationView(for: healthCardModel)
	}
	.environment(terminologyManager)
	.environment(trustManager)
}
