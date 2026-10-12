//
//  MeasurementBroadcasterTests.swift
//  CSCSEmulatorTests
//

import CoreBluetooth
import Foundation
import Testing
@testable import CSCSEmulator

@Suite(.timeLimit(.minutes(1))) @MainActor struct MeasurementBroadcasterTests {
    private func makeBroadcaster(
        bluetooth: FakeBluetoothStateMonitor? = nil,
        makeServer: @escaping (SimulatorConfiguration) -> any MeasurementServer,
        vitals: @escaping () -> SimulatorVitals = {
            .initial(supportsSpeed: true, supportsCadence: true)
        },
    ) -> MeasurementBroadcaster {
        let bluetooth = bluetooth ?? FakeBluetoothStateMonitor()
        return MeasurementBroadcaster(
            bluetooth: bluetooth,
            makeServer: makeServer,
            vitalsProvider: vitals,
        )
    }

    @Test func makeServerReceivesStartConfiguration() async {
        var received: SimulatorConfiguration?
        let broadcaster = makeBroadcaster { configuration in
            received = configuration
            return FakeMeasurementServer(label: "server", slot: FakeServerSlot(), script: .succeed)
        }
        let configuration = SimulatorConfiguration(supportsSpeed: true, supportsCadence: false)
        broadcaster.start(configuration: configuration)
        #expect(received == configuration)
        broadcaster.stop()
        await broadcaster.runTask?.value
    }

    @Test func advertisingOnlyAfterStartSucceeds() async {
        let server = FakeMeasurementServer(label: "server", slot: FakeServerSlot(), script: .holdUntilReleased)
        let broadcaster = makeBroadcaster { _ in server }
        broadcaster.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))
        await server.waitUntilStartEntered()
        #expect(!broadcaster.isAdvertising)
        server.release()
        await server.waitUntilObservingSubscribers()
        #expect(broadcaster.isAdvertising)
        #expect(broadcaster.lastError == nil)
        broadcaster.stop()
        await broadcaster.runTask?.value
    }

    @Test(arguments: [
        (CBManagerAuthorization.denied, CBManagerState.poweredOn, AppError.bluetoothPermissionDenied),
        (CBManagerAuthorization.allowedAlways, CBManagerState.poweredOff, AppError.bluetoothDisabled),
        (CBManagerAuthorization.allowedAlways, CBManagerState.unsupported, AppError.bluetoothUnavailable),
        (CBManagerAuthorization.allowedAlways, CBManagerState.poweredOn, AppError.advertisingFailed),
    ])
    func startFailureMapsToAppError(
        authorization: CBManagerAuthorization,
        state: CBManagerState,
        expected: AppError,
    ) async {
        let bluetooth = FakeBluetoothStateMonitor(authorization: authorization, state: state)
        let server = FakeMeasurementServer(
            label: "server",
            slot: FakeServerSlot(),
            script: .fail(TestStartFailure()),
        )
        let broadcaster = makeBroadcaster(bluetooth: bluetooth) { _ in server }
        broadcaster.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))
        await broadcaster.runTask?.value
        #expect(broadcaster.lastError == expected)
        #expect(!broadcaster.isAdvertising)
    }

    @Test func mappingReadsAuthorizationAtFailureTime() async {
        let bluetooth = FakeBluetoothStateMonitor(
            authorization: .notDetermined,
            state: .poweredOn,
        )
        let server = FakeMeasurementServer(
            label: "server",
            slot: FakeServerSlot(),
            script: .holdUntilReleased,
        )
        let broadcaster = makeBroadcaster(bluetooth: bluetooth) { _ in server }
        broadcaster.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))
        await server.waitUntilStartEntered()
        bluetooth.authorization = .denied
        server.failOnRelease = TestStartFailure()
        server.release()
        await broadcaster.runTask?.value
        #expect(broadcaster.lastError == .bluetoothPermissionDenied)
    }

    @Test func cancelledStartSetsNoError() async {
        let server = FakeMeasurementServer(
            label: "server",
            slot: FakeServerSlot(),
            script: .suspendUntilCancelled,
        )
        let broadcaster = makeBroadcaster { _ in server }
        broadcaster.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))
        await server.waitUntilStartEntered()
        broadcaster.stop()
        await broadcaster.runTask?.value
        #expect(broadcaster.lastError == nil)
        #expect(!broadcaster.isAdvertising)
        #expect(server.eventLog.snapshot().filter { $0.hasSuffix("stopEntered") }.count == 1)
    }

    @Test func startSucceedingAfterStopDoesNotAdvertise() async {
        let server = FakeMeasurementServer(
            label: "server",
            slot: FakeServerSlot(),
            script: .holdUntilReleased,
        )
        let broadcaster = makeBroadcaster { _ in server }
        broadcaster.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))
        await server.waitUntilStartEntered()
        broadcaster.stop()
        server.release()
        await broadcaster.runTask?.value
        #expect(!broadcaster.isAdvertising)
        #expect(server.eventLog.snapshot().filter { $0.hasSuffix("stopReturned") }.count == 1)
        broadcaster.publishSample()
        #expect(server.publishes.isEmpty)
    }

    @Test func doubleStopThenRestartNeverOverlapsServers() async {
        let slot = FakeServerSlot()
        let log = SharedEventLog()
        let server1 = FakeMeasurementServer(label: "server1", slot: slot, script: .succeed, eventLog: log)
        let server2 = FakeMeasurementServer(label: "server2", slot: slot, script: .succeed, eventLog: log)
        let bluetooth = FakeBluetoothStateMonitor(state: .poweredOn)
        var serverIndex = 0
        let broadcaster = makeBroadcaster(bluetooth: bluetooth) { _ in
            serverIndex += 1
            return serverIndex == 1 ? server1 : server2
        }
        broadcaster.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))
        await server1.waitUntilObservingSubscribers()
        server1.holdStop()
        bluetooth.onStateChange?(.poweredOff)
        #expect(broadcaster.lastError == .bluetoothDisabled)
        #expect(!broadcaster.isAdvertising)
        broadcaster.stop()
        broadcaster.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))
        await server1.waitUntilStopEntered()
        #expect(!log.snapshot().contains { $0.hasPrefix("server2.startEntered") })
        #expect(slot.isOccupied)
        server1.releaseStop()
        await server2.waitUntilObservingSubscribers()
        let events = log.snapshot()
        let stop1 = events.firstIndex { $0 == "server1.stopReturned" }
        let start2 = events.firstIndex { $0 == "server2.startEntered" }
        #expect(stop1 != nil && start2 != nil && stop1! < start2!)
        #expect(broadcaster.isAdvertising)
        broadcaster.stop()
        await broadcaster.runTask?.value
    }

    @Test func rapidSequenceEndsWithOneRunningServer() async {
        let slot = FakeServerSlot()
        let log = SharedEventLog()
        var index = 0
        let broadcaster = makeBroadcaster { _ in
            index += 1
            return FakeMeasurementServer(
                label: "server\(index)",
                slot: slot,
                script: .succeed,
                eventLog: log,
            )
        }
        broadcaster.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))
        broadcaster.stop()
        broadcaster.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))
        broadcaster.stop()
        broadcaster.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))
        let last = FakeMeasurementServer.lastCreated!
        await last.waitUntilObservingSubscribers()
        let events = log.snapshot()
        for pair in zip(events, events.dropFirst()) {
            if pair.0.hasSuffix("startEntered") {
                #expect(pair.1.hasSuffix("stopReturned") || pair.1.hasSuffix("startEntered"))
            }
        }
        broadcaster.stop()
        await broadcaster.runTask?.value
    }

    @Test func bluetoothOffWhileRunning() async {
        let server = FakeMeasurementServer(label: "server", slot: FakeServerSlot(), script: .succeed)
        let bluetooth = FakeBluetoothStateMonitor(state: .poweredOn)
        let broadcaster = makeBroadcaster(bluetooth: bluetooth) { _ in server }
        broadcaster.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))
        await server.waitUntilObservingSubscribers()
        bluetooth.onStateChange?(.poweredOff)
        #expect(broadcaster.lastError == .bluetoothDisabled)
        #expect(!broadcaster.isAdvertising)
        await broadcaster.runTask?.value
        #expect(server.stopCount == 1)
    }

    @Test func resettingNeitherSetsErrorNorStops() async {
        let server = FakeMeasurementServer(label: "server", slot: FakeServerSlot(), script: .succeed)
        let bluetooth = FakeBluetoothStateMonitor(state: .poweredOn)
        let broadcaster = makeBroadcaster(bluetooth: bluetooth) { _ in server }
        broadcaster.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))
        await server.waitUntilObservingSubscribers()
        bluetooth.onStateChange?(.resetting)
        #expect(broadcaster.lastError == nil)
        #expect(broadcaster.isAdvertising)
        broadcaster.stop()
        await broadcaster.runTask?.value
    }

    @Test func prepareActivatesOnlyWhenAuthorizationKnown() {
        let bluetooth = FakeBluetoothStateMonitor(authorization: .notDetermined)
        let broadcaster = makeBroadcaster(bluetooth: bluetooth) { _ in
            FakeMeasurementServer(label: "server", slot: FakeServerSlot(), script: .succeed)
        }
        broadcaster.prepare()
        #expect(bluetooth.activateCount == 0)
        bluetooth.authorization = .allowedAlways
        broadcaster.prepare()
        #expect(bluetooth.activateCount == 1)
    }

    @Test func subscriberCountDrivesConnectionAndImmediatePublish() async {
        let server = FakeMeasurementServer(label: "server", slot: FakeServerSlot(), script: .succeed)
        let vitals = SimulatorVitals(
            speed: .milesPerHour(20),
            cadence: .rpm(90),
            supportsSpeed: true,
            supportsCadence: true,
        )
        let broadcaster = makeBroadcaster(makeServer: { _ in server }, vitals: { vitals })
        broadcaster.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))
        await server.waitUntilObservingSubscribers()
        server.setSubscriberCount(1)
        await server.waitForPublishCount(1)
        #expect(broadcaster.isConnected)
        server.setSubscriberCount(0)
        server.setSubscriberCount(1)
        await server.waitForPublishCount(2)
        broadcaster.stop()
        await broadcaster.runTask?.value
    }

    @Test func configurationNotVitalsSelectsHalves() async {
        let server = FakeMeasurementServer(label: "server", slot: FakeServerSlot(), script: .succeed)
        let vitals = SimulatorVitals(
            speed: .milesPerHour(20),
            cadence: .rpm(90),
            supportsSpeed: false,
            supportsCadence: false,
        )
        let broadcaster = makeBroadcaster(makeServer: { _ in server }, vitals: { vitals })
        broadcaster.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))
        await server.waitUntilObservingSubscribers()
        server.setSubscriberCount(1)
        await server.waitForPublishCount(1)
        #expect(server.publishes.last?.wheel != nil)
        #expect(server.publishes.last?.crank != nil)
        broadcaster.stop()
        await broadcaster.runTask?.value
    }

    @Test func publishSampleWithSubscriberPublishesBothHalves() async {
        let server = FakeMeasurementServer(label: "server", slot: FakeServerSlot(), script: .succeed)
        let vitals = SimulatorVitals(
            speed: .milesPerHour(20),
            cadence: .rpm(90),
            supportsSpeed: true,
            supportsCadence: true,
        )
        let broadcaster = makeBroadcaster(makeServer: { _ in server }, vitals: { vitals })
        broadcaster.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))
        await server.waitUntilObservingSubscribers()
        server.setSubscriberCount(1)
        await server.waitForPublishCount(1)
        broadcaster.publishSample()
        #expect(server.publishes.count == 2)
        #expect(server.publishes.last?.wheel != nil)
        #expect(server.publishes.last?.crank != nil)
        broadcaster.stop()
        await broadcaster.runTask?.value
    }

    @Test func publishSampleWithoutSubscribersDoesNotAdvanceCounters() async {
        let server = FakeMeasurementServer(label: "server", slot: FakeServerSlot(), script: .succeed)
        let vitals = SimulatorVitals(
            speed: .milesPerHour(20),
            cadence: .rpm(90),
            supportsSpeed: true,
            supportsCadence: true,
        )
        let broadcaster = makeBroadcaster(makeServer: { _ in server }, vitals: { vitals })
        broadcaster.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))
        await server.waitUntilObservingSubscribers()
        broadcaster.publishSample()
        #expect(server.publishes.isEmpty)
        server.setSubscriberCount(1)
        await server.waitForPublishCount(1)
        let first = server.publishes[0]
        server.setSubscriberCount(0)
        server.setSubscriberCount(1)
        await server.waitForPublishCount(2)
        let second = server.publishes[1]
        #expect((second.wheel?.cumulativeRevolutions ?? 0) > (first.wheel?.cumulativeRevolutions ?? 0))
        broadcaster.stop()
        await broadcaster.runTask?.value
    }

    @Test func stopLeadsToExactlyOneServerStop() async {
        let server = FakeMeasurementServer(label: "server", slot: FakeServerSlot(), script: .succeed)
        let broadcaster = makeBroadcaster { _ in server }
        broadcaster.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))
        await server.waitUntilObservingSubscribers()
        broadcaster.stop()
        await broadcaster.runTask?.value
        #expect(server.stopCount == 1)
    }
}

