import Foundation

public protocol Clipboard: Sendable {
    func getString() -> String?
    func setString(_ value: String)
}

#if canImport(AppKit)
import AppKit

public final class SystemClipboard: Clipboard {
    private let pasteboard: NSPasteboard

    public init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    public func getString() -> String? {
        pasteboard.string(forType: .string)
    }

    public func setString(_ value: String) {
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)
    }
}

#elseif canImport(UIKit)
import UIKit

public final class SystemClipboard: Clipboard {
    private let pasteboard: UIPasteboard

    public init(pasteboard: UIPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    public func getString() -> String? {
        pasteboard.string
    }

    public func setString(_ value: String) {
        pasteboard.string = value
    }
}

#else

public final class SystemClipboard: Clipboard {
    private var storage: String?

    public init() {}

    public func getString() -> String? {
        storage
    }

    public func setString(_ value: String) {
        storage = value
    }
}

#endif
