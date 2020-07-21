//
//  main.swift
//  
//
//  Created by Jonathan Graves on 2/26/20.
//

import Foundation
import Commander


command(
    Argument<String>("root-folder", description: "Root folder to begin parsing"),
    Option<String>("development-language", default: ProcessInfo.processInfo.environment["DEVELOPMENT_LANGUAGE"] ?? "Base", description: "Two letter country code for base development langauge (or \"Base\""),
    Option<String>("ignore-comments-containing", default: "// ignore-same-translation-warning", description: "String in comments to ignore"),
    Flag("ignore-same-translation-warnings", default: false, flag: "i", description: "Generate warnings for identical translation strings"),
    Flag("verbose", default: false, flag: "v", description: "Verbose logging")
    ){
        let result = LocalizeRx(rootFolder: $0,
                                masterLanguage: $1,
                                ignoreSameTranslationComment: $2,
                                ignoreSameTranslationWarnings: $3,
                                verbose: $4
                                )
            .process()
        exit(result ? 1 : 0)
   }.run()
