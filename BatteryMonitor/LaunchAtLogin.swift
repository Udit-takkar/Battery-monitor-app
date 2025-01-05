//
//  LaunchAtLogin.swift
//  BatteryMonitor
//
//  Created by Udit Takkar on 06/01/25.
//

import Foundation
import ServiceManagement

class LaunchAtLogin {
    static func enable() {
        do {
            try SMAppService.mainApp.register()
        } catch {
            print("Failed to register app for launch at login: \(error)")
        }
    }
    
    static func disable() {
        do {
            try SMAppService.mainApp.unregister()
        } catch {
            print("Failed to unregister app for launch at login: \(error)")
        }
    }
}
