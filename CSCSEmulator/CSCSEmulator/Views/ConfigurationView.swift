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
    var lastError: AppError? { get }

    func startEmulator()
}

struct ConfigurationView<ViewModel: ConfigurationViewModel>: View {
    @Bindable var viewModel: ViewModel
    @State private var showError = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                supportedMetricsSection
                infoCallout
                startButton
            }
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
            .padding()
        }
        .navigationTitle("CSCS BLE Emulator")
        .onChange(of: viewModel.lastError) { _, error in
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

    private var startButton: some View {
        Button {
            viewModel.startEmulator()
        } label: {
            Label("Start Emulator", systemImage: "play.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!viewModel.canStart)
    }

    private var cardBackground: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(.secondarySystemGroupedBackground)
        #endif
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        ConfigurationView(viewModel: PreviewConfigurationViewModel())
    }
}
#endif
