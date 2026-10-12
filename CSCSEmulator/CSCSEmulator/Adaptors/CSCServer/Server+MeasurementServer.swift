//
//  Server+MeasurementServer.swift
//  CSCSEmulator
//

import CSCServer
import Foundation

@MainActor
final class ServerToMeasurementServer: MeasurementServer {
    private let server: Server
    private let input: (RevolutionCounters.Sample) -> Void
    private let finish: () -> Void

    init(configuration: SimulatorConfiguration) {
        let reject = RejectSetCumulativeWheelRevolutions()
        // Counters are cumulative, so a replaced element loses no revolutions.
        switch (configuration.supportsSpeed, configuration.supportsCadence) {
        case (true, true):
            let (stream, continuation) = AsyncStream.makeStream(
                of: WheelAndCrankRevolution.self,
                bufferingPolicy: .bufferingNewest(1),
            )
            input = { sample in
                guard sample.wheel != nil || sample.crank != nil else { return }
                continuation.yield(
                    WheelAndCrankRevolution(
                        wheel: sample.wheel.map {
                            WheelRevolution(
                                cumulativeRevolutions: $0.cumulativeRevolutions,
                                lastEventTime: $0.lastEventTime,
                            )
                        },
                        crank: sample.crank.map {
                            CrankRevolution(
                                cumulativeRevolutions: $0.cumulativeRevolutions,
                                lastEventTime: $0.lastEventTime,
                            )
                        },
                    ),
                )
            }
            finish = { continuation.finish() }
            server = Server.wheelAndCrankRevolutions(stream, setCumulativeWheelRevolutions: reject).build()
        case (true, false):
            let (stream, continuation) = AsyncStream.makeStream(
                of: WheelRevolution.self,
                bufferingPolicy: .bufferingNewest(1),
            )
            input = { sample in
                guard let wheel = sample.wheel else { return }
                continuation.yield(
                    WheelRevolution(
                        cumulativeRevolutions: wheel.cumulativeRevolutions,
                        lastEventTime: wheel.lastEventTime,
                    ),
                )
            }
            finish = { continuation.finish() }
            server = Server.wheelRevolutions(stream, setCumulativeWheelRevolutions: reject).build()
        case (false, true):
            let (stream, continuation) = AsyncStream.makeStream(
                of: CrankRevolution.self,
                bufferingPolicy: .bufferingNewest(1),
            )
            input = { sample in
                guard let crank = sample.crank else { return }
                continuation.yield(
                    CrankRevolution(
                        cumulativeRevolutions: crank.cumulativeRevolutions,
                        lastEventTime: crank.lastEventTime,
                    ),
                )
            }
            finish = { continuation.finish() }
            server = Server.crankRevolutions(stream).build()
        case (false, false):
            preconditionFailure("SimulatorConfiguration.isValid excludes both metrics disabled")
        }
    }

    var subscriberCount: AsyncStream<Int> {
        get async { await server.measurementSubscriberCount }
    }

    func start() async throws {
        try await server.start()
    }

    func stop() async {
        await server.stop()
        finish()
    }

    func publish(_ sample: RevolutionCounters.Sample) {
        input(sample)
    }
}

private nonisolated struct SetCumulativeWheelRevolutionsUnsupported: Error {}

private nonisolated struct RejectSetCumulativeWheelRevolutions: CumulativeWheelRevolutionsDelegate {
    func setCumulativeWheelRevolutions(_ cumulativeRevolutions: UInt32) async throws {
        throw SetCumulativeWheelRevolutionsUnsupported()
    }
}
