//
//  BatteryService.swift
//  BatteryMonitor
//
//  Created by Udit Takkar on 10/01/25.
//

import Foundation
import IOKit
import IOKit.ps
import IOKit.pwr_mgt
import CoreFoundation


class BatteryService {
    static let shared = BatteryService()
    private var smartBatteryService: io_service_t = 0
    
    private init() {
        smartBatteryService = IOServiceGetMatchingService(kIOMainPortDefault,
            IOServiceMatching("AppleSmartBattery"))
    }
    
    deinit {
        if smartBatteryService != 0 {
            IOObjectRelease(smartBatteryService)
        }
    }
    
    func getBatteryInfo() -> BatteryInfo? {
        // Safely get battery properties
        guard let batteryProps = getBatteryProperties() else {
            print("Failed to get battery properties")
            return nil
        }
        
        // Safely extract values with defaults
        let currentCapacity = batteryProps[kIOPMPSCurrentCapacityKey] as? Int ?? 0
        let maxCapacity = batteryProps[kIOPMPSMaxCapacityKey] as? Int ?? 0
        let designCapacity = batteryProps[kIOPMPSDesignCapacityKey] as? Int ?? maxCapacity
        let cycleCount = batteryProps[kIOPMPSCycleCountKey] as? Int ?? 0
        
        // Safe temperature calculation
        let temperature = getTemperature(batteryProps)
        
        // Safe voltage calculation
        let voltageRaw = batteryProps[kIOPMPSVoltageKey] as? Double ?? 0
        let voltage = voltageRaw / 1000.0
        
        let amperage = batteryProps[kIOPMPSAmperageKey] as? Int ?? 0
        let isCharging = batteryProps[kIOPMPSIsChargingKey] as? Bool ?? false
        let timeRemaining = batteryProps[kIOPMPSTimeRemainingKey] as? Int ?? 0
        
        // Safe power source check
        let powerSource = getPowerSource()
        
        // Safe health calculation
        let health: Double
        if designCapacity > 0 {
            health = (Double(maxCapacity) / Double(designCapacity)) * 100.0
        } else {
            health = 100.0 // Default value if calculation not possible
        }
        
        // Debug logging
        print("Battery Info Debug:")
        print("Current Capacity: \(currentCapacity)")
        print("Max Capacity: \(maxCapacity)")
        print("Design Capacity: \(designCapacity)")
        print("Health: \(health)%")
        
        // Safely create power adapter info
        let powerAdapter = getPowerAdapterInfo(batteryProps)
        
        return BatteryInfo(
            currentCapacity: currentCapacity,
            maxCapacity: maxCapacity,
            designCapacity: designCapacity,
            cycleCount: cycleCount,
            temperature: temperature,
            voltage: voltage,
            amperage: amperage,
            isCharging: isCharging,
            timeRemaining: timeRemaining,
            powerSource: powerSource,
            health: health,
            powerAdapter: powerAdapter
        )
    }
    
    private func getBatteryProperties() -> [String: Any]? {
        var properties: Unmanaged<CFMutableDictionary>?
        
        let result = IORegistryEntryCreateCFProperties(
            smartBatteryService,
            &properties,
            kCFAllocatorDefault,
            0
        )
        
        if result == kIOReturnSuccess {
            return properties?.takeRetainedValue() as? [String: Any]
        }
        print("Failed to get battery properties: \(result)")
        return nil
    }
    
    private func getTemperature(_ properties: [String: Any]) -> Double {
        let temp = properties[kIOPMPSBatteryTemperatureKey] as? Double ?? 0
        return (temp / 100.0).rounded(to: 1)
    }
    
    private func getPowerSource() -> String {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        
        for source in sources {
            if let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeRetainedValue() as? [String: Any],
               let powerSource = description[kIOPSPowerSourceStateKey] as? String {
                return powerSource
            }
        }
        return "Unknown"
    }
    
    private func getPowerAdapterInfo(_ properties: [String: Any]) -> PowerAdapterInfo? {
        let watts = properties["AdapterPower"] as? Int ?? 0
        let isConnected = properties["ExternalConnected"] as? Bool ?? false
        let details = properties["AdapterDetails"] as? String ?? "Unknown"
        
        return PowerAdapterInfo(
            watts: watts,
            isConnected: isConnected,
            details: details
        )
    }
}
