import Foundation
import IOKit.ps
import UserNotifications
import IOKit


class BatteryMonitor: ObservableObject {
       @Published var batteryLevel: Double = 0.0
       @Published var powerSource: String = "Unknown"
       @Published var cycleCount: Int = 0
       @Published var temperature: Double = 0.0
       @Published var health: Double = 100.0
       @Published var maxCapacity: Int = 100
       @Published var currentCapacity: Int = 0
       @Published var isCharging: Bool = false
       
       private var timer: Timer?
       private var lastLowBatteryNotification: Date?
       private var lastHighBatteryNotification: Date?
       
    private let cycleCountKey = "cycleCount" // IOKit key for cycle count
    
    func startMonitoring() {
        // Update immediately before starting the timer
        updateBatteryStatus()
        
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateBatteryStatus()
        }
        // Make sure the timer starts running immediately
        timer?.fire()
    }
    
    func updateBatteryStatus() {
        // Get IOKit battery info
        let smartBattery = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard smartBattery != IO_OBJECT_NULL else {
            return
        }
        defer { IOServiceClose(smartBattery) }
        
        var props: Unmanaged<CFMutableDictionary>?
        let result = IORegistryEntryCreateCFProperties(smartBattery, &props, kCFAllocatorDefault, 0)
        
        guard result == kIOReturnSuccess,
              let batteryProps = props?.takeRetainedValue() as? [String: Any] else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Update battery properties using correct keys
            self.currentCapacity = batteryProps["AppleRawCurrentCapacity"] as? Int ?? 0
            self.maxCapacity = batteryProps["AppleRawMaxCapacity"] as? Int ?? 100
            self.cycleCount = batteryProps["CycleCount"] as? Int ?? 0
            
            if let temp = batteryProps["Temperature"] as? Int {
                self.temperature = Double(temp) / 100.0
            }
            
            // Calculate battery level
            if self.maxCapacity > 0 {
                self.batteryLevel = Double(self.currentCapacity) / Double(self.maxCapacity)
            }
            
            // Update charging status and power source
            self.isCharging = batteryProps["IsCharging"] as? Bool ?? false
            self.powerSource = self.isCharging ? "AC Power" : "Battery Power"
            
            // Calculate health using design capacity
            if let designCapacity = batteryProps["DesignCapacity"] as? Int,
               designCapacity > 0 {
                self.health = (Double(self.maxCapacity) / Double(designCapacity)) * 100.0
            }
            
            // Debug print
            print("""
            Battery Status:
            Level: \(Int(self.batteryLevel * 100))%
            Health: \(Int(self.health))%
            Cycles: \(self.cycleCount)
            Temperature: \(String(format: "%.1f°C", self.temperature))
            Power Source: \(self.powerSource)
            Is Charging: \(self.isCharging)
            Current Capacity: \(self.currentCapacity)
            Max Capacity: \(self.maxCapacity)
            """)
            
            self.checkBatteryLevels()
        }
    }
    
    private func checkBatteryLevels() {
        let currentTime = Date()
        
        // Check for low battery (below 20%)
        if batteryLevel <= 0.20 {
            if shouldSendNotification(lastNotification: lastLowBatteryNotification) {
                sendNotification(
                    title: "Low Battery Alert",
                    body: "Your battery is at \(Int(batteryLevel * 100))%. Please connect to power."
                )
                lastLowBatteryNotification = currentTime
            }
        }
        
        // Check for high battery (above 80%)
        if batteryLevel >= 0.80 && powerSource == "AC Power" {
            if shouldSendNotification(lastNotification: lastHighBatteryNotification) {
                sendNotification(
                    title: "High Battery Alert",
                    body: "Your battery is at \(Int(batteryLevel * 100))%. Consider unplugging to preserve battery health."
                )
                lastHighBatteryNotification = currentTime
            }
        }
    }
    
    private func shouldSendNotification(lastNotification: Date?) -> Bool {
        guard let lastNotification = lastNotification else { return true }
        return Date().timeIntervalSince(lastNotification) >= 3600
    }
    
    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "BATTERY_ALERT"
        content.threadIdentifier = "battery_monitoring"
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error.localizedDescription)")
            }
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}