private struct TestStartFailure: Error {}

@MainActor
private final class FakeBluetoothStateMonitor: BluetoothStateMonitoring {
    var authorization: CBManagerAuthorization
    var state: CBManagerState?
    var onStateChange: ((CBManagerState) -> Void)?
    var activateCount = 0

    init(
        authorization: CBManagerAuthorization = .allowedAlways,
        state: CBManagerState? = .poweredOn,
    ) {
        self.authorization = authorization
        self.state = state
    }

    func activate() {
        activateCount += 1
    }
}

private final class SharedEventLog: @unchecked Sendable {
    private let lock = NSLock()
    private var events: [String] = []

    func append(_ event: String) {
        lock.lock()
        events.append(event)
        lock.unlock()
    }

    func snapshot() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return events
    }
}

private final class FakeServerSlot: @unchecked Sendable {
    private let lock = NSLock()
    private var occupied = false

    var isOccupied: Bool {
        lock.lock()
        defer { lock.unlock() }
        return occupied
    }

    func claim() {
        lock.lock()
        defer { lock.unlock() }
        if occupied {
            Issue.record("FakeServerSlot already claimed")
            return
        }
        occupied = true
    }

    func release() {
        lock.lock()
        defer { lock.unlock() }
        occupied = false
    }
}

private final class FakeMeasurementSubscriberCount: @unchecked Sendable {
    private let lock = NSLock()
    private var latest = 0
    private var active: [UUID: AsyncStream<Int>.Continuation] = [:]

