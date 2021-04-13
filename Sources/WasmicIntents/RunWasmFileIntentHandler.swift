//
//  RunWasmFileIntentHandler.swift
//  WasmicIntents
//
//  Created by kateinoigakukun on 2021/04/10.
//

import Intents
import UIKit
import os.log
import WasmicKit

final class RunWasmFileIntentHandler: NSObject, RunWasmFileIntentHandling {
    func provideFileOptionsCollection(
        for intent: RunWasmFileIntent,
        with completion: @escaping (INObjectCollection<INFile>?, Error?) -> Void
    ) {
        let storage = ShortcutsStorage()
        let files = storage.documents().map { fileURL in
            INFile(
                fileURL: fileURL, filename: fileURL.lastPathComponent,
                typeIdentifier: "dev.katei.wasmic.wasm")
        }
        completion(INObjectCollection(items: files), nil)
    }

    func handle(
        intent: RunWasmFileIntent, completion: @escaping (RunWasmFileIntentResponse) -> Void
    ) {
        guard let file = intent.file,
            let functionName = intent.functionName
        else {
            completion(RunWasmFileIntentResponse(code: .failure, userActivity: nil))
            return
        }
        let arguments = intent.arguments ?? []

        do {
            let results = try WebAssembly.execute(
                wasmBytes: Array(file.data),
                function: functionName,
                args: arguments.map(\.description))
            let response = RunWasmFileIntentResponse(code: .success, userActivity: nil)
            response.results = results.map { $0.asDouble }
            completion(response)
        } catch {
            os_log(
                "Failed to execute, error: '%@'",
                log: OSLog.default, type: .error,
                file as CVarArg, error as CVarArg)
            completion(.init(code: .failure, userActivity: nil))
        }
    }
}

extension WebAssembly.Value {
    fileprivate var asDouble: Double {
        switch self {
        case .i32(let v): return Double(v)
        case .i64(let v): return Double(v)
        case .f32(let v): return Double(v)
        case .f64(let v): return Double(v)
        }
    }
}
