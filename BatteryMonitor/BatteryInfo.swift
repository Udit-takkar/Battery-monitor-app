//
//  BatteryInfo.swift
//  BatteryMonitor
//
//  Created by Udit Takkar on 10/01/25.
//

import Foundation

struct BatteryInfo {
    let currentCapacity: Int
    let maxCapacity: Int
    let designCapacity: Int
    let cycleCount: Int
    let temperature: Double
    let voltage: Double
    let amperage: Int
    let isCharging: Bool
    let timeRemaining: Int
    let powerSource: String
    let health: Double
    let powerAdapter: PowerAdapterInfo?
    
    var percentage: Double {
        return Double(currentCapacity) / Double(maxCapacity) * 100.0
    }
    
    var timeRemainingFormatted: String {
        if timeRemaining <= 0 {
            return isCharging ? "Calculating..." : "No Estimate"
        }
        let hours = timeRemaining / 60
        let minutes = timeRemaining % 60
        return "\(hours)h \(minutes)m"
    }
    
    var healthStatus: String {
        switch health {
        case 90...100: return "Excellent"
        case 80..<90: return "Good"
        case 60..<80: return "Fair"
        default: return "Poor"
        }
    }
}

struct PowerAdapterInfo {
    let watts: Int
    let isConnected: Bool
    let details: String
}
