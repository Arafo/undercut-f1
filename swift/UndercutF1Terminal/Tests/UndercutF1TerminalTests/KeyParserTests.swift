import XCTest
@testable import UndercutF1Terminal

final class KeyParserTests: XCTestCase {
    private let parser = KeyParser()

    func testParsesEscapeKeyVariants() {
        let single = parser.parse(bytes: [27])
        XCTAssertEqual(single.key, .escape)

        let padded = parser.parse(bytes: [27, 0, 0])
        XCTAssertEqual(padded.key, .escape)
    }

    func testParsesArrowSequences() {
        let basicUp = parser.parse(bytes: [27, 91, 65])
        XCTAssertEqual(basicUp.key, .up)
        XCTAssertTrue(basicUp.modifiers.isEmpty)

        let shiftRight = parser.parse(bytes: [27, 91, 49, 59, 50, 67])
        XCTAssertEqual(shiftRight.key, .right)
        XCTAssertTrue(shiftRight.modifiers.contains(.shift))
        XCTAssertFalse(shiftRight.modifiers.contains(.control))

        let controlLeft = parser.parse(bytes: [27, 91, 49, 59, 53, 68])
        XCTAssertEqual(controlLeft.key, .left)
        XCTAssertTrue(controlLeft.modifiers.contains(.control))
    }

    func testParsesFeArrowSequence() {
        let down = parser.parse(bytes: [27, 79, 66])
        XCTAssertEqual(down.key, .down)
    }

    func testParsesControlSequencesForPunctuation() {
        // ESC [ 27 ; 5 ; 44 ~
        let ctrlComma = parser.parse(bytes: [27, 91, 50, 55, 59, 53, 59, 52, 52, 126])
        XCTAssertEqual(ctrlComma.character, ",")
        XCTAssertEqual(ctrlComma.key, .character(","))
        XCTAssertTrue(ctrlComma.modifiers.contains(.control))

        // ESC [ 27 ; 5 ; 46 ~
        let ctrlPeriod = parser.parse(bytes: [27, 91, 50, 55, 59, 53, 59, 52, 54, 126])
        XCTAssertEqual(ctrlPeriod.character, ".")
        XCTAssertTrue(ctrlPeriod.modifiers.contains(.control))
    }

    func testParsesControlCharacters() {
        let ctrlC = parser.parse(bytes: [3])
        XCTAssertEqual(ctrlC.key, .controlC)
        XCTAssertTrue(ctrlC.modifiers.contains(.control))

        let ctrlA = parser.parse(bytes: [1])
        XCTAssertEqual(ctrlA.character, "a")
        XCTAssertTrue(ctrlA.modifiers.contains(.control))
    }

    func testParsesBackspaceAndEnter() {
        XCTAssertEqual(parser.parse(bytes: [8]).key, .backspace)
        XCTAssertEqual(parser.parse(bytes: [127]).key, .backspace)
        XCTAssertEqual(parser.parse(bytes: [10]).key, .enter)
        XCTAssertEqual(parser.parse(bytes: [13]).key, .enter)
    }

    func testParsesPrintableCharactersWithShiftDetection() {
        let lowercase = parser.parse(bytes: [110])
        XCTAssertEqual(lowercase.character, "n")
        XCTAssertFalse(lowercase.modifiers.contains(.shift))
        XCTAssertEqual(lowercase.repeatCount, 1)

        let uppercase = parser.parse(bytes: [78])
        XCTAssertEqual(uppercase.character, "N")
        XCTAssertTrue(uppercase.modifiers.contains(.shift))

        let repeats = parser.parse(bytes: [110, 110, 110])
        XCTAssertEqual(repeats.repeatCount, 3)
    }

    func testReturnsUnknownForUnhandledSequences() {
        let unknown = parser.parse(bytes: [0])
        XCTAssertEqual(unknown.key, .unknown(0))
    }
}
