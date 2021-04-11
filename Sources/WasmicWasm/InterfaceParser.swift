//
//  InterfaceParser.swift
//  WasmicWasm
//
//  Created by kateinoigakukun on 2021/04/10.
//

extension WebAssembly {

    public struct Export: Equatable, Hashable {
        public let name: String
        public let signature: FuncSignature

        public init(name: String, signature: FuncSignature) {
            self.name = name
            self.signature = signature
        }
    }
    public enum ParsingError: Swift.Error {
        case invalidIndex(Int, String)
    }

    public static func getExported(wasmBytes: [UInt8]) throws -> (functions: [Export], isWASI: Bool)
    {
        var input = InputByteStream(bytes: wasmBytes)
        var result = [SectionInfo]()
        var typeSection = TypeSection()
        var functionSection = FunctionSection()
        var exportSection = ExportSection()
        var importSection = ImportSection()

        input.readHeader()

        while !input.isEOF {
            let section = try input.readSectionInfo()
            result.append(section)
            switch section.type {
            case .type:
                typeSection = try TypeSection(from: &input)
            case .import:
                importSection = try ImportSection(from: &input)
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
        var isWASI: Bool = false
        for export in exportSection.exports {
            guard export.kind == .func else { continue }
            guard export.index < importSection.funcImportCount + functionSection.typeIndices.count
            else {
                throw ParsingError.invalidIndex(export.index, "export")
            }
            let typeIndex = functionSection.typeIndices[
                importSection.funcImportCount + export.index]
            guard typeIndex < typeSection.signatures.count else {
                throw ParsingError.invalidIndex(typeIndex, "type")
            }
            let signature = typeSection.signatures[typeIndex]
            exports.append(Export(name: export.name, signature: signature))
            if export.name == "_start" {
                isWASI = true
            }
        }
        return (exports, isWASI)
    }
}
