//
//  TheSwiftUIApp.swift
//  TheSwiftUI
//
//  Created by John Daugdaug on 5/28/25.
//

import SwiftUI

@main
struct TheSwiftUIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    debugLog(logMessage: "Documents Directory: \(FileManager.documentsDir())")
                }
        }
    }
}
