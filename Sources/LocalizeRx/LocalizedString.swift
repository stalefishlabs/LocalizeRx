//
//  LocalizedString.swift
//  
//
//  Created by Jonathan Graves on 2/26/20.
//

import Foundation

// This type represents a localized string, either declaration or usage, and is intended to be stored in a dictionary
// by key, which is why the key itself is not in this structure
struct LocalizedString {
  var filePath: String
  var lineNumber: Int
  var linePosition: Int
  var line: String
  var localizedValue: String?
  var ignoreSameTranslation: Bool
  
  init(filePath: String, lineNumber: Int, linePosition: Int, line: String, localizedValue: String? = nil, ignoreSameTranslation: Bool = false) {
    self.filePath = filePath
    self.lineNumber = lineNumber
    self.linePosition = linePosition
    self.line = line
    self.localizedValue = localizedValue
    self.ignoreSameTranslation = ignoreSameTranslation
  }
  
  func formattedError(key: String, messageSuffix: String) -> String {
    return "\(self.filePath):\(self.lineNumber):\(self.linePosition): error: String \"\(key)\" \(messageSuffix)\n\(self.line)\n\(String(repeating: " ", count: self.linePosition))^"
  }
  
  func formattedWarning(key: String, messageSuffix: String) -> String {
    return "\(self.filePath):\(self.lineNumber):\(self.linePosition): warning: String \"\(key)\" \(messageSuffix)\n\(self.line)\n\(String(repeating: " ", count: self.linePosition))^"
  }
}
