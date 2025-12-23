//
//  Logger.swift
//  SMARTHealthCardUI
//
//  Created by David Carlson on 12/22/25.
//

import OSLog

extension Logger {
	/// Messages displayed to the user..
	static let messages = Logger(subsystem: Bundle.module.bundleIdentifier!, category: "messages")
	
	/// Logs related to SMART Health Card verification.
	static let verification = Logger(subsystem: Bundle.module.bundleIdentifier!, category: "verification")
	
	/// Logs the view cycles like a view that appeared.
	static let viewCycle = Logger(subsystem: Bundle.module.bundleIdentifier!, category: "viewcycle")

	/// All logs related to tracking and analytics.
	static let statistics = Logger(subsystem: Bundle.module.bundleIdentifier!, category: "statistics")
}
