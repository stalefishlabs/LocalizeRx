//
//  StringHelpers.swift
//  
//
//  Created by Jonathan Graves on 2/26/20.
//

import Foundation

    // For a given file path, return a dictionary of localized strings appearing within that file
    extension LocalizeRx {
    func getLocalizedStrings(at filePath: String) -> [String:LocalizedString] {
      var localizedStrings = [String:LocalizedString]()
      if let sourceCode = try? String(contentsOfFile: filePath) {
        let lines = sourceCode.components(separatedBy: CharacterSet.newlines)
        for (lineNumber, line) in lines.enumerated() {
          let range = NSRange(location:0, length:(line as NSString).length)
          let regex = try? NSRegularExpression(pattern: "\"(.*)\" *= *\"(.*)\" *; *(\\/\\/ *.*)?", options: [])
          regex?.enumerateMatches(in: line, options: [], range: range, using: { (result, _, _) in
            if let result = result {
              var ignoreSameTranslation = false
              
              let keyRange = result.range(at: 1)
              let key = (line as NSString).substring(with: keyRange)

              let valueRange = result.range(at: 2)
              let value = (line as NSString).substring(with: valueRange)
              
              let commentRange = result.range(at: 3)
              if commentRange.location != NSNotFound {
                let comment = (line as NSString).substring(with: commentRange)
                if comment == ignoreSameTranslationComment {
                  ignoreSameTranslation = true
                }
              }
              
              localizedStrings[key] = LocalizedString(filePath: "\(FileManager.default.currentDirectoryPath)/\(filePath)", lineNumber: lineNumber + 1, linePosition: keyRange.location, line: line, localizedValue: value, ignoreSameTranslation: (ignoreSameTranslation || ignoreSameTranslationWarnings))
            }
          })
        }
      }
      return localizedStrings
    }

    // For a given starting root path, recursively look for localization projects and return a hierarchical dictionary of projects
    // organized by project/file/language
    func getLocalizationProjects(at rootPath: String) -> [String:[String:[String:[String:LocalizedString]]]]? {
      guard FileManager.default.fileExists(atPath: rootPath) else { return nil }
      
      var localizationProjects = [String:[String:[String:[String:LocalizedString]]]]()
      let fileEnumerator = FileManager.default.enumerator(atPath: rootPath)
      var processingProjectPath: String?
      var processingLanguage: String?
      while let filePath = fileEnumerator?.nextObject() as? String {
        if filePath.hasSuffix("lproj") {
          let projectPath = (filePath as NSString).deletingLastPathComponent
          let stringsFilename = (filePath as NSString).lastPathComponent
          let language = (stringsFilename as NSString).deletingPathExtension
          
          if localizationProjects[projectPath] == nil {
            localizationProjects[projectPath] = [String:[String:[String:LocalizedString]]]()
          }
          if localizationProjects[projectPath]?[language] == nil {
            localizationProjects[projectPath]?[language] = [String:[String:LocalizedString]]()
          }
          
          processingProjectPath = projectPath
          processingLanguage = language
        }
        else if filePath.hasSuffix("strings"), let processingProjectPath = processingProjectPath, let processingLanguage = processingLanguage {
          let stringsFilename = (filePath as NSString).lastPathComponent
          print("Processing strings in \(filePath)")
          localizationProjects[processingProjectPath]?[processingLanguage]?[stringsFilename] = getLocalizedStrings(at: filePath)
        }
      }
      return localizationProjects
    }

    // For a given file path, return a dictionary of localized strings used within that file's source code
    func getSourceCodeUsedStrings(at filePath: String) -> [String:LocalizedString] {
      var sourceCodeUsedStrings = [String:LocalizedString]()
      let sourceEnumerator = FileManager.default.enumerator(atPath: filePath)
      while let sourceCodeFilename = sourceEnumerator?.nextObject() as? String {
        if sourceCodeFilename.hasSuffix(".swift") ||  sourceCodeFilename.hasSuffix(".m") || sourceCodeFilename.hasSuffix(".mm") {
          let location = "\(filePath)/\(sourceCodeFilename)"
          if let sourceCode = try? String(contentsOfFile: location) {
            let lines =  sourceCode.components(separatedBy: CharacterSet.newlines)
            for (lineNumber, line) in lines.enumerated() {
              let regex = try? NSRegularExpression(pattern: "(?i)(NS)?Localized(Format)?String(FromTable)?(?-i)\\( *@?\"(.*?)\"", options: [])
              let range = NSRange(location:0, length:(line as NSString).length)
              regex?.enumerateMatches(in: line, options: [], range: range, using: { (result, _, _) in
                if let result = result {
                  let keyRange = result.range(at: result.numberOfRanges - 1)
                  let key = (line as NSString).substring(with: keyRange)
                  sourceCodeUsedStrings[key] = LocalizedString(filePath: location, lineNumber: lineNumber + 1, linePosition: keyRange.location, line: line)
                }
              })
            }
          }
        }
      }
      return sourceCodeUsedStrings
    }

}
