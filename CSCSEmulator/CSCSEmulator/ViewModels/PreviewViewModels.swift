//
//  PreviewViewModels.swift
//  CSCSEmulator
//

#if DEBUG
import Foundation
import Observation

@Observable
@MainActor
final class PreviewRootViewModel: RootViewModel {
    private let previewConfigurationViewModel: PreviewConfigurationViewModel
    private let previewRunningViewModel: PreviewRunningViewModel
    var appState: AppState

    init(
        appState: AppState = .configuring,
        configurationViewModel: PreviewConfigurationViewModel? = nil,
        runningViewModel: PreviewRunningViewModel? = nil,
    ) {
        self.appState = appState
        self.previewConfigurationViewModel = configurationViewModel ?? PreviewConfigurationViewModel()
        self.previewRunningViewModel = runningViewModel ?? PreviewRunningViewModel()
    }

    var configurationViewModel: some ConfigurationViewModel {
        previewConfigurationViewModel
    }

    var runningViewModel: some RunningViewModel {
        previewRunningViewModel
    }
}

@Observable
@MainActor
final class PreviewConfigurationViewModel: ConfigurationViewModel {
    var supportsSpeed: Bool
    var supportsCadence: Bool
    var availability: BluetoothAvailability
    var isAdvertising: Bool
    var isStarting: Bool
    var lastError: AppError?

    init(
        supportsSpeed: Bool = true,
        supportsCadence: Bool = true,
        availability: BluetoothAvailability = .ready,
        isAdvertising: Bool = false,
        isStarting: Bool = false,
        lastError: AppError? = nil,
    ) {
        self.supportsSpeed = supportsSpeed
        self.supportsCadence = supportsCadence
        self.availability = availability
        self.isAdvertising = isAdvertising
        self.isStarting = isStarting
        self.lastError = lastError
    }

    var canStart: Bool {
        SimulatorConfiguration(
            supportsSpeed: supportsSpeed,
            supportsCadence: supportsCadence,
        ).isValid && availability == .ready
    }

    func startEmulator() {}

    func handleStartOutcome() {}

    func openSettings() {}

    func refreshAvailability() {}
}

@Observable
@MainActor
final class PreviewRunningViewModel: RunningViewModel {
    private static let speedFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 1
        formatter.numberFormatter.minimumFractionDigits = 0
        return formatter
    }()

    var mode: OperatingMode
    var supportsSpeed: Bool
    var supportsCadence: Bool
    var isConnected: Bool
    var lastError: AppError?
    var speedMPH: Double
    var cadenceRPM: Double
    let speedRangeMPH: ClosedRange<Double>
    let cadenceRangeRPM: ClosedRange<Double>
    let simulationEngine: SimulationEngine<SystemRandomNumberGenerator>? = nil

    init(
        mode: OperatingMode = .random,
        supportsSpeed: Bool = true,
        supportsCadence: Bool = true,
        isConnected: Bool = true,
        lastError: AppError? = nil,
        speedMPH: Double = 18.5,
        cadenceRPM: Double = 90,
    ) {
        self.mode = mode
        self.supportsSpeed = supportsSpeed
        self.supportsCadence = supportsCadence
        self.isConnected = isConnected
        self.lastError = lastError
        self.speedMPH = speedMPH
        self.cadenceRPM = cadenceRPM
        speedRangeMPH = SimulatorRanges.speedMin.converted(to: .milesPerHour).value...SimulatorRanges.speedMax.converted(to: .milesPerHour).value
        cadenceRangeRPM = SimulatorRanges.cadenceMin.converted(to: .revolutionsPerMinute).value...SimulatorRanges.cadenceMax.converted(to: .revolutionsPerMinute).value
    }

    var slidersEnabled: Bool {
        mode == .manual
    }

    var formattedSpeed: String {
        speedMPH.formatted(.number.precision(.fractionLength(0...1))) + " " + speedUnit
    }

    var formattedCadence: String {
        cadenceRPM.formatted(.number.precision(.fractionLength(0))) + " " + cadenceUnit
    }

    var speedUnit: String {
        Self.speedFormatter.string(from: UnitSpeed.milesPerHour)
    }

    var cadenceUnit: String {
        String(localized: "rpm")
    }

    func setMode(_ mode: OperatingMode) {
        self.mode = mode
    }

    func stopEmulator() {}

    func handleErrorChange() {}
}
#endif
