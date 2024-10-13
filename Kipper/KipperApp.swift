//
//  KipperApp.swift
//  Kipper
//
//  Created by Kanwar Sandhu on 2024-10-13.
//

import SwiftUI

@main
struct KipperApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }
    }
}
