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
					.frame(width: 200, height: 200)
				Spacer()
			}
		}
	}
}
