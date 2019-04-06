//
//  AppConfig.swift
//  Meruru
//
//  Created by castaneai on 2019/04/06.
//  Copyright © 2019 castaneai. All rights reserved.
//

import Foundation
import Cocoa

struct AppConfigData : Codable {
    var mirakurunPath: String?
}

class AppConfig {
    static let shared = AppConfig()
    
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()
    
    private let fileManager = FileManager.default
    private let configFilePath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".config")
        .appendingPathComponent("meruru")
        .appendingPathComponent("config.json")
    
    var currentData: AppConfigData?
    
    init() {
        do {
            let configDir = configFilePath.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: configDir.path) {
                try fileManager.createDirectory(at: configDir, withIntermediateDirectories: true)
            }
            if !fileManager.fileExists(atPath: configFilePath.path) {
                fileManager.createFile(atPath: configFilePath.path, contents: "{}".data(using: .utf8)!)
            }
            let data = try Data(contentsOf: configFilePath)
            currentData = try jsonDecoder.decode(AppConfigData.self, from: data)
        } catch let err as NSError {
            let alert = NSAlert()
            alert.messageText = err.localizedDescription
            alert.runModal()
            NSApplication.shared.terminate(self)
        }
    }
    
    func save() throws {
        let encoded = try jsonEncoder.encode(currentData)
        try encoded.write(to: configFilePath)
    }
}
