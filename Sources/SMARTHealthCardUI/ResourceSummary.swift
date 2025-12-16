//
//  ResourceSummary.swift
//  SMARTHealthCardUI
//
//  Created by David Carlson on 12/12/25.
//

import SwiftUI
import ModelsR4

struct ResourceSummary: View {
	@Environment(TerminologyManager.self) private var terminology
	
	var resourceModel: ResourceModel
	var showNavigation: Bool = true
	
	var body: some View {
		VStack(alignment: .leading, spacing: 5) {
			NavigationLink(value: showNavigation ? resourceModel.resource : nil) {
				HStack(spacing: 10) {
					if let icon = resourceModel.icon {
						icon
					}
					Text(resourceModel.resourceType)
					Spacer()
				}
				.bold()
				.foregroundColor(resourceModel.color ?? .primary)
			}
			.navigationLinkIndicatorVisibility(showNavigation ? .visible : .hidden)
			
			Text(resourceModel.title)
				.font(.headline)
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
			try? await resourceModel.lookupTitle(using: terminology)
			try? await resourceModel.lookupDetail(using: terminology)
		}
	}
}

#Preview {
	@Previewable @State var terminologyManager = TerminologyManager()
	let condition = Condition(subject: Reference(reference: "resource:0"))
	List {
		ResourceSummary(resourceModel: ResourceModel(condition))
	}
	.environment(terminologyManager)
}

