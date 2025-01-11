import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarManager: MenuBarManager!
    private var batteryMonitor: BatteryMonitor?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize battery monitor
        batteryMonitor = BatteryMonitor()
        batteryMonitor?.startMonitoring()
        
        // Initialize menu bar manager (this will handle the status item)
        menuBarManager = MenuBarManager.shared
        
        // Setup notifications
        NotificationManager.shared.setupNotifications()
        
        // Enable launch at login
        LaunchAtLogin.enable()
    }
}
