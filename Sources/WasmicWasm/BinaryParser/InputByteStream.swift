public struct InputByteStream {
    public private(set) var offset: Int
    public let bytes: ArraySlice<UInt8>
    public var isEOF: Bool {
        offset >= bytes.endIndex
    }

    public init(bytes: ArraySlice<UInt8>) {
        self.bytes = bytes
        self.offset = bytes.startIndex
    }

    public init(bytes: [UInt8]) {
        self.init(bytes: bytes[...])
    }

    mutating func readHeader() {
        let maybeMagic = read(4)
        assert(maybeMagic.elementsEqual(magic))
        let maybeVersion = read(4)
        assert(maybeVersion.elementsEqual(version))
    }

    mutating func readSectionInfo() throws -> SectionInfo {
        let startOffset = offset
        let rawType = readUInt8()
        guard let type = SectionType(rawValue: rawType) else {
            throw Error.unexpectedSection(rawType)
        }
        let size = Int(readVarUInt32())
        let contentStart = offset

        return .init(
            startOffset: startOffset,
            endOffset: contentStart + size,
            type: type,
            size: size
        )
    }

    public mutating func seek(_ offset: Int) {
        self.offset = offset
    }

    public mutating func skip(_ length: Int) {
        offset += length
    }

    public mutating func read(_ length: Int) -> ArraySlice<UInt8> {
        let result = bytes[offset..<offset + length]
        offset += length
        return result
    }

    mutating func readUInt8() -> UInt8 {
        let byte = read(1)
        return byte[byte.startIndex]
    }

    public mutating func readVarUInt32() -> UInt32 {
        let (value, advanced) = decodeULEB128(bytes[offset...], UInt32.self)
        offset += advanced
        return value
    }

    mutating func consumeULEB128<T>(_: T.Type) where T: UnsignedInteger, T: FixedWidthInteger {
        let (_, advanced) = decodeULEB128(bytes[offset...], T.self)
        offset += advanced
    }

    mutating func readString() -> String {
        let length = Int(readVarUInt32())
        let bytes = self.bytes[offset..<offset + length]
        let name = String(decoding: bytes, as: Unicode.ASCII.self)
        offset += length
        return name
    }

    enum Error: Swift.Error {
        case invalidValueType(UInt8)
        case expectConstOpcode(UInt8)
        case expectI32Const(ConstOpcode)
        case unexpectedOpcode(UInt8)
        case unexpectedSection(UInt8)
        case expectEnd
    }

    /// https://webassembly.github.io/spec/core/binary/types.html#result-types
    mutating func readResultTypes() throws -> [ValueType] {
        let count = readVarUInt32()
        var resultTypes: [ValueType] = []
        for _ in 0..<count {
            let rawType = readUInt8()
            guard let type = ValueType(rawValue: rawType) else {
                throw Error.invalidValueType(rawType)
            }
            resultTypes.append(type)
        }
        return resultTypes
    }

    typealias Consumer = (ArraySlice<UInt8>) throws -> Void

    mutating func consumeString(consumer: Consumer? = nil) rethrows {
        let start = offset
        let length = Int(readVarUInt32())
        offset += length
        try consumer?(bytes[start..<offset])
    }

    /// https://webassembly.github.io/spec/core/binary/types.html#table-types
    mutating func consumeTable(consumer: Consumer? = nil) rethrows {
        let start = offset
        _ = readUInt8() // element type
        let hasMax = readUInt8() != 0
        _ = readVarUInt32() // initial
        if hasMax {
            _ = readVarUInt32() // max
        }
        try consumer?(bytes[start ..< offset])
    }

    /// https://webassembly.github.io/spec/core/binary/types.html#memory-types
    mutating func consumeMemory(consumer: Consumer? = nil) rethrows {
        let start = offset
        let flags = readUInt8()
        let hasMax = (flags & LIMITS_HAS_MAX_FLAG) != 0
        _ = readVarUInt32() // initial
        if hasMax {
            _ = readVarUInt32() // max
        }
        try consumer?(bytes[start ..< offset])
    }

    /// https://webassembly.github.io/spec/core/binary/types.html#global-types
    mutating func consumeGlobalHeader(consumer: Consumer? = nil) rethrows {
        let start = offset
        _ = readUInt8() // value type
        _ = readUInt8() // mutable
        try consumer?(bytes[start ..< offset])
    }
}
