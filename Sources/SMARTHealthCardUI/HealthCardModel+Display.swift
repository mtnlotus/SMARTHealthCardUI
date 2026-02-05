//
//  HealthCardModel+Display.swift
//  SMARTHealthCardUI
//
//  Created by David Carlson on 2/5/26.
//

import SMARTHealthCard
import ModelsR4

public extension HealthCardModel {
	
	static private var listedTypes: [ResourceType] = [
		.patient, .goal, .condition, .medication, .immunization, .procedure, .serviceRequest, .observation
	]
	
	private var entryTypes: [ResourceType] {
		fhirResources.map { type(of: $0).resourceType }
	}
	
	private var summaryTypes: [ResourceType] {
		HealthCardModel.listedTypes.filter { entryTypes.contains($0) }
	}
	
	/// Build a simple comma-separated summary of categories present in the health card entries.
	public var contentSummaryText: String {
		let names = summaryTypes.map { $0.rawValue }
		if names.isEmpty {
			return ""
		}
		if names.count == 1 {
			return names[0]
		}
		// Oxford comma style: "A, B, and C"
		let allButLast = names.dropLast().joined(separator: ", ")
		let last = names.last!
		return "\(allButLast), and \(last)"
	}
	
}
