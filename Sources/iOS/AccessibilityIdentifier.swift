//
//  AccessibilityIdentifier.swift
//  Wasmic
//
//  Created by kateinoigakukun on 2021/04/12.
//

import Foundation

public enum WasmicAccessibilityIdentifier {
    public enum TextDocument: String {
        case closeButton = "dev.katei.wasmic.text-document.close-button"
        case runButton = "dev.katei.wasmic.text-document.run-button"
    }
    public enum WasmInvocation: String {
        case runButton = "dev.katei.wasmic.wasm-invocation.run-button"
    }
}
