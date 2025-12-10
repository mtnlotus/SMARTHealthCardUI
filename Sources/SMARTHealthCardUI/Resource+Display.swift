//
//  Resource+Display.swift
//  SMARTHealthCardDemo
//
//  Created by David Carlson on 11/19/25.
//

import Foundation
import SwiftUI
import ModelsR4

public protocol DisplayableResource: Resource {
	var icon: Image? { get }
	var title: String { get }
	var titleCode: CodeableConcept? { get }
	var subtitle: String? { get }
	var detail: String? { get }
	
	@MainActor func lookupTitle(using terminology: TerminologyManager?) async throws -> String?
	
	@MainActor func lookupDetail(using terminology: TerminologyManager?) async throws -> String?
}

extension Resource {
	public var icon: Image? {
		switch type(of: self).resourceType {
		case .condition:
			return Image(systemName: "stethoscope")
		case .goal:
			return Image(systemName: "flag")
		case .immunization:
			return Image(systemName: "cross.vial")
		case .medicationRequest:
			return Image(systemName: "pills.fill")
		case .observation:
			return Image(systemName: "checkmark.rectangle")
		case .patient:
			return Image(systemName: "person")
		default:
			return nil
		}
	}
	
	public var color: Color? {
		switch type(of: self).resourceType {
		case .condition:
			return .purple
		case .goal:
			return .green
		case .immunization:
			return .cyan
		case .medicationRequest:
			return .teal
		case .observation:
			return .orange
		case .patient:
			return .blue
		default:
			return nil
		}
	}
}
	
extension DisplayableResource {
	
	public var title: String {
		titleCode?.displayString ?? type(of: self).resourceType.rawValue
	}
	
	public var titleCode: CodeableConcept? {
		nil
	}
	
	public var subtitle: String? {
		nil
	}
	
	public var detail: String? {
		nil
	}
	
	@MainActor
	public func lookupTitle(using terminology: TerminologyManager?) async throws -> String? {
		nil
	}
	
	@MainActor 
	public func lookupDetail(using terminology: TerminologyManager?) async throws -> String? {
		nil
	}
	
}

extension Patient: DisplayableResource {
	
	public var title: String {
		name?.first?.fullName ?? type(of: self).resourceType.rawValue
	}
	
	public var subtitle: String? {
		guard let fhirDate = birthDate?.value, let nsDate = try? fhirDate.asNSDate()
		else { return nil }
		
		// Displays date correctly in user's timezone. FHIRDate does not include time components.
		let displayDate = Calendar.current.date(from: .init(timeZone: .current, year: fhirDate.year,
										  month: fhirDate.month != nil ? Int(fhirDate.month!) : nil,
										  day: fhirDate.day != nil ? Int(fhirDate.day!) : nil)) ?? nsDate
		
		let formatter = DateFormatter()
		formatter.dateStyle = .long
		formatter.timeStyle = .none
		return "\(formatter.string(from: displayDate))"
	}
	
}

extension Condition: DisplayableResource {
	
	public var titleCode: CodeableConcept? {
		self.code
	}
	
	public var subtitle: String? {
		guard let recordedDate = try? self.recordedDate?.value?.asNSDate()
		else { return nil }
		
		let formatter = DateFormatter()
		formatter.dateStyle = .long
		formatter.timeStyle = .none
		formatter.timeZone = Calendar.current.timeZone
		return "Starting \(formatter.string(from: recordedDate))"
	}
	
}

extension Goal: DisplayableResource {
	
	public var subtitle: String? {
		guard case .date(let fhirDate) = self.start, let nsDate = try? fhirDate.value?.asNSDate()
		else { return nil }
		
		// Displays date correctly in user's timezone. FHIRDate does not include time components.
		let displayDate = Calendar.current.date(from: .init(timeZone: .current, year: fhirDate.value?.year,
										  month: fhirDate.value?.month != nil ? Int(fhirDate.value!.month!) : nil,
										  day: fhirDate.value?.day != nil ? Int(fhirDate.value!.day!) : nil)) ?? nsDate
		
		let formatter = DateFormatter()
		formatter.dateStyle = .long
		formatter.timeStyle = .none
		return "Starting \(formatter.string(from: displayDate))"
	}
	
	public var detail: String? {
		description_fhir.displayString ?? title
	}
	
}

extension Immunization: DisplayableResource {
	
	public var titleCode: CodeableConcept? {
		self.vaccineCode
	}
	
	public var subtitle: String? {
		guard case .dateTime(let dateTime) = self.occurrence, let nsDate = try? dateTime.value?.asNSDate()
		else { return nil }
		
		let formatter = DateFormatter()
		formatter.dateStyle = .long
		formatter.timeStyle = .none
		formatter.timeZone = Calendar.current.timeZone
		return "\(formatter.string(from: nsDate))"
	}
	
