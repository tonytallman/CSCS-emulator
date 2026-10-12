//
//  MeasurementServer.swift
//  CSCSEmulator
//

@MainActor
protocol MeasurementServer: AnyObject {
    var subscriberCount: AsyncStream<Int> { get async }
    func start() async throws
    func stop() async
    func publish(_ sample: RevolutionCounters.Sample)
}
