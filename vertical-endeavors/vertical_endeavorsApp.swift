//
//  vertical_endeavorsApp.swift
//  vertical-endeavors
//
//  Created by   on 7/28/23.
//

import SwiftUI

@main
struct vertical_endeavorsApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
