//
//  ResourceSummary.swift
//  SMARTHealthCardUI
//
//  Created by David Carlson on 12/12/25.
//

import SwiftUI
import ModelsR4
import OSLog

public struct ResourceSummary: View {
	@Environment(TerminologyManager.self) private var terminology
	
	let resourceModel: ResourceModel
	let showNavigation: Bool
	
	public init(resourceModel: ResourceModel, showNavigation: Bool = true) {
		self.resourceModel = resourceModel
		self.showNavigation = showNavigation
	}
	
	public init(_ resource: Resource) {
		self.init(resourceModel: ResourceModel(resource))
	}
	
	public var body: some View {
		VStack(alignment: .leading, spacing: 5) {
			NavigationLink(value: showNavigation ? resourceModel.resource : nil) {
				HStack(spacing: 10) {
					if let icon = resourceModel.icon {
						icon
							.font(.title2)
							.foregroundColor(resourceModel.color ?? .primary)
					}
					Text(resourceModel.title)
						.font(.headline)
						.foregroundColor(.primary)
					Spacer()
				}
			}
			.navigationLinkIndicatorVisibility(showNavigation ? .visible : .hidden)
			
			if let subtitle = resourceModel.subtitle {
				Text(subtitle)
					.font(.footnote)
					.foregroundStyle(.secondary)
			}
			if let value = resourceModel.detail {
				Text(value)
			}
		}
		.multilineTextAlignment(.leading)
		.task {
			do {
				try await resourceModel.lookupTitle(using: terminology)
				try await resourceModel.lookupDetail(using: terminology)
			}
			catch {
				Logger.statistics.error("Failed to lookup resource details: \(error)")
			}
		}
	}
}

#Preview {
	@Previewable @State var terminologyManager = TerminologyManager()
	let condition = Condition(code: CodeableConcept(text: "High Cholesterol"), recordedDate : try? DateTime(date: Date.now).asPrimitive(), subject: Reference(reference: "resource:0"))
	let medication = MedicationRequest(authoredOn: try? DateTime(date: Date.now).asPrimitive(), intent: MedicationRequestIntent.order.asPrimitive(), medication: .codeableConcept(CodeableConcept(text: "Aspirin")), status: MedicationrequestStatus.active.asPrimitive(), subject: Reference(reference: "resource:0"))
	List {
		ResourceSummary(resourceModel: ResourceModel(condition))
		ResourceSummary(resourceModel: ResourceModel(medication))
	}
	.environment(terminologyManager)
}

