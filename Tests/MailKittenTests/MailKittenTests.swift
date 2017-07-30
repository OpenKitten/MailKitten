import XCTest
@testable import MailKitten

class MailKittenTests: XCTestCase {
    func testExample() throws {
        let client = try SMTPClient(to: "smtp.transip.email", ssl: true)
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