	public var detail: String? {
		performer?.first?.actor.display?.value?.string
	}
	
}

extension Observation: DisplayableResource {
	
	public var titleCode: CodeableConcept? {
		self.code
	}
	
	public var subtitle: String? {
		guard case .dateTime(let dateTime) = self.effective, let nsDate = try? dateTime.value?.asNSDate()
		else { return nil }
		
		let formatter = DateFormatter()
		formatter.dateStyle = .long
		formatter.timeStyle = .none
		formatter.timeZone = Calendar.current.timeZone
		return "\(formatter.string(from: nsDate))"
	}
	
	public var detail: String? {
		if let value = value {
			return value.displayString
		}
		else if let obsComponents = component, !obsComponents.isEmpty {
			var componentDisplay = ""
			for component in obsComponents {
				if let codeString = component.code.displayString, let valueString = component.value?.displayString {
					componentDisplay += "\(codeString) = \(valueString), "
				}
			}
			return componentDisplay
		}
		else {
			return nil
		}
	}
	
	@MainActor
	public func lookupDetail(using terminology: TerminologyManager?) async throws -> String? {
		if let obsComponents = component, !obsComponents.isEmpty {
		var componentDisplay = ""
		   for component in obsComponents {
			   if let codeString = try await terminology?.lookupDisplayText(for: component.code) ?? component.code.displayString,
					let valueString = component.value?.displayString {
				   if !componentDisplay.isEmpty {
					   componentDisplay.append(", ")
				   }
				   componentDisplay.append("\(codeString) = \(valueString)")
			   }
		   }
		   return componentDisplay
	   }
	   else {
		   return nil
	   }
	}
	
}

extension Observation.ValueX {
	public var displayString: String? {
		switch self {
		case .quantity(let value):
			return value.displayString
		case .codeableConcept(let value):
			return value.displayString
		case .string(let value):
			return value.value?.string
		case .integer(let value):
			return value.value?.integer.description
		case .boolean(let value):
			return value.value?.bool.description
		default:
			return nil
		}
	}
}

extension ObservationComponent.ValueX {
	public var displayString: String? {
		switch self {
		case .quantity(let value):
			return value.displayString
		case .codeableConcept(let value):
			return value.displayString
		case .string(let value):
			return value.value?.string
		case .integer(let value):
			return value.value?.integer.description
		case .boolean(let value):
			return value.value?.bool.description
		default:
			return nil
		}
	}
}

extension Quantity {
	
	public var displayString: String? {
		guard let displayValue = self.displayValue else { return nil }
		
		return "\(self.comparator?.value?.rawValue ?? "") \(displayValue) \(self.unit?.value?.string ?? "")"
	}
	
	public var displayValue: String? {
		if let value = self.value?.value?.decimal {
			let d = Double(truncating:value as NSNumber)
			let formatter = NumberFormatter()
			formatter.numberStyle = .decimal
			formatter.maximumFractionDigits = d.isLess(than: 1) ? 2 : 1
			return formatter.string(from: NSNumber(value: d))
		}
		return nil
	}
	
}

extension CodeableConcept {
	
	internal var displayString: String? {
		if let coding = coding?.first {
			return "\(systemDisplay(coding.system) ?? "") \(coding.code?.value?.string ?? "")"
		}
		else {
			return nil
		}
	}
	
	internal func systemDisplay(_ system: FHIRPrimitive<FHIRURI>?) -> String? {
		guard let systemURI = system?.value?.url.absoluteString
		else { return nil }
		
		switch systemURI {
		case "http://hl7.org/fhir/sid/cvx":
			return "CVX"
		case "http://loinc.org":
			return "LOINC"
		case "http://snomed.info/sct":
			return "SNOMED"
		default :
			return nil
		}
	}
}

extension HumanName {
	
	/// Join the non-empty name parts into a "human-normal" string in the order prefix > given > family > suffix, joined by a space,
	/// **unless** the receiver's `text` is set, in which case the text is returned.
	public var fullName: String? {
		if let text = text?.value?.string {
			return text
		}
		
		var parts = [String]()
		if let prefix = prefix {
			parts.append(contentsOf: prefix.filter { $0.value?.string.count ?? -1 > 0 }.map { $0.value?.string ?? "" })
		}
		if let given = given {
			parts.append(contentsOf: given.filter { $0.value?.string.count ?? -1 > 0 }.map {$0.value?.string ?? "" })
		}
		if let family = family?.value?.string, family.count > 0 {
			parts.append(family)
		}
		if let suffix = suffix {
			parts.append(contentsOf: suffix.filter { $0.value?.string.count ?? -1 > 0 }.map { $0.value?.string ?? "" })
		}
		guard parts.count > 0 else {
			return nil
		}
		return parts.joined(separator: " ")
	}
	
}
