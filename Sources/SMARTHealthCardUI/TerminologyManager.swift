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
	 Consumer-friendly display names..
	 key has format "system|code", value is display string
	 */
	static private let consumerDisplayNames: [String: String] = [
		"http://snomed.info/sct|452341000124107" : "Goal Barrier",
		"http://loinc.org|85354-9" : "Blood Pressure",
		"http://loinc.org|8480-6" : "Systolic",
		"http://loinc.org|8462-4" : "Diastolic",
		"http://loinc.org|4548-4" : "Hemoglobin A1c",
	]
	
	/**
	 Include these standard codes to reduce terminology server lookup for primary use cases.
	 key has format "system|code", value is display string
	 */
	static private let cachedDisplayNames: [String: String] = [
		"http://snomed.info/sct|247751003" : "Sense of Purpose",
		"http://snomed.info/sct|452341000124107" : "Assessment of barriers to meet care plan goals performed",
	]
	
	/**
	 Temporary codes from FHIR IGs that are not available at this time from standardized code systems.
	 key has format "system|code", value is display string
	 */
	static private let otherDisplayNames: [String: String] = [
		"http://va.gov/fhir/vco/CodeSystem/well-being|well-being-signs" : "Well-Being Signs",
		"http://va.gov/fhir/us/vco/CodeSystem/well-being-signs|satisfied" : "Satisfied",
		"http://va.gov/fhir/us/vco/CodeSystem/well-being-signs|involved" : "Involved",
		"http://va.gov/fhir/us/vco/CodeSystem/well-being-signs|functioning" : "Functioning",
		"http://va.gov/fhir/us/vco/CodeSystem/well-being-signs|score" : "Score",
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
		// Load terminology in priority order if duplicates are present across sources,
		// e.g. consumer display prioritized over the same code from other sources.
		try? codingDisplayMap.merge(TerminologyManager.consumerDisplayNames) { (current, _) in current }
		try? codingDisplayMap.merge(TerminologyManager.cachedDisplayNames) { (current, _) in current }
		try? codingDisplayMap.merge(TerminologyManager.otherDisplayNames) { (current, _) in current }
		
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
		let query = "\(txServerBase)/CodeSystem/$lookup?_format=json&system=\(system)&code=\(code)"
		guard let url = URL(string: query) else {
			throw CodeSystemError.unableToParseSystemURL(coding.system?.value?.url.absoluteString ?? "Invalid terminology server URL")
		}
		
		let configuration = URLSessionConfiguration.ephemeral
		configuration.timeoutIntervalForResource = 10.0
		let session = URLSession(configuration: configuration)
		do {
			let (data, response) = try await session.data(from: url, delegate: nil)
			if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
				print("Terminology response error: \(httpResponse)")
			}
			let parameters = try JSONDecoder().decode(Parameters.self, from: data)
			
			guard let parameters = parameters.parameter else {
				return nil
			}
			if let name = parameters.first(where: { "display" == $0.name.value?.string }), case .string(let display) = name.value {
				// cache the result
				let displayString = display.value?.string
				codingDisplayMap[keyString] = display.value?.string ?? ""
				return displayString
			}
		}
		catch {
			print("Terminology lookup failed: \(error)")
		}
		return nil
	}
	
//		do {
//			let data = try await performBasicAuthRequest(username: "apikey", password: "xxxxxx", urlString: query)
//			let parameters = try JSONDecoder().decode(Parameters.self, from: data)
//			print(parameters)
//		}
//		catch {
//			print("Terminology lookup failed with basic auth: \(error)")
//		}
	
	@MainActor
	func performBasicAuthRequest(username: String, password: String, urlString: String) async throws -> Data {
		guard let url = URL(string: urlString) else {
			throw NSError(domain: "InvalidURL", code: 0, userInfo: nil)
		}

		var request = URLRequest(url: url)
		request.httpMethod = "GET" // Or POST, PUT, etc.

		// 1. Combine username and password
		let loginString = "\(username):\(password)"
		
		// 2. Encode the string to Data using UTF-8
		guard let loginData = loginString.data(using: .utf8) else {
			throw NSError(domain: "EncodingError", code: 0, userInfo: nil)
		}
		
		// 3. Base64 encode the Data
		let base64EncodedCredential = loginData.base64EncodedString()
		
		// 4. Add the "Authorization" header
		request.setValue("Basic \(base64EncodedCredential)", forHTTPHeaderField: "Authorization")

		// 5. Use URLSession to perform the request
		let (data, response) = try await URLSession.shared.data(for: request)

		// Optional: Check the HTTP response status code
		if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
			print("Authentication failed or request error: \(httpResponse.statusCode)")
		}

		return data
	}
}

enum CodeSystemError: Error {
	case unableToParseSystemURL(String)
	case failedToCreateUTF8DataFromString
}
