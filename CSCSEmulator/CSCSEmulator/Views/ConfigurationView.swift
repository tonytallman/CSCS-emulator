//
//  ConfigurationView.swift
//  CSCSEmulator
//

import Observation
import SwiftUI

@MainActor
protocol ConfigurationViewModel: AnyObject, Observable {
    var supportsSpeed: Bool { get set }
    var supportsCadence: Bool { get set }
    var canStart: Bool { get }
    var availability: BluetoothAvailability { get }
    var isAdvertising: Bool { get }
    var isStarting: Bool { get }
    var lastError: AppError? { get }

    func startEmulator()
    func handleStartOutcome()
    func openSettings()
    func refreshAvailability()
}

struct ConfigurationView<ViewModel: ConfigurationViewModel>: View {
    @Bindable var viewModel: ViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var showError = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                supportedMetricsSection
                infoCallout
                if viewModel.availability != .ready {
                    availabilityCallout
                }
                startButton
            }
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
            .padding()
        }
        .scrollBounceBehavior(.basedOnSize)
        .onChange(of: viewModel.lastError) { _, error in
            showError = error != nil
            viewModel.handleStartOutcome()
        }
        .onChange(of: viewModel.isAdvertising) { _, _ in
            viewModel.handleStartOutcome()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                viewModel.refreshAvailability()
            }
        }
        .alert(
            "Error",
            isPresented: $showError,
            presenting: viewModel.lastError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { error in
            Text(error.localizedDescription)
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image("BrandMark")
                .resizable()
                .scaledToFit()
                .frame(height: 48)
                .accessibilityLabel("Bike Sensor Emulator")
            Text(AppInfo.title)
                .font(.title2)
                .fontWeight(.bold)
            Text("Choose which metrics this emulator will support. These choices cannot be changed after starting.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var supportedMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SUPPORTED METRICS")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                metricRow(
                    icon: "speedometer",
                    title: "Speed",
                    subtitle: "Support speed (mph)",
                    isOn: $viewModel.supportsSpeed
                )
                Divider()
                metricRow(
                    icon: "gearshape.2",
                    title: "Cadence",
                    subtitle: "Support cadence (rpm)",
                    isOn: $viewModel.supportsCadence
                )
            }
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func metricRow(
        icon: String,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle(title, isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .padding()
    }

    private var infoCallout: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.blue)
            Text("After the emulator is started, the supported metrics cannot be changed.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var availabilityCallout: some View {
        if let error = viewModel.availability.appError {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if viewModel.availability.showsSettingsButton {
                    Button {
                        viewModel.openSettings()
                    } label: {
                        Label("Open Settings", systemImage: "gear")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var startButton: some View {
        Button {
            viewModel.startEmulator()
        } label: {
            Group {
                if viewModel.isStarting {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Label("Start Emulator", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!viewModel.canStart || viewModel.isStarting)
    }

    private var cardBackground: Color {
        Color(.secondarySystemGroupedBackground)
    }
}

#if DEBUG
#Preview("Ready") {
    NavigationStack {
        ConfigurationView(viewModel: PreviewConfigurationViewModel())
    }
}

#Preview("Permission Denied") {
    NavigationStack {
        ConfigurationView(
            viewModel: PreviewConfigurationViewModel(availability: .permissionDenied)
        )
    }
}

#Preview("Bluetooth Off") {
    NavigationStack {
        ConfigurationView(
            viewModel: PreviewConfigurationViewModel(availability: .poweredOff)
        )
    }
}
#endif
