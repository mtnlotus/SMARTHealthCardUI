//
//  ResourceView.swift
//  SMARTHealthCardDemo
//
//  Created by David Carlson on 11/19/25.
//

import SwiftUI
import ModelsR4

struct ResourceView: View {
	@Environment(TerminologyManager.self) private var terminology
	
	let resourceModel: ResourceModel
	
    var body: some View {
		VStack(alignment: .leading, spacing: 5) {
			HStack(spacing: 10) {
				if let icon = resourceModel.icon {
					icon
				}
				Text(resourceModel.resourceType)
				Spacer()
			}
			.bold()
			.foregroundColor(resourceModel.color ?? .primary)
			
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
	let condition = Condition(subject: Reference(reference: "resource:0"))
	ResourceView(resourceModel: ResourceModel(condition))
}
