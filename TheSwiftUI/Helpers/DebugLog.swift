//
//  DebugLog.swift
//  TheSwiftUI
//
//  Created by John Daugdaug on 5/28/25.
//

import Foundation

#if DEBUG
let debugBuild = true
#else
let debugBuild = false
#endif

func debugLog(logMessage: String, functionName: String = #function, className: String = #file) {
    if debugBuild {
        if functionName == "" {
            print("\(Date())\(logMessage)")
        } else {
            let fileName = ((className as NSString).lastPathComponent as NSString).deletingPathExtension
            print("\(Date())[\(fileName)] \(functionName): \(logMessage)")
        }
    }
}

