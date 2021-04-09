//
//  WatDocument.swift
//  Wasmic
//
//  Created by kateinoigakukun on 2021/04/09.
//

import Foundation

class WatDocument: TextDocument {
    init() {
        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent("main.wat")

        super.init(fileURL: url)
    }
}
