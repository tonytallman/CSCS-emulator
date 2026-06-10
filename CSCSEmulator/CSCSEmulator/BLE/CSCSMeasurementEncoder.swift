//
//  CSCSMeasurementEncoder.swift
//  CSCSEmulator
//

import Foundation

/// Builds CSC Measurement (0x2A5B) packets from simulator vitals. No CoreBluetooth dependencies (SDD section 13).
struct CSCSMeasurementEncoder: Sendable {
    private let wheelCircumferenceMeters: Double
    private var wheelAccumulator = RevolutionAccumulator()
    private var crankAccumulator = RevolutionAccumulator()

    init(wheelCircumference: Measurement<UnitLength> = .init(value: 2.105, unit: .meters)) {
        wheelCircumferenceMeters = wheelCircumference.converted(to: .meters).value
    }

    mutating func measurement(vitals: SimulatorVitals, elapsed: Duration) -> Data {
        if vitals.supportsSpeed {
            let speedMetersPerSecond = vitals.speed.converted(to: .metersPerSecond).value
            let wheelRevolutionsPerSecond = speedMetersPerSecond / wheelCircumferenceMeters
            wheelAccumulator.accumulate(revolutionsPerSecond: wheelRevolutionsPerSecond, elapsed: elapsed)
        }

        if vitals.supportsCadence {
            let crankRevolutionsPerSecond = vitals.cadence.converted(to: .hertz).value
            crankAccumulator.accumulate(revolutionsPerSecond: crankRevolutionsPerSecond, elapsed: elapsed)
        }

        var packet = Data()
        var flags: UInt8 = 0

        if vitals.supportsSpeed {
            flags |= 0x01
        }
        if vitals.supportsCadence {
            flags |= 0x02
        }

        packet.append(flags)

        if vitals.supportsSpeed {
            Self.appendUInt32LittleEndian(wheelAccumulator.cumulativeRevolutions, to: &packet)
            Self.appendUInt16LittleEndian(wheelAccumulator.lastEventTime1024, to: &packet)
        }

        if vitals.supportsCadence {
            let crankRevolutions = UInt16(truncatingIfNeeded: crankAccumulator.cumulativeRevolutions)
            Self.appendUInt16LittleEndian(crankRevolutions, to: &packet)
            Self.appendUInt16LittleEndian(crankAccumulator.lastEventTime1024, to: &packet)
        }

        return packet
    }

    private static func appendUInt16LittleEndian(_ value: UInt16, to data: inout Data) {
        var littleEndian = value.littleEndian
        withUnsafeBytes(of: &littleEndian) { data.append(contentsOf: $0) }
    }

    private static func appendUInt32LittleEndian(_ value: UInt32, to data: inout Data) {
        var littleEndian = value.littleEndian
        withUnsafeBytes(of: &littleEndian) { data.append(contentsOf: $0) }
    }
}
