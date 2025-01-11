//
//  MenuBarManager.swift
//  BatteryMonitor
//
//  Created by Udit Takkar on 10/01/25.
//

import Cocoa
import IOKit.ps
import CoreFoundation
import IOKit
import AppKit


class MenuBarManager {
    static let shared = MenuBarManager()
    private var statusItem: NSStatusItem
    private var batteryMonitor: BatteryMonitor
    private var timer: Timer?
    
    private init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        batteryMonitor = BatteryMonitor()
        
        setupMenu()
        setupTimer()
        batteryMonitor.startMonitoring()
    }
    
    private struct MenuItemInfo {
        let icon: String
        let title: String
        let index: Int
        let addSeparatorAfter: Bool
        
        static let items = [
            MenuItemInfo(icon: "🔋", title: "Design Capacity", index: 0, addSeparatorAfter: false),
            MenuItemInfo(icon: "🔄", title: "macOS Capacity", index: 1, addSeparatorAfter: false),
            MenuItemInfo(icon: "📊", title: "macOS Condition", index: 2, addSeparatorAfter: false),
            MenuItemInfo(icon: "⏱", title: "Cycle Count", index: 3, addSeparatorAfter: true),
            // Index 4 is the separator
            MenuItemInfo(icon: "🌡", title: "Battery Temperature", index: 5, addSeparatorAfter: false),
            MenuItemInfo(icon: "⏰", title: "Time to full", index: 6, addSeparatorAfter: false),
            MenuItemInfo(icon: "📱", title: "Serial Number", index: 7, addSeparatorAfter: true),
            // Index 8 is the separator
            MenuItemInfo(icon: "⚡️", title: "Charger Current", index: 9, addSeparatorAfter: false),
            MenuItemInfo(icon: "⚡️", title: "Charger Voltage", index: 10, addSeparatorAfter: false),
            MenuItemInfo(icon: "🔋", title: "Battery Current", index: 11, addSeparatorAfter: false),
            MenuItemInfo(icon: "🔋", title: "Battery Voltage", index: 12, addSeparatorAfter: false),
            MenuItemInfo(icon: "💻", title: "System Load", index: 12, addSeparatorAfter: true)
        ]
    }

    private func setupMenu() {
        let menu = NSMenu()
        
        // Set dark appearance
        menu.appearance = NSAppearance(named: .vibrantDark)
        
        // Create menu items with dark theme
        for menuInfo in MenuItemInfo.items {
            let item = createMenuItem(icon: menuInfo.icon, title: menuInfo.title, value: "--")
            menu.addItem(item)
            
            if menuInfo.addSeparatorAfter {
                let separator = NSMenuItem.separator()
                // Style the separator to be subtle
                let separatorString = NSAttributedString(
                    string: "",
                    attributes: [
                        .backgroundColor: NSColor.white.withAlphaComponent(0.1)
                    ]
                )
                separator.attributedTitle = separatorString
                menu.addItem(separator)
            }
        }
        
        // Add quit button with matching style
        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit Battery Monitor", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.attributedTitle = NSAttributedString(
            string: "Quit Battery Monitor",
            attributes: [
                .font: NSFont.systemFont(ofSize: 13),
                .foregroundColor: NSColor.white.withAlphaComponent(0.9)
            ]
        )
        quitItem.isEnabled = true
        menu.addItem(quitItem)
        
        // Style the menu
        menu.autoenablesItems = false
        
        // Set the menu
        statusItem.menu = menu
    }

    private func createMenuItem(icon: String, title: String, value: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.tabStops = [
            NSTextTab(textAlignment: .left, location: 200),
            NSTextTab(textAlignment: .right, location: 350)
        ]
        
        let attributedString = NSMutableAttributedString()
        
        // Icon with bright white color
        attributedString.append(NSAttributedString(
            string: "\(icon) ",
            attributes: [
                .font: NSFont.systemFont(ofSize: 14),
                .foregroundColor: NSColor.white.withAlphaComponent(0.9)
            ]
        ))
        
        // Title with medium white color
        attributedString.append(NSAttributedString(
            string: "\(title):\t",
            attributes: [
                .font: NSFont.systemFont(ofSize: 13),
                .foregroundColor: NSColor.white.withAlphaComponent(0.7),
                .paragraphStyle: paragraphStyle
            ]
        ))
        
        // Value with bright white color
        attributedString.append(NSAttributedString(
            string: value,
            attributes: [
                .font: NSFont.systemFont(ofSize: 13, weight: .medium),
                .foregroundColor: NSColor.white,
                .paragraphStyle: paragraphStyle
            ]
        ))
        
        item.attributedTitle = attributedString
        return item
    }


    private func updateMenuItem(_ menu: NSMenu, index: Int, value: String) {
        guard let item = menu.items[safe: index],
              let menuInfo = MenuItemInfo.items.first(where: { $0.index == index }) else {
            return
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.tabStops = [
            NSTextTab(textAlignment: .left, location: 200),
            NSTextTab(textAlignment: .right, location: 350)
        ]
        
        let attributedString = NSMutableAttributedString()
        
        // Icon with white color
        attributedString.append(NSAttributedString(
            string: "\(menuInfo.icon) ",
            attributes: [
                .font: NSFont.systemFont(ofSize: 14),
                .foregroundColor: NSColor.white.withAlphaComponent(0.9)
            ]
        ))
        
        // Title with light gray color
        attributedString.append(NSAttributedString(
            string: "\(menuInfo.title):\t",
            attributes: [
                .font: NSFont.systemFont(ofSize: 13),
                .foregroundColor: NSColor.white.withAlphaComponent(0.7),
                .paragraphStyle: paragraphStyle
            ]
        ))
        
        // Value with bright white color
        attributedString.append(NSAttributedString(
            string: value,
            attributes: [
                .font: NSFont.systemFont(ofSize: 13, weight: .medium),
                .foregroundColor: NSColor.white,
                .paragraphStyle: paragraphStyle
            ]
        ))
        
        item.attributedTitle = attributedString
    }
    

    private func updateDisplay() {
        guard let menu = statusItem.menu else { return }
        
        let batteryInfo = getBatteryInfo()
        
        // Extract values safely
        let designCapacity = batteryInfo["DesignCapacity"] as? Int ?? 1
        let maxCapacity = batteryInfo["MaxCapacity"] as? Int ?? 1
        let currentCapacity = batteryInfo["CurrentCapacity"] as? Int ?? 0
        let cycleCount = batteryInfo["CycleCount"] as? Int ?? 0
        let appleRawCurrentCapacity = batteryInfo["AppleRawCurrentCapacity"] as? Int ?? 0
        let appleRawMaxCapacity = batteryInfo["AppleRawMaxCapacity"] as? Int ?? 0
        
        // Calculate percentages correctly
        let healthPercentage = (Double(appleRawMaxCapacity) / Double(designCapacity)) * 100
        let currentPercentage = Double(currentCapacity)  // CurrentCapacity is already a percentage
        
        // Temperature and other values...
        let rawTemp = batteryInfo["Temperature"] as? Int ?? 0
        let temperatureCelsius = Double(rawTemp) / 100.0
        let temperatureString = String(format: "%.1f°C", temperatureCelsius)
        
        let voltage = Double(batteryInfo["Voltage"] as? Int ?? 0) / 1000.0
        let amperage = Double(batteryInfo["Amperage"] as? Int ?? 0) / 1000.0
        let isCharging = batteryInfo[kIOPSIsChargingKey] as? Bool ?? false
        let serialNumber = batteryInfo["BatterySerialNumber"] as? String ?? "--"
        
        let condition = getBatteryCondition(health: healthPercentage)
        let timeRemaining = getTimeRemaining(from: batteryInfo, isCharging: isCharging)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Update menu items
            self.updateMenuItem(menu, index: 0, value: "\(designCapacity) mAh\t100 %")
            self.updateMenuItem(menu, index: 1, value: "\(appleRawMaxCapacity) mAh\t\(Int(healthPercentage)) %")
            self.updateMenuItem(menu, index: 2, value: condition)
            self.updateMenuItem(menu, index: 3, value: "\(cycleCount)")
            // Index 4 is separator
            self.updateMenuItem(menu, index: 5, value: temperatureString)
            self.updateMenuItem(menu, index: 6, value: timeRemaining)
            self.updateMenuItem(menu, index: 7, value: serialNumber)
            // Index 8 is separator
            self.updateMenuItem(menu, index: 9, value: String(format: "%.2f A", abs(amperage)))
            self.updateMenuItem(menu, index: 10, value: String(format: "%.2f V", voltage))
            self.updateMenuItem(menu, index: 11, value: String(format: "%.2f A", amperage))
            self.updateMenuItem(menu, index: 12, value: String(format: "%.2f V", voltage))
            self.updateMenuItem(menu, index: 13, value: String(format: "%.2f W", abs(voltage * amperage)))
            
            // Update status bar
            let batterySymbol = self.getBatterySymbol(level: currentPercentage / 100, isCharging: isCharging)
            let statusText = "\(batterySymbol) \(Int(round(currentPercentage)))%"
            
            if let button = self.statusItem.button {
                self.statusItem.length = 70
                button.title = statusText
            }
        }
    }
    
    struct BatteryInfo {
        let designCapacity: Int
        let maxCapacity: Int
        let currentCapacity: Int
        let cycleCount: Int
        let temperature: Double
        let voltage: Double
        let amperage: Double
        let condition: String
        let serialNumber: String
        let timeRemaining: Int
    }

    // Add this function to get accurate battery information
    private func getBatteryInfo() -> [String: Any] {
        let smartBattery = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard smartBattery != IO_OBJECT_NULL else {
            return [:]
        }
        defer { IOServiceClose(smartBattery) }
        
        var props: Unmanaged<CFMutableDictionary>?
        let result = IORegistryEntryCreateCFProperties(smartBattery, &props, kCFAllocatorDefault, 0)
        
        guard result == kIOReturnSuccess,
              let batteryProps = props?.takeRetainedValue() as? [String: Any] else {
            return [:]
        }

        // Map battery properties using the correct keys
        var batteryInfo: [String: Any] = [:]
        
        // Map known properties
        let propertyMappings: [(key: String, infoKey: String)] = [
            ("DesignCapacity", "DesignCapacity"),
            ("CurrentCapacity", "CurrentCapacity"),
            ("MaxCapacity", "MaxCapacity"),
            ("CycleCount", "CycleCount"),
            ("Temperature", "Temperature"),
            ("Voltage", "Voltage"),
            ("Amperage", "Amperage"),
            ("BatterySerialNumber", "BatterySerialNumber"),
            ("IsCharging", kIOPSIsChargingKey),
            ("TimeRemaining", "TimeRemaining"),
            ("AppleRawMaxCapacity", "AppleRawMaxCapacity"),
            ("AppleRawCurrentCapacity", "AppleRawCurrentCapacity")
        ]
        
        // Copy properties with debug logging
        for (key, infoKey) in propertyMappings {
            if let value = batteryProps[key] {
                batteryInfo[infoKey] = value
                print("Found \(key): \(value)")
            } else {
                print("Missing \(key)")
            }
        }
        
        // Ensure minimum values and handle special cases
        if batteryInfo["DesignCapacity"] as? Int ?? 0 <= 0 {
            batteryInfo["DesignCapacity"] = batteryProps["AppleRawMaxCapacity"] as? Int ?? 100
        }
        
        if batteryInfo["MaxCapacity"] as? Int ?? 0 <= 0 {
            batteryInfo["MaxCapacity"] = batteryProps["AppleRawMaxCapacity"] as? Int ?? 100
        }
        
        if batteryInfo["CurrentCapacity"] as? Int ?? 0 <= 0 {
            batteryInfo["CurrentCapacity"] = batteryProps["AppleRawCurrentCapacity"] as? Int ?? 0
        }
        
        // Handle temperature specifically
        if let temp = batteryProps["Temperature"] as? Int {
            batteryInfo["Temperature"] = temp
            print("Raw Temperature: \(temp)")
        } else {
            print("Temperature not found in battery properties")
        }
        
        // Debug print final info
        print("Final Battery Info:", batteryInfo)
        
        return batteryInfo
    }
    
    // Add this property to track errors
    private var lastError: Error? = nil

    // Add error handling helper
    private func handleError(_ error: Error) {
        lastError = error
        print("Battery Monitor Error: \(error.localizedDescription)")
    }
    
    private func getBatteryCondition(health: Double) -> String {
        print("health \(health)")
        switch health {
        case 80...100: return "Normal"
        case 60..<80: return "Fair"
        case 40..<60: return "Poor"
        default: return "Replace"
        }
    }

    private func getTimeRemaining(from batteryInfo: [String: Any], isCharging: Bool) -> String {
        if !isCharging {
            return "--"
        }
        
        if let timeRemaining = batteryInfo["TimeRemaining"] as? Int {
            let hours = timeRemaining / 60
            let minutes = timeRemaining % 60
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(minutes)m"
            }
        }
        
        return "--"
    }
    
    private func getBatterySymbol(level: Double, isCharging: Bool) -> String {
        if isCharging {
            return "⚡️"
        }
        
        switch level {
        case 0..<0.2: return "🪫"
        case 0.2..<0.5: return "🔋"
        case 0.5..<0.8: return "🔋"
        default: return "🔋"
        }
    }
    
    private func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateDisplay()
        }
        timer?.tolerance = 0.5
        updateDisplay()
    }
    
    deinit {
        timer?.invalidate()
    }
}

// Array safe subscript extension
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
