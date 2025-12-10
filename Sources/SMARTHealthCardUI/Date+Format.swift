//
//  Date+Format.swift
//  SMARTHealthCardDemo
//
//  Created by David Carlson on 12/5/25.
//

import Foundation

public extension Date {
	
	var mediumFormat: String {
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .medium
		dateFormatter.timeStyle = .none
		return dateFormatter.string(from: self)
	}
	
	var longFormat: String {
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .long
		dateFormatter.timeStyle = .none
		return dateFormatter.string(from: self)
	}
	
	var mediumDateTimeFormat: String {
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .medium
		dateFormatter.timeStyle = .short
		return dateFormatter.string(from: self)
	}
	
	var fullDateTimeFormat: String {
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .full
		dateFormatter.timeStyle = .short
		return dateFormatter.string(from: self)
	}
	
	
}
