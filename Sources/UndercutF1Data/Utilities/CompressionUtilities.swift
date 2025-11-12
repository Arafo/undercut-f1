import Foundation
#if canImport(Compression)
import Compression
#elseif canImport(CZlibShim)
import CZlibShim
#endif

public enum CompressionUtilities {
    public static func inflateBase64Data(_ value: String) throws -> String {
        guard let data = Data(base64Encoded: value) else {
            throw CompressionError.invalidBase64
        }
        #if canImport(Compression)
        let output = try inflateWithCompression(data: data)
        guard let string = String(data: output, encoding: .utf8) else {
            throw CompressionError.invalidUTF8
        }
        return string
        #elseif canImport(CZlibShim)
        let output = try inflateWithZlib(data: data)
        guard let string = String(data: output, encoding: .utf8) else {
            throw CompressionError.invalidUTF8
        }
        return string
        #else
        throw CompressionError.unsupportedPlatform
        #endif
    }

    #if canImport(Compression)
    private static func inflateWithCompression(data: Data) throws -> Data {
        return try data.withUnsafeBytes { (inputPointer: UnsafeRawBufferPointer) -> Data in
            guard let baseAddress = inputPointer.baseAddress else {
                throw CompressionError.invalidBuffer
            }
            let inputBuffer = UnsafePointer<UInt8>(baseAddress.assumingMemoryBound(to: UInt8.self))
            var output = Data()
            let chunkSize = 32 * 1024
            var stream = compression_stream()
            var status = compression_stream_init(&stream, COMPRESSION_STREAM_DECODE, COMPRESSION_ZLIB)
            guard status != COMPRESSION_STATUS_ERROR else {
                throw CompressionError.initializationFailed
            }
            defer { compression_stream_destroy(&stream) }

            stream.src_ptr = inputBuffer
            stream.src_size = data.count

            let destPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: chunkSize)
            defer { destPointer.deallocate() }

            repeat {
                stream.dst_ptr = destPointer
                stream.dst_size = chunkSize

                status = compression_stream_process(&stream, 0)
                switch status {
                case COMPRESSION_STATUS_OK, COMPRESSION_STATUS_END:
                    let count = chunkSize - stream.dst_size
                    output.append(destPointer, count: count)
                default:
                    throw CompressionError.decompressionFailed
                }
            } while status == COMPRESSION_STATUS_OK

            return output
        }
    }
    #endif

    #if canImport(CZlibShim)
    private static func inflateWithZlib(data: Data) throws -> Data {
        var pointer: UnsafeMutablePointer<UInt8>?
        var length: size_t = 0
        let status = data.withUnsafeBytes { rawBuffer -> Int32 in
            guard let baseAddress = rawBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return Z_STREAM_ERROR
            }
            return undercut_inflate(baseAddress, data.count, &pointer, &length)
        }

        guard status == Z_OK, let pointer else {
            if let pointer {
                free(pointer)
            }
            throw CompressionError.zlibError(status)
        }

        let buffer = Data(bytes: pointer, count: length)
        free(pointer)
        return buffer
    }
    #endif

    public enum CompressionError: Error {
        case invalidBase64
        case invalidUTF8
        case invalidBuffer
        case initializationFailed
        case decompressionFailed
        case zlibError(Int32)
        case unsupportedPlatform
    }
}
