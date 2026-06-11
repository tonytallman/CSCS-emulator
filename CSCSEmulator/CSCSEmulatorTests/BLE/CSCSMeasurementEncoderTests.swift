//
//  CSCSMeasurementEncoderTests.swift
//  CSCSEmulatorTests
//

import Foundation
import Testing
@testable import CSCSEmulator

@Suite struct CSCSMeasurementEncoderTests {
    private func readUInt32LittleEndian(from data: Data, at offset: Int) -> UInt32 {
        UInt32(data[offset])
            | UInt32(data[offset + 1]) << 8
            | UInt32(data[offset + 2]) << 16
            | UInt32(data[offset + 3]) << 24
    }

    private func readUInt16LittleEndian(from data: Data, at offset: Int) -> UInt16 {
        UInt16(data[offset]) | UInt16(data[offset + 1]) << 8
    }

    @Test func speedOnlyPacketHasExpectedFlagsAndLength() {
        var encoder = CSCSMeasurementEncoder()
        let vitals = SimulatorVitals(
            speed: .milesPerHour(20),
            cadence: .rpm(0),
            supportsSpeed: true,
            supportsCadence: false
        )

        let packet = encoder.measurement(vitals: vitals, elapsed: .seconds(1))

        #expect(packet.count == 7)
        #expect(packet[0] == 0x01)
    }

    @Test func cadenceOnlyPacketHasExpectedFlagsAndLength() {
        var encoder = CSCSMeasurementEncoder()
        let vitals = SimulatorVitals(
            speed: .milesPerHour(0),
            cadence: .rpm(90),
            supportsSpeed: false,
            supportsCadence: true
        )

        let packet = encoder.measurement(vitals: vitals, elapsed: .seconds(2))

        #expect(packet.count == 5)
        #expect(packet[0] == 0x02)
    }

    @Test func speedAndCadencePacketHasExpectedFlagsAndLength() {
        var encoder = CSCSMeasurementEncoder()
        let vitals = SimulatorVitals(
            speed: .milesPerHour(20),
            cadence: .rpm(90),
            supportsSpeed: true,
            supportsCadence: true
        )

        let packet = encoder.measurement(vitals: vitals, elapsed: .seconds(1))

        #expect(packet.count == 11)
        #expect(packet[0] == 0x03)
    }

    @Test func speedOnlyPacketMatchesHandComputedByteVector() {
        var encoder = CSCSMeasurementEncoder()
        let vitals = SimulatorVitals(
            speed: .milesPerHour(20),
            cadence: .rpm(0),
            supportsSpeed: true,
            supportsCadence: false
        )

        let packet = encoder.measurement(vitals: vitals, elapsed: .seconds(1))

        let speedMetersPerSecond = Speed.milesPerHour(20).converted(to: .metersPerSecond).value
        let wheelRevolutionsPerSecond = speedMetersPerSecond / 2.105
        let expectedRevolutions: UInt32 = 4
        let expectedEventTime = RevolutionAccumulator.eventTime1024(
            fromSeconds: Double(expectedRevolutions) / wheelRevolutionsPerSecond
        )

        #expect(packet[1] == 0x04)
        #expect(packet[2] == 0x00)
        #expect(packet[3] == 0x00)
        #expect(packet[4] == 0x00)
        #expect(packet[5] == UInt8(truncatingIfNeeded: expectedEventTime & 0xFF))
        #expect(packet[6] == UInt8(truncatingIfNeeded: (expectedEventTime >> 8) & 0xFF))
    }

    @Test func cadenceOnlyPacketMatchesHandComputedByteVector() {
        var encoder = CSCSMeasurementEncoder()
        let vitals = SimulatorVitals(
            speed: .milesPerHour(0),
            cadence: .rpm(90),
            supportsSpeed: false,
            supportsCadence: true
        )

        let packet = encoder.measurement(vitals: vitals, elapsed: .seconds(2))

        #expect(packet[1] == 0x03)
        #expect(packet[2] == 0x00)
        #expect(packet[3] == 0x00)
        #expect(packet[4] == 0x08)
    }

    @Test func cumulativeCountersIncreaseAcrossSuccessivePackets() {
        var encoder = CSCSMeasurementEncoder()
        let vitals = SimulatorVitals(
            speed: .milesPerHour(20),
            cadence: .rpm(90),
            supportsSpeed: true,
            supportsCadence: true
        )

        _ = encoder.measurement(vitals: vitals, elapsed: .seconds(1))
        let secondPacket = encoder.measurement(vitals: vitals, elapsed: .seconds(1))

        let firstWheelRevs = readUInt32LittleEndian(from: secondPacket, at: 1)
        let firstCrankRevs = readUInt16LittleEndian(from: secondPacket, at: 7)

        let thirdPacket = encoder.measurement(vitals: vitals, elapsed: .seconds(1))
        let secondWheelRevs = readUInt32LittleEndian(from: thirdPacket, at: 1)
        let secondCrankRevs = readUInt16LittleEndian(from: thirdPacket, at: 7)

        #expect(secondWheelRevs > firstWheelRevs)
        #expect(secondCrankRevs > firstCrankRevs)
    }

    @Test func zeroSpeedAndCadenceLeaveCountersUnchanged() {
        var encoder = CSCSMeasurementEncoder()
        let movingVitals = SimulatorVitals(
            speed: .milesPerHour(20),
            cadence: .rpm(90),
            supportsSpeed: true,
            supportsCadence: true
        )
        let stoppedVitals = SimulatorVitals(
            speed: .stopped,
            cadence: .stopped,
            supportsSpeed: true,
            supportsCadence: true,
        )

        let movingPacket = encoder.measurement(vitals: movingVitals, elapsed: .seconds(1))
        let stoppedPacket = encoder.measurement(vitals: stoppedVitals, elapsed: .seconds(1))

        let movingWheelRevs = readUInt32LittleEndian(from: movingPacket, at: 1)
        let movingCrankRevs = readUInt16LittleEndian(from: movingPacket, at: 7)
        let stoppedWheelRevs = readUInt32LittleEndian(from: stoppedPacket, at: 1)
        let stoppedCrankRevs = readUInt16LittleEndian(from: stoppedPacket, at: 7)

        #expect(stoppedWheelRevs == movingWheelRevs)
        #expect(stoppedCrankRevs == movingCrankRevs)
    }

    @Test func unsupportedMetricsContributeNoBytes() {
        var encoder = CSCSMeasurementEncoder()
        let vitals = SimulatorVitals(
            speed: .milesPerHour(20),
            cadence: .rpm(90),
            supportsSpeed: true,
            supportsCadence: false
        )

        let packet = encoder.measurement(vitals: vitals, elapsed: .seconds(1))

        #expect(packet.count == 7)
        #expect(packet[0] == 0x01)
    }
}
