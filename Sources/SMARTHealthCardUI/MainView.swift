//
//  MainView.swift
//  SMARTHealthCardUI
//
//  Created by David Carlson on 12/16/25.
//

import SwiftUI
import ModelsR4
import SMARTHealthCard

public struct MainView: View {
	
	@State private var healthCardModel: HealthCardModel
	
	public init(for healthCardModel: HealthCardModel? = nil) {
		self.healthCardModel = healthCardModel ?? HealthCardModel()
	}
	
	public var body: some View {
		NavigationStack {
			List {
				Section {
					QRCodeScannerButton(for: healthCardModel)
				}
				.listRowBackground(Color.clear)
				
				SMARTHealthCardView(for: healthCardModel)
			}
			.navigationDestination(for: Resource.self) { resource in
				ResourceDetailView(resource)
			}
			.navigationTitle("SMART Health Card")
		}
	}
}

#Preview {
	@Previewable @State var terminologyManager = TerminologyManager()
	@Previewable @State var trustManager = TrustManager()
	@Previewable @State var healthCardModel = HealthCardModel(numericSerialization: PreviewData.qrCodeNumeric)
	
	MainView(for: healthCardModel)
		.environment(terminologyManager)
		.environment(trustManager)
}
