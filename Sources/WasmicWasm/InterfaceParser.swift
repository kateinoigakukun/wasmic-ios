//
//  InterfaceParser.swift
//  WasmicWasm
//
//  Created by kateinoigakukun on 2021/04/10.
//

extension WebAssembly {

    public struct Export {
        public let name: String
        public let signature: FuncSignature
    }
    public enum ParsingError: Swift.Error {
        case invalidIndex(Int, String)
    }
    public static func getExported(wasmBytes: [UInt8]) throws -> [Export] {
        var input = InputByteStream(bytes: wasmBytes)
        var result = [SectionInfo]()
        var typeSection = TypeSection()
        var functionSection = FunctionSection()
        var exportSection = ExportSection()

        input.readHeader()

        while !input.isEOF {
            let section = try input.readSectionInfo()
            result.append(section)
            switch section.type {
            case .type:
                typeSection = try TypeSection(from: &input)
            case .function:
                functionSection = try FunctionSection(from: &input)
                break
            case .export:
                exportSection = try ExportSection(from: &input)
            default:
                input.seek(section.endOffset)
            }
        }
        var exports: [Export] = []
        for export in exportSection.exports {
            guard export.index < functionSection.typeIndices.count else {
                throw ParsingError.invalidIndex(export.index, "export")
            }
            let typeIndex = functionSection.typeIndices[export.index]
            guard typeIndex < typeSection.signatures.count else {
                throw ParsingError.invalidIndex(typeIndex, "type")
            }
            let signature = typeSection.signatures[typeIndex]
            exports.append(Export(name: export.name, signature: signature))
        }
        return exports
    }
}
