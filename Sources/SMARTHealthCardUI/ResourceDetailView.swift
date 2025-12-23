//
//  SwiftUIView.swift
//  SMARTHealthCardUI
//
//  Created by David Carlson on 12/12/25.
//

import SwiftUI
import ModelsR4

public struct ResourceDetailView: View {
	private let resource: Resource
	private let resourceModel: ResourceModel
	
	private var resourceJSON: String? {
		let jsonEncoder = JSONEncoder()
		jsonEncoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
		return String(data: try! jsonEncoder.encode(resource), encoding: .utf8)
	}
	
	public init(_ resource: Resource) {
		self.resource = resource
		self.resourceModel = ResourceModel(resource)
	}
	
    public var body: some View {
		List {
			Section {
				ResourceSummary(resourceModel: resourceModel, showNavigation: false)
			}
			
			if let resourceJSON = resourceJSON {
				Section("FHIR Source Data") {
					Text(resourceJSON)
						.multilineTextAlignment(.leading)
						.font(.footnote)
						.textSelection(.enabled)
//						.font(.system(size: 14, weight: .regular, design: .monospaced))
				}
			}
		}
		.navigationTitle(resourceModel.resourceType)
    }
}

#Preview {
	@Previewable @State var terminologyManager = TerminologyManager()
	let condition = Condition(code: CodeableConcept(text: "High Cholesterol"), recordedDate : try? DateTime(date: Date.now).asPrimitive(), subject: Reference(reference: "resource:0"))
	NavigationStack {
		ResourceDetailView(condition)
			.environment(terminologyManager)
	}
}
