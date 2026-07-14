//
//  SettingsOpening.swift
//  CSCSEmulator
//

import Foundation

#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Opens system or app settings so the user can enable Bluetooth or grant permission.
@MainActor
protocol SettingsOpening: AnyObject {
    func openBluetoothSettings()
}

@MainActor
final class SystemSettingsOpener: SettingsOpening {
    func openBluetoothSettings() {
        #if os(macOS)
        if let url = URL(string: "x-apple.systempreferences:com.apple.BluetoothSettings") {
            NSWorkspace.shared.open(url)
        }
        #else
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }
}
