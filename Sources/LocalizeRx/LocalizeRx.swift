
import Foundation

class LocalizeRx {
    let masterLanguage : String
    let ignoreSameTranslationComment : String
    let ignoreSameTranslationWarnings : Bool
    let verbose : Bool
    let rootPath : String
    
    var errors = [String]()
    var warnings = [String]()
    
    init(rootFolder: String,
         masterLanguage : String,
         ignoreSameTranslationComment : String,
         ignoreSameTranslationWarnings : Bool,
         verbose : Bool) {
        self.ignoreSameTranslationComment = ignoreSameTranslationComment
        self.ignoreSameTranslationWarnings = ignoreSameTranslationWarnings
        self.verbose = verbose
        self.rootPath = rootFolder
        self.masterLanguage = masterLanguage
    }
    
    func log(_ text : String) {
        if verbose {
            print(text)
        }
    }

    func process() -> Bool {
        //Session diagnostics
        log("Using '\(masterLanguage)' as base language.")

        // Gather all localization projects
        if let localizationProjects = getLocalizationProjects(at: rootPath) {
          var masterLocalizedStrings = [String:LocalizedString]()
          var masterLocalizedStringKeys = [String]()
          for localizationProject in localizationProjects {
            if let masterProjectStringFiles = localizationProject.value[masterLanguage] {
              for masterProjectStringFile in masterProjectStringFiles {
                let masterProjectStrings = masterProjectStringFile.value
                
                // Add this project's master strings/keys to the full list of master strings/keys
                masterLocalizedStrings = masterLocalizedStrings.merging(masterProjectStrings) { (current, _) in current }
                masterLocalizedStringKeys.append(contentsOf: Array(masterProjectStrings.keys))
                
                let masterProjectStringKeySet = Set(masterProjectStrings.keys)
                let localizedLanguages = localizationProject.value.keys
                for localizedLanguage in localizedLanguages {
                  if localizedLanguage != masterLanguage {
                    if let localizedLanguageStrings = localizationProject.value[localizedLanguage]?[masterProjectStringFile.key] {
                      let localizedLanguageStringKeys = localizedLanguageStrings.keys
                      
                      if !localizedLanguage.starts(with: "en") {
                        for localizedLanguageStringKey in localizedLanguageStringKeys {
                          if let localizedString = localizedLanguageStrings[localizedLanguageStringKey], let localizedStringValue = localizedString.localizedValue {
                            if let masterStringValue = masterLocalizedStrings[localizedLanguageStringKey]?.localizedValue {
                              if !localizedString.ignoreSameTranslation, localizedStringValue == masterStringValue {
                                // Warn of any localized strings that don't appear to be translated
                                let formattedWarning = localizedString.formattedWarning(key: localizedLanguageStringKey, messageSuffix: "is localized to \(localizedLanguage.uppercased()) but doesn't appear to be translated (use // ignore-same-translation-warning to ignore)")
                                warnings.append(formattedWarning)
                              }
                            }
                            else {
                              // Warn of any localized strings that are missing in master
                              let formattedWarning = localizedString.formattedWarning(key: localizedLanguageStringKey, messageSuffix: "is localized to \(localizedLanguage.uppercased()) but missing a master (\(masterLanguage)) string")
                              warnings.append(formattedWarning)
                            }
                          }
                        }
                      }
                      
                      let localizedLanguageStringKeySet = Set(localizedLanguageStrings.keys)
                      
                      let missingLocalizedTranslationStrings = masterProjectStringKeySet.subtracting(localizedLanguageStringKeySet)
                      for missingLocalizedTranslationString in missingLocalizedTranslationStrings {
                        // Warn of any master localized strings that are missing in localized translations
                        if let formattedWarning = masterProjectStrings[missingLocalizedTranslationString]?.formattedWarning(key: missingLocalizedTranslationString, messageSuffix: "is localized but missing the \(localizedLanguage.uppercased()) translation") {
                          warnings.append(formattedWarning)
                        }
                      }
                    }
                  }
                }
              }
            }
          }
          let masterLocalizedStringKeySet = Set(masterLocalizedStringKeys)
          
          let sourceCodeUsedStrings = getSourceCodeUsedStrings(at: rootPath)
          let sourceCodeUsedStringKeySet = Set(sourceCodeUsedStrings.keys)
          
          // Warn of any strings used in source code but not localized (i.e. not appearing in any localized files)
          let untranslatedStringKeysSet = sourceCodeUsedStringKeySet.subtracting(masterLocalizedStringKeySet)
          for untranslatedStringKey in untranslatedStringKeysSet {
            if let formattedError = sourceCodeUsedStrings[untranslatedStringKey]?.formattedError(key: untranslatedStringKey, messageSuffix: "has not been localized") {
              errors.append(formattedError)
            }
          }
          
          // Warn of any strings that are localized but unused in source code
          let sourceCodeUnusedStringKeysSet = masterLocalizedStringKeySet.subtracting(sourceCodeUsedStringKeySet)
          for unusedStringKey in sourceCodeUnusedStringKeysSet {
            if let formattedWarning = masterLocalizedStrings[unusedStringKey]?.formattedWarning(key: unusedStringKey, messageSuffix: "is localized but unused in source code") {
              warnings.append(formattedWarning)
            }
          }
        }
        else {
            print("error: LocalizeRx failed with invalid configuration path \(self.rootPath)");
            return false
        }

        // Output resulting errors and warnings
        for error in errors { print(error) }
        for warning in warnings { print(warning) }
        print("Number of errors: \(errors.count), warnings: \(warnings.count)")

        // Exit with success if no errors, failure if errors
        return errors.count > 0
        }
}
