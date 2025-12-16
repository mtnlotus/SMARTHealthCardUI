//
//  MainView.swift
//  SMARTHealthCardUI
//
//  Created by David Carlson on 12/16/25.
//

import SwiftUI
import ModelsR4

struct MainView: View {
	
	var body: some View {
		NavigationStack {
			List {
				Section {
					QRCodeScannerButton()
				}
				.listRowBackground(Color.clear)
				
				SMARTHealthCardView()
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
	@Previewable @State var healthCareModel = HealthCardModel(numericSerialization: PreviewData.qrCodeNumeric)
	
	MainView()
		.environment(terminologyManager)
		.environment(trustManager)
		.environment(healthCareModel)
}
