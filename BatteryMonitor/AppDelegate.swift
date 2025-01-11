import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarManager: MenuBarManager!
    private var batteryMonitor: BatteryMonitor?
    
    override init() {
        super.init()
        // Set activation policy here instead of in the App
        NSApplication.shared.setActivationPolicy(.accessory)
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize menu bar manager first
        menuBarManager = MenuBarManager.shared
        
        // Setup notifications
        NotificationManager.shared.setupNotifications()
        
        // Initialize battery monitor and start it immediately
        batteryMonitor = BatteryMonitor()
        batteryMonitor?.startMonitoring()
        
        // Enable launch at login for future launches
        LaunchAtLogin.enable()
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if menuBarManager == nil {
            menuBarManager = MenuBarManager.shared
        }
        return true
    }
}
