import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var batteryMonitor: BatteryMonitor?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Initialize battery monitor
        batteryMonitor = BatteryMonitor()
        batteryMonitor?.startMonitoring()
        
        // Update status bar every minute
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateMenuBar()
        }
        
        // Initial update
        updateMenuBar()
        
        // Setup menu
        setupMenu()
        
        LaunchAtLogin.enable()
    }
    
    func updateMenuBar() {
        if let batteryLevel = batteryMonitor?.batteryLevel {
            statusItem?.button?.title = "\(Int(batteryLevel * 100))%"
        }
    }
    
    func setupMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Battery Monitor", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        let powerSourceItem = NSMenuItem(title: "Power Source: Unknown", action: nil, keyEquivalent: "")
        menu.addItem(powerSourceItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        
        statusItem?.menu = menu
        
        // Update power source info every minute
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            if let powerSource = self?.batteryMonitor?.powerSource {
                powerSourceItem.title = "Power Source: \(powerSource)"
            }
        }
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(self)
    }
}
