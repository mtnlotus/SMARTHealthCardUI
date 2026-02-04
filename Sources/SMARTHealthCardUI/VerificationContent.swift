//
//  VerificationContent.swift
//  SMARTHealthCardUI
//
//  Created by David Carlson on 1/22/26.
//

import SwiftUI
import SMARTHealthCard
import ModelsR4

struct VerificationContent: View {
	@Environment(TrustManager.self) private var trustManager

	private let healthCardModel: HealthCardModel
	
	private var patient: Patient? {
		healthCardModel.fhirResources.first(where: {type(of: $0).resourceType == .patient}) as? Patient
	}
	
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
	
	private var entryTypes: [ResourceType] {
		healthCardModel.fhirResources.map { type(of: $0).resourceType }
	}
	
	private var listedTypes: [ResourceType] = [
		.patient, .goal, .condition, .medication, .immunization, .procedure, .serviceRequest, .observation
	]
	
	private var summaryTypes: [ResourceType] {
		listedTypes.filter { entryTypes.contains($0) }
	}
	
	/// Build a simple comma-separated summary of  categories present in the health card entries.
	private var summaryText: String {
		let names = summaryTypes.map { $0.rawValue }
		if names.isEmpty {
			return ""
		}
		if names.count == 1 {
			return names[0]
		}
		// Oxford comma style: "A, B, and C"
		let allButLast = names.dropLast().joined(separator: ", ")
		let last = names.last!
		return "\(allButLast), and \(last)"
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
				if let patient = patient {
					ResourceSummary(patient)
				}
				
				Text("Contains \(healthCardModel.fhirResources.count) entries including \(summaryText).")
			}
		}
	}
}

#Preview {
	@Previewable @State var trustManager = TrustManager()
	@Previewable @State var terminologyManager = TerminologyManager()
	@Previewable @State var healthCardModel = HealthCardModel(numericSerialization: PreviewData.qrCodeNumeric)
	
	VStack(alignment: .leading, spacing: 20) {
		VerificationContent(for: healthCardModel)
		Spacer()
	}
	.padding(20)
	.environment(trustManager)
	.environment(terminologyManager)
}
