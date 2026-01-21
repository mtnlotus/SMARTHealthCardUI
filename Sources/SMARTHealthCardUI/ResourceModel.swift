//
//  ResourceModel.swift
//  SMARTHealthCardDemo
//
//  Created by David Carlson on 11/25/25.
//

import SwiftUI
import class ModelsR4.Resource
import enum ModelsR4.ResourceType

@Observable
public class ResourceModel: Identifiable {
	
	public let id: String = UUID().uuidString
	
	public let resource: Resource
	
	public var displayableResource: DisplayableResource? {
		resource as? DisplayableResource
	}
	
	public init(_ resource: Resource) {
		self.resource = resource
		
		if let displayableResource = resource as? DisplayableResource {
			title = displayableResource.title
			detail = displayableResource.detail
		}
		else {
			title = type(of: resource).resourceType.rawValue
		}
	}
	
	public var icon: Image? {
		resource.icon
	}
	
	public var color: Color? {
		resource.color
	}
	
	public var resourceType: ResourceType {
		type(of: resource).resourceType
	}
	
	public var title: String
	private var titleLookupComplete: Bool = false
	
	public var subtitle: String? {
		displayableResource?.subtitle
	}
	
	public var detail: String?
	private var detailLookupComplete: Bool = false
	
	@MainActor
	public func lookupTitle(using terminology: TerminologyManager? = nil) async throws {
		if !titleLookupComplete, let codeable = displayableResource?.titleCode, let title = try await terminology?.lookupDisplayText(for: codeable) {
			titleLookupComplete = true
			if self.title != title {
				self.title = title
			}
		}
	}
	
	@MainActor
	public func lookupDetail(using terminology: TerminologyManager? = nil) async throws {
		if !detailLookupComplete, let detail = try await displayableResource?.lookupDetail(using: terminology) {
			detailLookupComplete = true
			if self.detail != detail {
				self.detail = detail
			}
		}
	}
	
}
