import Foundation

public struct RootLayout: RenderNode {
    let content: RenderNode
    let footer: RenderNode

    public init(content: RenderNode, footer: RenderNode) {
        self.content = content
        self.footer = footer
    }

    public func render(into buffer: inout String) {
        content.render(into: &buffer)
        buffer.append("\r\n")
        footer.render(into: &buffer)
    }
}

public struct SimpleTextNode: RenderNode {
    public let text: String

    public init(text: String) {
        self.text = text
    }

    public func render(into buffer: inout String) {
        buffer.append(text)
    }
}

public struct ColumnsNode: RenderNode {
    public let columns: [RenderNode]
    public let separator: String

    public init(columns: [RenderNode], separator: String = "  ") {
        self.columns = columns
        self.separator = separator
    }

    public func render(into buffer: inout String) {
        for (index, column) in columns.enumerated() {
            if index > 0 { buffer.append(separator) }
            column.render(into: &buffer)
        }
    }
}

public struct PanelNode: RenderNode {
    public let title: String?
    public let body: RenderNode

    public init(title: String? = nil, body: RenderNode) {
        self.title = title
        self.body = body
    }

    public func render(into buffer: inout String) {
        if let title { buffer.append(title + "\r\n") }
        body.render(into: &buffer)
    }
}

public struct RowsNode: RenderNode {
    public let rows: [RenderNode]

    public init(rows: [RenderNode]) {
        self.rows = rows
    }

    public func render(into buffer: inout String) {
        for (index, row) in rows.enumerated() {
            if index > 0 { buffer.append("\r\n") }
            row.render(into: &buffer)
        }
    }
}

public struct TableNode: RenderNode {
    public struct Column {
        public let title: String
        public let width: Int?
        public let alignment: Alignment

        public init(title: String, width: Int? = nil, alignment: Alignment = .left) {
            self.title = title
            self.width = width
            self.alignment = alignment
        }
    }

    public enum Alignment {
        case left
        case right
    }

    private let columns: [Column]
    private var rows: [[String]] = []

    public init(columns: [Column]) {
        self.columns = columns
    }

    public mutating func addRow(_ values: [String]) {
        rows.append(values)
    }

    public func render(into buffer: inout String) {
        let widths = columns.enumerated().map { index, column -> Int in
            column.width ?? max(column.title.count, rows.map { $0[safe: index]?.count ?? 0 }.max() ?? 0)
        }

        func renderRow(_ values: [String]) {
            for (index, value) in values.enumerated() {
                let width = widths[index]
                let padded = pad(value, width: width, alignment: columns[index].alignment)
                buffer.append(padded)
                if index < values.count - 1 { buffer.append(" ") }
            }
            buffer.append("\r\n")
        }

        renderRow(columns.map { $0.title })
        for row in rows {
            renderRow(row)
        }
    }

    private func pad(_ value: String, width: Int, alignment: Alignment) -> String {
        let trimmed = value.count > width ? String(value.prefix(width)) : value
        let padding = max(0, width - trimmed.count)
        switch alignment {
        case .left:
            return trimmed + String(repeating: " ", count: padding)
        case .right:
            return String(repeating: " ", count: padding) + trimmed
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

public struct ErrorPanel: RenderNode {
    let error: Error
    let footerHeight: Int
    let screen: Screen

    public init(error: Error, footerHeight: Int, screen: Screen) {
        self.error = error
        self.footerHeight = footerHeight
        self.screen = screen
    }

    public func render(into buffer: inout String) {
        buffer.append("Failed to render screen \(screen)\r\n")
        buffer.append(String(describing: error))
        buffer.append("\r\n")
        if footerHeight > 0 {
            buffer.append(String(repeating: "\r\n", count: footerHeight))
        }
    }
}
