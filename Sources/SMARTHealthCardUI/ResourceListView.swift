//
//  ResourceListView.swift
//  SMARTHealthCardUI
//
//  Created by David Carlson on 12/30/25.
//

import SwiftUI
import SMARTHealthCard
import ModelsR4

public struct ResourceTypeRow: View {
	
	private let resourceType: ResourceType
	
	public init(_ resourceType: ResourceType) {
		self.resourceType = resourceType
	}
	
	public var body: some View {
		NavigationLink(value: resourceType) {
			HStack {
				resourceType.icon
					.foregroundColor(resourceType.color ?? .primary)
//				Text(LocalizedStringKey(linkTitle ?? category.titlePlural))
				Text(resourceType.rawValue)
					.bold()
					.padding([.top, .bottom, .leading], 5)
				Spacer()
			}
			.padding([.top, .bottom], 5)
		}
	}
}

public struct ResourceListView: View {
	
	private let resourceModels: [ResourceModel]
	private let includeTypes: [ResourceType]
	private let excludeTypes: [ResourceType]
	private let showHeader: Bool
	
	var listTitle: String {
		if includeTypes.count == 1, excludeTypes.isEmpty == true, let first = includeTypes.first {
			return first.rawValue
		}
		return "Resources"
	}
	
	public init(_ resourceModels: [ResourceModel], include: [ResourceType]? = nil, exclude: [ResourceType]? = nil, showHeader: Bool = true) {
		self.resourceModels = resourceModels
		self.includeTypes = include ?? []
		self.excludeTypes = exclude ?? []
		self.showHeader = showHeader
	}
	
	public var body: some View {
		List {
			ResourceSectionView(resourceModels, include: includeTypes, exclude: excludeTypes)
		}
		.navigationBarTitle(listTitle)
	}
}

public struct ResourceSectionView: View {
	
	private let resourceModels: [ResourceModel]
	private let includeTypes: [ResourceType]
	private let excludeTypes: [ResourceType]
	private let showHeader: Bool
	
	@ViewBuilder var sectionHeader: some View {
		if showHeader, includeTypes.count == 1, excludeTypes.isEmpty == true, let first = includeTypes.first {
			Text(first.rawValue)
		}
	}
	
	var models: [ResourceModel] {
		var models = resourceModels.filter { excludeTypes.contains($0.resourceType) == false }
		
		if !includeTypes.isEmpty {
			return models.filter { includeTypes.contains($0.resourceType) == true }
		}
		return models
	}
	
	public init(_ resourceModels: [ResourceModel], include: [ResourceType]? = nil, exclude: [ResourceType]? = nil, showHeader: Bool = true) {
		self.resourceModels = resourceModels
		self.includeTypes = include ?? []
		self.excludeTypes = exclude ?? []
		self.showHeader = showHeader
	}
	
	public var body: some View {
		if !models.isEmpty {
			Section(header: sectionHeader) {
				ForEach(models) { model in
					ResourceView(resourceModel: model)
				}
			}
		}
	}
}

#Preview {
	@Previewable @State var healthCareModel = HealthCardModel(numericSerialization: PreviewData.qrCodeNumeric)
	@Previewable @State var terminologyManager = TerminologyManager()
	
	NavigationStack {
		let models = healthCareModel.resourceModels
		List {
			ResourceSectionView(models, include: [.patient])
			ResourceSectionView(models, exclude: [.patient])
			ResourceSectionView(models)
		}
		.navigationDestination(for: Resource.self) { resource in
			ResourceDetailView(resource)
		}
	}
	.environment(healthCareModel)
	.environment(terminologyManager)
}

