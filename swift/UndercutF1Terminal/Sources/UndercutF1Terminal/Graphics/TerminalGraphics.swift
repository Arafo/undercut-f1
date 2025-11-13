import Foundation

public enum TerminalGraphics {
    private static let escapeOSC = "\u{001B}]"
    private static let escapeAPC = "\u{001B}_G"
    private static let escapeDCS = "\u{001B}P"
    private static let escapeST = "\u{001B}\\"

    private static let encodedFileName: String = {
        Data("drivertracker.png".utf8).base64EncodedString()
    }()

    public static func iTerm2Sequence(height: Int, width: Int, base64Image: String) -> String {
        let arguments = [
            "name=\(encodedFileName)",
            "width=\(width)",
            "height=\(height)",
            "preserveAspectRatio=0",
            "inline=1"
        ]

        return "\(escapeOSC)1337;File=\(arguments.joined(separator: ";")):\(base64Image)\(escapeST)"
    }

    public static func kittySequence(height: Int, width: Int, base64Image: String) -> [String] {
        let args = [
            "a=T",
            "q=1",
            "r=\(height)",
            "c=\(width)",
            "f=100"
        ].joined(separator: ",")

        var chunks: [String] = []
        let characters = Array(base64Image)
        let chunkSize = 4000
        var index = 0

        while index < characters.count {
            let end = min(index + chunkSize, characters.count)
            let chunk = String(characters[index..<end])
            let remaining = characters.count - end

            if index == 0 {
                if remaining == 0 {
                    chunks.append("\(escapeAPC)\(args);\(chunk)\(escapeST)")
                } else {
                    chunks.append("\(escapeAPC)\(args),m=1;\(chunk)\(escapeST)")
                }
            } else if remaining == 0 {
                chunks.append("\(escapeAPC)q=1,m=0;\(chunk)\(escapeST)")
            } else {
                chunks.append("\(escapeAPC)q=1,m=1;\(chunk)\(escapeST)")
            }

            index += chunkSize
        }

        return chunks
    }

    public static func kittyDeleteSequence() -> String {
        let args = ["a=d", "d=A"].joined(separator: ",")
        return "\(escapeAPC)\(args);\(escapeST)"
    }

    public static func sixelSequence(_ data: String) -> String {
        "\(escapeDCS)9;1q\(data)\(escapeST)"
    }
}
