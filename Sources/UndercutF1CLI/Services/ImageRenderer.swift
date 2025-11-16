import Foundation

enum ImageRenderError: LocalizedError {
    case missingFile
    case unsupportedProtocol

    var errorDescription: String? {
        switch self {
        case .missingFile:
            return "The requested image file could not be found."
        case .unsupportedProtocol:
            return "This graphics protocol is not yet supported in the Swift CLI."
        }
    }
}

struct ImageRenderer {
    private let environment: [String: String]

    init(environment: [String: String] = ProcessInfo.processInfo.environment) {
        self.environment = environment
    }

    func render(file url: URL, using graphicsProtocol: GraphicsProtocol) throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ImageRenderError.missingFile
        }
        let data = try Data(contentsOf: url)
        switch graphicsProtocol {
        case .iTerm:
            try emitITermImage(data: data, fileName: url.lastPathComponent)
        case .kitty:
            try emitKittyImage(data: data)
        case .sixel:
            throw ImageRenderError.unsupportedProtocol
        }
    }

    private func emitITermImage(data: Data, fileName: String) throws {
        let base64Data = data.base64EncodedString()
        let fileNameData = fileName.data(using: .utf8) ?? Data()
        let encodedName = fileNameData.base64EncodedString()
        let (cols, rows) = terminalSize()
        let arguments = [
            "name=\(encodedName)",
            "width=\(cols)",
            "height=\(rows)",
            "preserveAspectRatio=0",
            "inline=1"
        ]
        let sequence = "\u{1b}]1337;File=\(arguments.joined(separator: ";")):\(base64Data)\u{07}"
        write(sequence)
    }

    private func emitKittyImage(data: Data) throws {
        let base64Data = data.base64EncodedString()
        let (cols, rows) = terminalSize()
        let header = "a=T,q=1,c=\(cols),r=\(rows),f=100"
        let chunkSize = 4000
        let characters = Array(base64Data)
        var index = 0
        while index < characters.count {
            let remaining = characters.count - index
            let length = min(chunkSize, remaining)
            let chunk = String(characters[index..<(index + length)])
            let mode: String
            if index == 0 && remaining > chunkSize {
                mode = "\u{1b}_\(header),m=1;\(chunk)\u{1b}\\"
            } else if index == 0 {
                mode = "\u{1b}_\(header);\(chunk)\u{1b}\\"
            } else if remaining > chunkSize {
                mode = "\u{1b}_q=1,m=1;\(chunk)\u{1b}\\"
            } else {
                mode = "\u{1b}_q=1,m=0;\(chunk)\u{1b}\\"
            }
            write(mode)
            index += length
        }
    }

    private func terminalSize() -> (Int, Int) {
        let cols = environment["COLUMNS"].flatMap(Int.init) ?? 80
        let rows = environment["LINES"].flatMap(Int.init) ?? 24
        return (cols, rows)
    }

    private func write(_ string: String) {
        if let data = string.data(using: .utf8) {
            FileHandle.standardOutput.write(data)
        }
    }
}