    func stream() -> AsyncStream<Int> {
        AsyncStream { continuation in
            let id = UUID()
            lock.lock()
            active[id] = continuation
            let replay = latest
            lock.unlock()
            continuation.yield(replay)
            continuation.onTermination = { [weak self, id] _ in
                self?.remove(id)
            }
        }
    }

    func send(_ value: Int) {
        lock.lock()
        latest = value
        let continuations = Array(active.values)
        lock.unlock()
        for continuation in continuations {
            continuation.yield(value)
        }
    }

    private func remove(_ id: UUID) {
        lock.lock()
        active.removeValue(forKey: id)
        lock.unlock()
    }
}

@MainActor
private final class FakeMeasurementServer: MeasurementServer {
    enum Script {
        case succeed
        case fail(any Error)
        case suspendUntilCancelled
        case holdUntilReleased
    }

    static weak var lastCreated: FakeMeasurementServer?

    private let label: String
    private let slot: FakeServerSlot
    private let script: Script
    let eventLog: SharedEventLog
    private let subscriberCounts = FakeMeasurementSubscriberCount()

    private(set) var publishes: [RevolutionCounters.Sample] = []
    private(set) var stopCount = 0

    var failOnRelease: (any Error)?

    private var startEnteredContinuations: [CheckedContinuation<Void, Never>] = []
    private var releaseContinuations: [CheckedContinuation<Void, Never>] = []
    private var observingSubscribersContinuations: [CheckedContinuation<Void, Never>] = []
    private var stopEnteredContinuations: [CheckedContinuation<Void, Never>] = []
    private var stopHeld = false
    private var stopHoldContinuations: [CheckedContinuation<Void, Never>] = []
    private var publishWaiters: [CheckedContinuation<Void, Never>] = []

