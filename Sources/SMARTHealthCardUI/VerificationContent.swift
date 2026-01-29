//
//  VerificationContent.swift
//  SMARTHealthCardUI
//
//  Created by David Carlson on 1/22/26.
//

import SwiftUI
import SMARTHealthCard

struct VerificationContent: View {
	@Environment(TrustManager.self) private var trustManager

	private let healthCardModel: HealthCardModel
	
	init(for healthCardModel: HealthCardModel) {
		self.healthCardModel = healthCardModel
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
		let issuerInfo = trustManager.issuer(iss: iss)
		let name = issuerInfo?.issuer.name ?? URL(string: iss)?.host() ?? iss
		let nameLink = issuerInfo?.issuer.website != nil ? "[\(name)](\(issuerInfo!.issuer.website!))" : name
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
			Group {
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
				
				HStack {
					Text("Contains \(healthCardModel.fhirResources.count) entries")
					Spacer()
				}
			}
		}
	}
}

#Preview {
	@Previewable @State var trustManager = TrustManager()
	@Previewable @State var healthCardModel = HealthCardModel(numericSerialization: PreviewData.qrCodeNumeric)
	
	VStack(alignment: .leading, spacing: 20) {
		VerificationContent(for: healthCardModel)
		Spacer()
	}
	.padding(20)
	.environment(trustManager)
}
