//
//  QRCodeScannerButton.swift
//  SMARTHealthCardDemo
//
//  Created by David Carlson on 11/19/25.
//

import SwiftUI
import SMARTHealthCard
import CodeScanner
internal import AVFoundation

public struct QRCodeScannerButton: View {
	
	private let healthCardModel: HealthCardModel
	
    @State private var isPresentingScanner = false
	
	@State private var isGalleryPresented = false
	
	public init(for healthCardModel: HealthCardModel) {
		self.healthCardModel = healthCardModel
	}
	
    public var body: some View {
		HStack(spacing: 10) {
			Button(action: {
				healthCardModel.numericSerialization = nil
				isPresentingScanner = true
			})
			{
				Text("Scan QR Code")
					.font(.headline)
					.padding(10)
			}
			.buttonStyle(.borderedProminent)
			
			Image(systemName: "camera")
				.font(.title)
		}
		.frame(minWidth: 200, maxWidth: .infinity, minHeight: 40)
        .sheet(isPresented: $isPresentingScanner) {
			CodeScannerView(codeTypes: [.qr], scanMode: .oncePerCode, scanInterval: 1.0, showViewfinder: true, isGalleryPresented: $isGalleryPresented) { response in
                if case let .success(result) = response {
					healthCardModel.numericSerialization = result.string
                    isPresentingScanner = false
                }
            }
        }
    }
}

#Preview {
	@Previewable @State var healthCardModel = HealthCardModel()
	VStack {
		List {
			QRCodeScannerButton(for: healthCardModel)
		}
	}
}
