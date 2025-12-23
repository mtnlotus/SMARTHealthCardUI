//
//  ErrorMessage.swift
//  SMARTHealthCardUI
//
//  Created by David Carlson on 12/21/25.
//

import Foundation
import SMARTHealthCard
import OSLog

public struct ErrorMessage: Identifiable {
	
	public let id: String = UUID().uuidString
	
	public let error: Error?
	
	public let text: String
	
	public init(message: String) {
		self.error = nil
		self.text = message
		Logger.messages.info("\(message)")
	}
	
	public init(error: Error) {
		self.error = error
		self.text = error.localizedDescription
		Logger.messages.error("\(error.localizedDescription)")
	}
}
