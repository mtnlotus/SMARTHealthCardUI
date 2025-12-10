//
//  CodeSystemUtil.swift
//  SMARTHealthCardDemo
//
//  Created by David Carlson on 11/20/25.
//

import Foundation
import _Concurrency
import SwiftUI
// import only necessary classes to workaround FHIR Observation conflict with @Observable
import class ModelsR4.ValueSet
import class ModelsR4.CodeableConcept
import class ModelsR4.Coding
import class ModelsR4.Parameters

@Observable
public class TerminologyManager {
	/**
	 Temporary codes from FHIR IGs that are not available at this time from standardized code systems.
	 Also may nclude misc standard codes to reduce terminology server lookup for primary use cases.
	 
	 key has format "system|code", value is display string
	 */
	static private let otherDisplayNames: [String: String] = [
		"http://snomed.info/sct|247751003" : "Sense of Purpose",
		"http://va.gov/fhir/vco/CodeSystem/well-being|well-being-signs" : "Well-Being Signs",
		"http://va.gov/fhir/us/vco/CodeSystem/well-being-signs|satisfied" : "Satisfied",
		"http://va.gov/fhir/us/vco/CodeSystem/well-being-signs|involved" : "Involved",
		"http://va.gov/fhir/us/vco/CodeSystem/well-being-signs|functioning" : "Functioning",
	]
	
	/// Cached value sets of standard codes to reduce external code lookup queries.
	static private let valueSetFileNames: [String] = [
		"ValueSet-immunization-all-cvx",
	]
	
//	private let txServerBase = "https://tx.fhir.org/r4"
	private let txServerBase: String?
	
	/// key has format "system|code", value is display string
	private var codingDisplayMap: [String: String] = [:]
	
	public init(txServerBase: String? = nil) {
		self.txServerBase = txServerBase
		loadCachedTerminology()
	}
	
	private func loadCachedTerminology() {
		for key in TerminologyManager.otherDisplayNames.keys {
			codingDisplayMap[key] = TerminologyManager.otherDisplayNames[key]
		}
		// load FHIR ValueSets
		for fileName in TerminologyManager.valueSetFileNames {
			if let valueSet = readValueSet(from: fileName) {
				loadValueSetCodes(from: valueSet)
			}
		}
	}
	
	private func readValueSet(from fileName: String) -> ValueSet? {
		guard let fileURL = Bundle.module.url(forResource: "\(fileName)", withExtension: "json")
		else { return nil }
		
		return try? JSONDecoder().decode(ValueSet.self, from: try! Data(contentsOf: fileURL))
	}
	
	private func loadValueSetCodes(from valueSet: ValueSet) {
		for composeInclude in valueSet.compose?.include ?? [] {
			if let system = composeInclude.system?.value?.url.absoluteString {
				composeInclude.concept?.forEach({
					let key = "\(system)|\($0.code.value?.string ?? "")"
					codingDisplayMap[key] = $0.display?.value?.string ?? ""
				})
			}
		}
		for expansion in valueSet.expansion?.contains ?? [] {
			expansion.contains?.forEach({
				if let system = $0.system?.value?.url.absoluteString, let code = $0.code?.value?.string {
					let key = "\(system)|\(code)"
					codingDisplayMap[key] = $0.display?.value?.string ?? code
				}
			})
		}
	}
	
	@MainActor
	public func lookupDisplayText(for codeable: CodeableConcept) async throws -> String? {
		for coding in codeable.coding ?? [] {
			if let display = try await lookupDisplayText(for: coding) {
				return display
			}
		}
		return nil
	}
	
	@MainActor
	internal func lookupDisplayText(for coding: Coding) async throws -> String? {
		guard let system = coding.system?.value?.url.absoluteString, let code = coding.code?.value?.string else {
			return nil
		}
		
		let keyString = "\(system)|\(code)"
		if let display = codingDisplayMap[keyString] {
			return display
		}
		
		guard let txServerBase = txServerBase else {
			return nil
		}
		let query = "\(txServerBase)/CodeSystem/$lookup?_format=json&system=\(system)&code=\(code)&property=display&property=designation&property=lang.en-US"
		guard let url = URL(string: query) else {
			throw CodeSystemError.unableToParseSystemURL(coding.system?.value?.url.absoluteString ?? "Invalid terminology server URL")
		}
		
		let configuration = URLSessionConfiguration.ephemeral
		configuration.timeoutIntervalForResource = 5.0
		let session = URLSession(configuration: configuration)
		let (data, _) = try await session.data(from: url, delegate: nil)
		let parameters = try JSONDecoder().decode(Parameters.self, from: data)
		
		guard let parameters = parameters.parameter else {
			return nil
		}
		if let name = parameters.first(where: { "display" == $0.name.value?.string }), case .string(let displayString) = name.value {
			return displayString.value?.string
		}
		return nil
	}
}

enum CodeSystemError: Error {
	case unableToParseSystemURL(String)
	case failedToCreateUTF8DataFromString
}
