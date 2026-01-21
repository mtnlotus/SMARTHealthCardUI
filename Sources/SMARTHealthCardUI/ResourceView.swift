//
//  ResourceView.swift
//  SMARTHealthCardDemo
//
//  Created by David Carlson on 11/19/25.
//

import SwiftUI
import ModelsR4

struct ResourceView: View {
	let resourceModel: ResourceModel
	
    var body: some View {
		ResourceSummary(resourceModel: resourceModel, showNavigation: true)
    }
}

#Preview {
	@Previewable @State var healthCareModel = HealthCardModel(numericSerialization: PreviewData.qrCodeNumeric)
	@Previewable @State var terminologyManager = TerminologyManager()
	let condition = Condition(code: CodeableConcept(text: "High Cholesterol"), recordedDate : try? DateTime(date: Date.now).asPrimitive(), subject: Reference(reference: "resource:0"))
	List {
		ResourceView(resourceModel: ResourceModel(condition))
	}
	.environment(healthCareModel)
	.environment(terminologyManager)
}
