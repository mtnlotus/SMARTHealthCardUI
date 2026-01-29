//
//  VerificationView.swift
//  SMARTHealthCardUI
//
//  Created by David Carlson on 1/22/26.
//

import SwiftUI
import SMARTHealthCard

public struct VerificationView: View {
	@Environment(TrustManager.self) private var trustManager

	private let healthCardModel: HealthCardModel
	
	public init(for healthCardModel: HealthCardModel) {
		self.healthCardModel = healthCardModel
	}
	
	public var body: some View {
		VStack(alignment: .leading, spacing: 20) {
			VerificationContent(for: healthCardModel)
			Spacer()
		}
		.padding(20)
		.onAppear {
			healthCardModel.trustManager = trustManager
		}
	}
}

#Preview {
	@Previewable @State var trustManager = TrustManager()
	@Previewable @State var healthCardModel = HealthCardModel(numericSerialization: PreviewData.qrCodeNumeric)
	
	VerificationView(for: healthCardModel)
		.environment(trustManager)
}
