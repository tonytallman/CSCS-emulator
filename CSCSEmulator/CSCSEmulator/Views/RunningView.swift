//
//  RunningView.swift
//  CSCSEmulator
//

import SwiftUI

struct RunningView: View {
    @Bindable var viewModel: RunningViewModel
    var engine: SimulationEngine<SystemRandomNumberGenerator>?
    @State private var showError = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                modeSection
                metricsSection
                infoCallout
                stopButton
            }
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
            .padding()
        }
        .navigationTitle("CSCS BLE Emulator")
        .background {
            if let engine {
                SimulationObservation(engine: engine)
            }
        }
        .onChange(of: viewModel.lastError) { _, error in
            viewModel.handleErrorChange()
            showError = error != nil
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
            Image(systemName: "bicycle")
                .font(.system(size: 48))
                .foregroundStyle(.blue)
            Text("CSCS BLE Emulator")
                .font(.title2)
                .fontWeight(.bold)
            HStack(spacing: 6) {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
                Text("Emulator Running")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.green.opacity(0.12))
            .clipShape(Capsule())
        }
        .padding(.top, 8)
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MODE")
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("Mode", selection: Binding(
                get: { viewModel.mode },
                set: { viewModel.setMode($0) }
            )) {
                Text("Pedaling").tag(OperatingMode.pedaling)
                Text("Coasting").tag(OperatingMode.coasting)
                Text("Random").tag(OperatingMode.random)
            }
            .pickerStyle(.segmented)

            modeHelperText
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var modeHelperText: some View {
        switch viewModel.mode {
        case .pedaling:
            Text("Pedaling: normal riding (speed and cadence active)")
        case .coasting:
            Text("Coasting: not pedaling (cadence = 0, speed decays to 0)")
        case .random:
            Text("Random: cadence varies around 90 rpm, speed derived from cadence")
        }
    }

    @ViewBuilder
    private var metricsSection: some View {
        if viewModel.supportsSpeed || viewModel.supportsCadence {
            VStack(alignment: .leading, spacing: 12) {
                Text("METRICS")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if viewModel.supportsSpeed {
                    metricCard(
                        icon: "speedometer",
                        title: "Speed",
                        unit: "mph",
                        value: viewModel.formattedSpeed,
                        range: viewModel.speedRangeMPH,
                        valueBinding: Binding(
                            get: { viewModel.speedMPH },
                            set: { viewModel.speedMPH = $0 }
                        ),
                        enabled: viewModel.slidersEnabled
                    )
                }

                if viewModel.supportsCadence {
                    metricCard(
                        icon: "gearshape.2",
                        title: "Cadence",
                        unit: "rpm",
                        value: viewModel.formattedCadence,
                        range: viewModel.cadenceRangeRPM,
                        valueBinding: Binding(
                            get: { viewModel.cadenceRPM },
                            set: { viewModel.cadenceRPM = $0 }
                        ),
                        enabled: viewModel.slidersEnabled
                    )
                }
            }
        }
    }

    private func metricCard(
        icon: String,
        title: String,
        unit: String,
        value: String,
        range: ClosedRange<Double>,
        valueBinding: Binding<Double>,
        enabled: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.blue)
                VStack(alignment: .leading) {
                    Text(title)
                        .fontWeight(.semibold)
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Slider(value: valueBinding, in: range)
                .disabled(!enabled)
        }
        .padding()
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var infoCallout: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.blue)
            Text("The emulator is running and advertising the Cycling Speed and Cadence Service (CSCS). Connected devices will receive the simulated speed and cadence values.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var stopButton: some View {
        Button(role: .destructive) {
            viewModel.stopEmulator()
        } label: {
            Label("Stop Emulator", systemImage: "stop.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.red)
        .controlSize(.large)
    }

    private var cardBackground: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(.secondarySystemGroupedBackground)
        #endif
    }
}

private struct SimulationObservation: View {
    @Bindable var engine: SimulationEngine<SystemRandomNumberGenerator>

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
            .onChange(of: engine.isRunning) { _, _ in }
            .onChange(of: engine.state.vitals) { _, _ in }
    }
}
