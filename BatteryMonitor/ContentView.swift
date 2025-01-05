import SwiftUI
import UserNotifications

struct ContentView: View {
    @StateObject private var batteryMonitor = BatteryMonitor()
    
    var body: some View {
        VStack {
            Text("Battery Level: \(Int(batteryMonitor.batteryLevel * 100))%")
                .font(.title)
            Text("Power Status: \(batteryMonitor.powerSource)")
                .font(.subheadline)
        }
        .padding()
        .onAppear {
            batteryMonitor.startMonitoring()
            requestNotificationPermission()
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge, .provisional, .criticalAlert]
        ) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error)")
            }
        }
    }
}
