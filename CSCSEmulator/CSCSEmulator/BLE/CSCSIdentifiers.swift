//
//  CSCSIdentifiers.swift
//  CSCSEmulator
//

import CoreBluetooth
import Foundation

/// Bluetooth SIG Cycling Speed and Cadence Service identifiers.
enum CSCSIdentifiers {
    static let serviceUUID = CBUUID(string: "1816")
    static let measurementCharacteristicUUID = CBUUID(string: "2A5B")
    static let featureCharacteristicUUID = CBUUID(string: "2A5C")

    static let advertisedLocalName = "CSCS emulator"

    /// CSC Feature characteristic value (uint16 LE): bit 0 = wheel rev data, bit 1 = crank rev data.
    static func featureValue(supportsSpeed: Bool, supportsCadence: Bool) -> Data {
        var flags: UInt16 = 0
        if supportsSpeed {
            flags |= 0x01
        }
        if supportsCadence {
            flags |= 0x02
        }
        var littleEndian = flags.littleEndian
        return withUnsafeBytes(of: &littleEndian) { Data($0) }
    }
}
