//
//  ShortcutsStorage.swift
//  WasmicKit
//
//  Created by kateinoigakukun on 2021/04/11.
//

import Foundation

public class ShortcutsStorage {

    private let fileManager = FileManager()
    private lazy var shortcutsURL: URL = {
        let sharedContainer = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: "group.dev.katei.wasmic"
        )!
        return sharedContainer.appendingPathComponent("Shortcuts")
    }()

    public init() {}
    private func prepareDirectory() throws {
        if !fileManager.fileExists(atPath: shortcutsURL.path) {
            try fileManager.createDirectory(at: shortcutsURL, withIntermediateDirectories: true, attributes: nil)
        }
    }
    public func importDocument(_ url: URL) throws -> URL {
        try prepareDirectory()
        let targetURL = shortcutsURL.appendingPathComponent(url.lastPathComponent)
        if fileManager.fileExists(atPath: targetURL.path) {
            try fileManager.removeItem(at: targetURL)
        }
        try fileManager.copyItem(at: url, to: targetURL)
        return targetURL
    }

    public func documents() -> [URL] {
        var files: [URL] = []
        let enumerator = fileManager.enumerator(atPath: shortcutsURL.path)
        while let filePath = enumerator?.nextObject() as? String {
            guard filePath.contains(".wasm") else { continue }
            let fileURL = shortcutsURL.appendingPathComponent(filePath)
            files.append(fileURL)
        }
        return files
    }
}
