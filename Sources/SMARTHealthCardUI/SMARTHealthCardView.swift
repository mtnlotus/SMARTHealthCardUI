//
//  SMARTHealthCardView.swift
//  SMARTHealthCardDemo
//
//  Created by David Carlson on 11/19/25.
//

import SwiftUI
import SMARTHealthCard
import ModelsR4

public struct SMARTHealthCardView: View {
	
	@Environment(HealthCardModel.self) private var healthCardModel
	@Environment(TrustManager.self) private var trustManager
	
	private var verificationFooter: String {
		guard healthCardModel.hasVerifiedSignature == true else { return "" }
		return "Verified records have not been changed since originally created."
	}
	
	private var healthDataFooter: String {
		guard healthCardModel.jwsCharacterCount > 0 else { return "" }
		return "QR Code contains \(healthCardModel.jwsCharacterCount) characters (max 1195)"
	}
	
	public init() { }
	
    public var body: some View {
		if let smartHealthCard = healthCardModel.smartHealthCard {
			VerificationView()
			
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
		
		if let error = healthCardModel.error {
			Section("Error Messages") {
				if let jwsError = error as? JWSError {
					Text("\(jwsError.description)")
				}
				else {
					Text("\(error.localizedDescription)")
				}
			}
		}
    }
}

#Preview {
	@Previewable @State var terminologyManager = TerminologyManager()
	@Previewable @State var trustManager = TrustManager()
	@Previewable @State var healthCareModel = HealthCardModel(numericSerialization: PreviewData.qrCodeNumeric)
	
	NavigationStack {
		List {
			SMARTHealthCardView()
		}
		.navigationTitle("SMART Health Card")
		.environment(terminologyManager)
		.environment(trustManager)
		.environment(healthCareModel)
	}
}
