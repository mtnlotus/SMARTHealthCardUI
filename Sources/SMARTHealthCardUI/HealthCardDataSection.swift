//
//  HealthCardDataSection.swift
//  SMARTHealthCardUI
//
//  Created by David Carlson on 2/3/26.
//

import SwiftUI
import SMARTHealthCard
import ModelsR4

public struct HealthCardDataSection: View {
	
	@Environment(TrustManager.self) private var trustManager
	
	private let healthCardModel: HealthCardModel
	
	private var healthDataFooter: String {
		guard healthCardModel.jwsCharacterCount > 0 else { return "" }
		return "QR Code contains \(healthCardModel.jwsCharacterCount) characters (max 1195)"
	}
	
	public init(for healthCardModel: HealthCardModel) {
		self.healthCardModel = healthCardModel
	}
	
	public var body: some View {
		if healthCardModel.healthCardPayload != nil {
			Section(header: Text("Health Card Data"), footer: Text(healthDataFooter)) {
				if healthCardModel.resourceModels.isEmpty {
					Text("No FHIR resources found")
				}
				else {
					ForEach(healthCardModel.resourceModels) { model in
						ResourceView(resourceModel: model)
					}
				}
			}
		}
	}
}

#Preview {
	@Previewable @State var terminologyManager = TerminologyManager()
	@Previewable @State var trustManager = TrustManager()
	@Previewable @State var healthCardModel = HealthCardModel(numericSerialization: PreviewData.qrCodeNumeric)
	
	NavigationStack {
		List {
			HealthCardDataSection(for: healthCardModel)
		}
		.navigationTitle("SMART Health Card")
		.environment(terminologyManager)
		.environment(trustManager)
		.navigationDestination(for: Resource.self) { resource in
			ResourceDetailView(resource)
		}
	}
}

