//
//  AppInfo.swift
//  CSCSEmulator
//

import Foundation

enum AppInfo {
    static var title: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? "CSCS Emulator"
    }
}
