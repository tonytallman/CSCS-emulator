//
//  RunningViewModelTests.swift
//  CSCSEmulatorTests
//

import Foundation
import Testing
@testable import CSCSEmulator

@Suite @MainActor struct RunningViewModelTests {
    private func makeViewModel(
        simulation: SimulationControllingSpy? = nil,
        broadcaster: MeasurementBroadcastingSpy? = nil
    ) -> (RunningViewModel, SimulationControllingSpy, MeasurementBroadcastingSpy) {
        let simulation = simulation ?? SimulationControllingSpy()
        let broadcaster = broadcaster ?? MeasurementBroadcastingSpy()
        simulation.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))
        let viewModel = RunningViewModel(simulation: simulation, broadcaster: broadcaster)
        return (viewModel, simulation, broadcaster)
    }

    @Test(arguments: OperatingMode.allCases)
    func slidersEnabledOnlyInPedaling(mode: OperatingMode) {
        let (viewModel, simulation, _) = makeViewModel()
        simulation.setMode(mode)

        #expect(viewModel.slidersEnabled == (mode == .pedaling))
    }

    @Test func speedSetterForwardsClampedValueToEngine() {
        let (viewModel, simulation, _) = makeViewModel()
        simulation.setMode(.pedaling)

        viewModel.speedMPH = 100

        #expect(simulation.setSpeedCalls.count == 1)
        #expect(simulation.setSpeedCalls[0].converted(to: .milesPerHour).value == 50)
        #expect(viewModel.speedMPH == 50)
    }

    @Test func cadenceSetterForwardsClampedValueToEngine() {
        let (viewModel, simulation, _) = makeViewModel()
        simulation.setMode(.pedaling)

        viewModel.cadenceRPM = 250

        #expect(simulation.setCadenceCalls.count == 1)
        #expect(simulation.setCadenceCalls[0].converted(to: .revolutionsPerMinute).value == 200)
        #expect(viewModel.cadenceRPM == 200)
    }

    @Test func sliderGettersReflectVitals() {
        let (viewModel, simulation, _) = makeViewModel()
        simulation.setMode(.pedaling)
        simulation.setSpeed(.milesPerHour(22.5))
        simulation.setCadence(.rpm(95))

        #expect(viewModel.speedMPH == 22.5)
        #expect(viewModel.cadenceRPM == 95)
    }

    @Test func setModeForwardsToEngine() {
        let (viewModel, simulation, _) = makeViewModel()

        viewModel.setMode(.coasting)

        #expect(simulation.setModeCalls == [.coasting])
    }

    @Test func stopEmulatorStopsBroadcasterAndEngine() {
        let (viewModel, simulation, broadcaster) = makeViewModel()

        viewModel.stopEmulator()

        #expect(broadcaster.stopCallCount == 1)
        #expect(simulation.stopCallCount == 1)
    }

    @Test(arguments: [AppError.bluetoothUnavailable, AppError.bluetoothDisabled])
    func bluetoothUnavailableErrorStopsBroadcasterAndEngine(error: AppError) {
        let simulation = SimulationControllingSpy()
        let broadcaster = MeasurementBroadcastingSpy()
        simulation.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))
        broadcaster.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))
        let viewModel = RunningViewModel(simulation: simulation, broadcaster: broadcaster)

        broadcaster.lastError = error
        viewModel.handleErrorChange()

        #expect(broadcaster.stopCallCount == 1)
        #expect(simulation.stopCallCount == 1)
    }

    @Test func nonFatalErrorDoesNotStopEmulator() {
        let simulation = SimulationControllingSpy()
        let broadcaster = MeasurementBroadcastingSpy()
        simulation.start(configuration: SimulatorConfiguration(supportsSpeed: true, supportsCadence: true))
        let viewModel = RunningViewModel(simulation: simulation, broadcaster: broadcaster)

        broadcaster.lastError = .advertisingFailed
        viewModel.handleErrorChange()

        #expect(broadcaster.stopCallCount == 0)
        #expect(simulation.stopCallCount == 0)
    }
}
