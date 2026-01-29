//
//  HealthCardModel+Extensions.swift
//  SMARTHealthCardUI
//
//  Created by David Carlson on 1/28/26.
//

import SMARTHealthCard

public extension HealthCardModel {
	
	public var resourceModels: [ResourceModel] {
		fhirResources.map { ResourceModel($0) }
	}
	
}
