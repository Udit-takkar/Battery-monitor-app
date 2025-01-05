//
//  BatteryMonitorApp.swift
//  BatteryMonitor
//
//  Created by Udit Takkar on 06/01/25.
//

import SwiftUI

@main
struct BatteryMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
