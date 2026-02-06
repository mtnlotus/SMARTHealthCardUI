//
//  VerificationView.swift
//  SMARTHealthCardUI
//
//  Created by David Carlson on 12/11/25.
//

import SwiftUI
import SMARTHealthCard

public struct VerificationSection: View {
	@Environment(TrustManager.self) private var trustManager

	private let healthCardModel: HealthCardModel
	
	public init(for healthCardModel: HealthCardModel) {
		self.healthCardModel = healthCardModel
	}
	
	private var verificationFooter: String {
		guard healthCardModel.hasVerifiedSignature == true else { return "" }
		return "Verified records have not been changed since originally created."
	}
	
	@State var showQRCode: Bool = false
	
	@ViewBuilder
	private var showQRCodeButton: some View {
		let buttonText = showQRCode ? "▼ Hide QR Code" : "▶︎ Show QR Code"
		Button(action: {
			withAnimation {
				showQRCode.toggle()
			}
		}) {
			Text(buttonText)
				.textCase(.none)
		}
		.animation(.default, value: showQRCode)
	}
	
    public var body: some View {
		if let smartHealthCard = healthCardModel.healthCardPayload {
			Section(header: Text("Record Verification"), footer: Text(verificationFooter)) {
				VerificationContent(for: healthCardModel)
				
				if let image = healthCardModel.qrCodeImage {
					Section(header: showQRCodeButton ) {
						if showQRCode {
							QRCodeImageView(for: healthCardModel)
						}
					}
				}
			}
			.onAppear {
				healthCardModel.trustManager = trustManager
			}
		}
    }
}

#Preview {
	@Previewable @State var trustManager = TrustManager()
	@Previewable @State var healthCardModel = HealthCardModel(numericSerialization: PreviewData.qrCodeNumeric)
	
	List {
		VerificationSection(for: healthCardModel)
	}
	.environment(trustManager)
}
