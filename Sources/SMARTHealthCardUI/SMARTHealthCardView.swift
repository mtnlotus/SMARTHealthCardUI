//
//  SMARTHealthCardView.swift
//  SMARTHealthCardDemo
//
//  Created by David Carlson on 11/19/25.
//

import SwiftUI
import ModelsR4
import SMARTHealthCard
import FHIRFoundation

public struct SMARTHealthCardView: View {
	
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
			VerificationSection(for: healthCardModel)
			HealthCardDataSection(for: healthCardModel)
		}
		
		if !healthCardModel.messages.isEmpty {
			Section("Messages") {
				ForEach(healthCardModel.messages) { message in
					Text(message.text)
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
			SMARTHealthCardView(for: healthCardModel)
		}
		.navigationTitle("SMART Health Card")
		.environment(terminologyManager)
		.environment(trustManager)
		.navigationDestination(for: ResourceProxy.self) { proxy in
			ResourceDetailView(proxy.get())
		}
	}
}
