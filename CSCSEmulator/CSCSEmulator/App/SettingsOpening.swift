//
//  SettingsOpening.swift
//  CSCSEmulator
//

import Foundation
import UIKit

/// Opens system or app settings so the user can enable Bluetooth or grant permission.
@MainActor
protocol SettingsOpening: AnyObject {
    func openBluetoothSettings()
}

@MainActor
final class SystemSettingsOpener: SettingsOpening {
    func openBluetoothSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