    init(
        label: String,
        slot: FakeServerSlot,
        script: Script,
        eventLog: SharedEventLog = SharedEventLog(),
    ) {
        self.label = label
        self.slot = slot
        self.script = script
        self.eventLog = eventLog
        Self.lastCreated = self
    }

    var subscriberCount: AsyncStream<Int> {
        get async {
            resumeObservingSubscribersWaiters()
            return subscriberCounts.stream()
        }
    }

    func setSubscriberCount(_ count: Int) {
        subscriberCounts.send(count)
    }

    func start() async throws {
        slot.claim()
        eventLog.append("\(label).startEntered")
        resumeStartEnteredWaiters()

        switch script {
        case .succeed:
            return
        case let .fail(error):
            slot.release()
            throw error
        case .suspendUntilCancelled:
            do {
                try await Task.sleep(for: .seconds(3600))
            } catch {
                slot.release()
                throw error
            }
        case .holdUntilReleased:
            await withCheckedContinuation { continuation in
                releaseContinuations.append(continuation)
            }
            if let failOnRelease {
                slot.release()
                throw failOnRelease
            }
            return
        }
    }

    func stop() async {
        eventLog.append("\(label).stopEntered")
        resumeStopEnteredWaiters()
        if stopHeld {
            await withCheckedContinuation { continuation in
                stopHoldContinuations.append(continuation)
            }
        }
        stopCount += 1
        subscriberCounts.send(0)
        slot.release()
        eventLog.append("\(label).stopReturned")
    }

