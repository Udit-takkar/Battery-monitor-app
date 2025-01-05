import Foundation
import IOKit.ps
import UserNotifications

class BatteryMonitor: ObservableObject {
    @Published var batteryLevel: Double = 0.0
    @Published var powerSource: String = "Unknown"
    
    private var timer: Timer?
    private var lastLowBatteryNotification: Date?
    private var lastHighBatteryNotification: Date?
    
    func startMonitoring() {
        // Check battery status every 60 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateBatteryStatus()
        }
        updateBatteryStatus() // Initial check
    }
    
    private func updateBatteryStatus() {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        
        for source in sources {
            let info = IOPSGetPowerSourceDescription(snapshot, source).takeRetainedValue() as! [String: Any]
            
            if let capacity = info[kIOPSCurrentCapacityKey] as? Int,
               let maxCapacity = info[kIOPSMaxCapacityKey] as? Int {
                batteryLevel = Double(capacity) / Double(maxCapacity)
                
                // Update power source status
                if let powerSource = info[kIOPSPowerSourceStateKey] as? String {
                    self.powerSource = powerSource
                }
                
                // Check battery levels and send notifications
                checkBatteryLevels()
            }
        }
    }
    
    private func checkBatteryLevels() {
        let currentTime = Date()
        
        // Check for low battery (below 20%)
        if batteryLevel <= 0.20 {
            if lastLowBatteryNotification == nil || currentTime.timeIntervalSince(lastLowBatteryNotification!) >= 3600 {
                sendNotification(title: "Low Battery Alert", body: "Your battery is at \(Int(batteryLevel * 100))%. Please connect to power.")
                lastLowBatteryNotification = currentTime
            }
        }
        
        // Check for high battery (above 80%)
        if batteryLevel >= 0.80 && powerSource == "AC Power" {
            if lastHighBatteryNotification == nil || currentTime.timeIntervalSince(lastHighBatteryNotification!) >= 3600 {
                sendNotification(title: "High Battery Alert", body: "Your battery is at \(Int(batteryLevel * 100))%. Consider unplugging to preserve battery health.")
                lastHighBatteryNotification = currentTime
            }
        }
    }
    
    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .defaultCritical // Makes a more attention-grabbing sound
        
        // Make it a high priority notification
        content.interruptionLevel = .timeSensitive
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}
