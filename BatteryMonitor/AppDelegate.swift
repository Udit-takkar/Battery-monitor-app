import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarManager: MenuBarManager!
    private var batteryMonitor: BatteryMonitor?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize battery monitor and start it immediately
        batteryMonitor = BatteryMonitor()
        batteryMonitor?.startMonitoring()
        
        // Initialize menu bar manager (this will handle the status item)
        menuBarManager = MenuBarManager.shared
        
        // Setup notifications
        NotificationManager.shared.setupNotifications()
        
        // Enable launch at login for future launches
        LaunchAtLogin.enable()
        
        // Start monitoring immediately
        batteryMonitor?.updateBatteryStatus()
    }
    
    // Add this method to ensure the app stays running
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