    func publish(_ sample: RevolutionCounters.Sample) {
        publishes.append(sample)
        resumePublishWaiters()
    }

    func holdStop() {
        stopHeld = true
    }

    func releaseStop() {
        stopHeld = false
        let waiters = stopHoldContinuations
        stopHoldContinuations = []
        for waiter in waiters {
            waiter.resume()
        }
    }

    func release() {
        let waiters = releaseContinuations
        releaseContinuations = []
        for waiter in waiters {
            waiter.resume()
        }
    }

    func waitUntilStartEntered() async {
        if eventLog.snapshot().contains(where: { $0 == "\(label).startEntered" }) { return }
        await withCheckedContinuation { continuation in
            startEnteredContinuations.append(continuation)
        }
    }

    func waitUntilStopEntered() async {
        if eventLog.snapshot().contains(where: { $0 == "\(label).stopEntered" }) { return }
        await withCheckedContinuation { continuation in
            stopEnteredContinuations.append(continuation)
        }
    }

    func waitUntilObservingSubscribers() async {
        await withCheckedContinuation { continuation in
            observingSubscribersContinuations.append(continuation)
        }
    }

    func waitForPublishCount(_ count: Int) async {
        if publishes.count >= count { return }
        await withCheckedContinuation { continuation in
            publishWaiters.append(continuation)
        }
        if publishes.count < count {
            await waitForPublishCount(count)
        }
    }

    private func resumeStartEnteredWaiters() {
        let waiters = startEnteredContinuations
        startEnteredContinuations = []
        for waiter in waiters {
            waiter.resume()
        }
    }

    private func resumeObservingSubscribersWaiters() {
        let waiters = observingSubscribersContinuations
        observingSubscribersContinuations = []
        for waiter in waiters {
            waiter.resume()
        }
    }

    private func resumeStopEnteredWaiters() {
        let waiters = stopEnteredContinuations
        stopEnteredContinuations = []
        for waiter in waiters {
            waiter.resume()
        }
    }

    private func resumePublishWaiters() {
        let waiters = publishWaiters
        publishWaiters = []
        for waiter in waiters {
            waiter.resume()
        }
    }
}
