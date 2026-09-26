import Foundation

/// Minimal ZIP archiver: STORED entries only (valid per the EPUB spec, and a
/// novel-sized book gains little from deflate), CRC-32 computed locally.
/// Entry order is preserved — EPUB requires `mimetype` to be the first entry.
nonisolated enum ZipWriter {
    struct Entry {
        var path: String
        var data: Data

        init(path: String, data: Data) {
            self.path = path
            self.data = data
        }

        init(path: String, text: String) {
            self.path = path
            self.data = Data(text.utf8)
        }
    }

    private static let crcTable: [UInt32] = (0..<256).map { index -> UInt32 in
        var crc = UInt32(index)
        for _ in 0..<8 {
            crc = (crc & 1) == 1 ? (0xEDB88320 ^ (crc >> 1)) : (crc >> 1)
        }
        return crc
    }

    static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data {
            crc = crcTable[Int((crc ^ UInt32(byte)) & 0xFF)] ^ (crc >> 8)
        }
        return crc ^ 0xFFFFFFFF
    }

    static func archive(_ entries: [Entry]) -> Data {
        var output = Data()
        var centralDirectory = Data()
        var entryCount: UInt16 = 0

        for entry in entries {
            let nameData = Data(entry.path.utf8)
            let crc = crc32(entry.data)
            let size = UInt32(entry.data.count)
            let offset = UInt32(output.count)

            // Local file header
            output.appendLE(UInt32(0x04034B50))
            output.appendLE(UInt16(20))         // version needed
            output.appendLE(UInt16(0))          // flags
            output.appendLE(UInt16(0))          // method: STORED
            output.appendLE(UInt16(0))          // mod time
            output.appendLE(UInt16(0x21))       // mod date (1980-01-01)
            output.appendLE(crc)
            output.appendLE(size)               // compressed
            output.appendLE(size)               // uncompressed
            output.appendLE(UInt16(nameData.count))
            output.appendLE(UInt16(0))          // extra length
            output.append(nameData)
            output.append(entry.data)

            // Central directory record
            centralDirectory.appendLE(UInt32(0x02014B50))
            centralDirectory.appendLE(UInt16(20))   // made by
            centralDirectory.appendLE(UInt16(20))   // needed
            centralDirectory.appendLE(UInt16(0))
            centralDirectory.appendLE(UInt16(0))
            centralDirectory.appendLE(UInt16(0))
            centralDirectory.appendLE(UInt16(0x21))
            centralDirectory.appendLE(crc)
            centralDirectory.appendLE(size)
            centralDirectory.appendLE(size)
            centralDirectory.appendLE(UInt16(nameData.count))
            centralDirectory.appendLE(UInt16(0))    // extra
            centralDirectory.appendLE(UInt16(0))    // comment
            centralDirectory.appendLE(UInt16(0))    // disk
            centralDirectory.appendLE(UInt16(0))    // internal attrs
            centralDirectory.appendLE(UInt32(0))    // external attrs
            centralDirectory.appendLE(offset)
            centralDirectory.append(nameData)

            entryCount += 1
        }

        let centralOffset = UInt32(output.count)
        output.append(centralDirectory)

        // End of central directory
        output.appendLE(UInt32(0x06054B50))
        output.appendLE(UInt16(0))
        output.appendLE(UInt16(0))
        output.appendLE(entryCount)
        output.appendLE(entryCount)
        output.appendLE(UInt32(centralDirectory.count))
        output.appendLE(centralOffset)
        output.appendLE(UInt16(0))
        return output
    }
}

nonisolated extension Data {
    mutating func appendLE(_ value: UInt16) {
        append(UInt8(value & 0xFF))
        append(UInt8(value >> 8))
    }

    mutating func appendLE(_ value: UInt32) {
        append(UInt8(value & 0xFF))
        append(UInt8((value >> 8) & 0xFF))
        append(UInt8((value >> 16) & 0xFF))
        append(UInt8((value >> 24) & 0xFF))
    }
}
