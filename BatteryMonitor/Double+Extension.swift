//
//  Double+Extension.swift
//  BatteryMonitor
//
//  Created by Udit Takkar on 10/01/25.
//

import Foundation

extension Double {
    func rounded(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
