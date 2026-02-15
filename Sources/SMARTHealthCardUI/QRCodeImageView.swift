//
//  QRCodeImageView.swift
//  SMARTHealthCardReader
//
//  Created by David Carlson on 2/3/26.
//


import SwiftUI
import SMARTHealthCard

struct QRCodeImageView: View {
	private let healthCardModel: HealthCardModel
	
	init(for healthCardModel: HealthCardModel) {
		self.healthCardModel = healthCardModel
	}
	
	var body: some View {
		if let uiImage = healthCardModel.qrCodeImage {
			HStack {
				Spacer()
				Image(uiImage: uiImage)
					.interpolation(.none)
					.resizable()
					.scaledToFit()
					.frame(maxWidth: 300, maxHeight: 300)
					// SHC spec aims for 40mm x 40mm QR code when printed = 240 points on iPhone 16 Pro Max
					// Choose a bit larger maxWidth of 300 for screen display
				Spacer()
			}
		}
	}
}
