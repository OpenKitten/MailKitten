import Foundation
import Schrodinger
import Lynx

public struct Email {
    public enum ContentType : String {
        case plain = "text/plain"
        case html = "text/html"
    }
    
    internal let id: String = "<\(NSUUID().uuidString)@localhost>"
    
    public var subject: String
    public var type: ContentType
    public var contents: BodyRepresentable
    public var recipients: [String]
    public var attachments = [File]()
    public var extendedFields = [String: String]()
    
    public let creation = Date()
    
    public init(subject: String, type: ContentType, contents: BodyRepresentable, recipients: [String]) {
        self.subject = subject
        self.type = type
        self.contents = contents
        self.recipients = recipients
    }
}

fileprivate let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en-US")
    formatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss ZZZ"
    return formatter
}()

extension SMTPClient {
    public func send(_ email: Email, from sender: String) throws -> Future<Void> {
        var future = try send("MAIL FROM:<\(sender)>")
        
        for recipient in email.recipients {
            future = try future.replace { result in
                try result.assertSingleReply().assert(code: 250)

                return try self.send("RCPT TO: <\(recipient)>")
            }
        }
        
        return try future.replace { result -> Future<Replies> in
            try result.assertSingleReply().assert(code: 250)
            
            return try self.send("DATA")
        }.replace { result -> Future<Replies> in
            try result.assertSingleReply().assert(code: 354)
            
            var headers: [String: String] = [
                "Date": formatter.string(from: email.creation),
                "Message-Id": email.id,
                "From": "<\(sender)>",
                "To": email.recipients.map { "<" + $0 + ">" }.joined(separator: ", "),
                "Subject": email.subject,
                "MIME-Version": "1.0"
            ]
            
            for (key, value) in email.extendedFields {
                headers[key] = value
            }
            
            let boundary = "sdsadajdfnqewrnwdajsifnqweriw"
            
            headers["Content-type"] = "multipart/mixed; boundary=\"\(boundary)\""
            
            let emailString = headers.reduce("") { lhs, rhs in
                return lhs + rhs.key + ": " + rhs.value + "\r\n"
            }
            
            let size = 65_507
            let pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
            pointer.initialize(to: 0, count: size)
            
            let fullBoundary = [0x2d, 0x2d] + [UInt8](boundary.utf8)
            var offset = 0
            
            func write(_ data: [UInt8]) throws {
                memcpy(pointer.advanced(by: offset), data, data.count)
                offset += data.count
                try self.client.send(data: data)
            }
            
            func writeString(_ string: String) throws {
                try write([UInt8](string.utf8))
            }
            
            func writeBoundary() throws {
                try write(fullBoundary + [0x0d, 0x0a])
            }
            
            try writeString(emailString)
            
            try writeBoundary()
            try writeString("Content-Type: \(email.type.rawValue); charset=\"utf-8\"\r\n")
            try writeString("Content-Transfer-Encoding: \(Encoding.binary.rawValue)\r\n\r\n")
            
            try email.contents.write { buffer in
                try Encoding.binary.write(buffer: buffer, to: self.client!)
            }
            
            try write([0x0d, 0x0a])
            
            for attachment in email.attachments {
                try writeBoundary()
                try writeString("Content-Disposition: attachment; filename=\(attachment.name)\r\n")
                try writeString("Content-Type: \(attachment.mimeType); name=\(attachment.name)\r\n")
                try writeString("Content-Transfer-Encoding: \(Encoding.base64.rawValue)\r\n\r\n")
                
                try attachment.write { buffer in
                    try Encoding.base64.write(buffer: buffer, to: self.client!)
                }
                
                try write([0x0d, 0x0a])
            }
            
            return try self.send("--\(boundary)--\r\n\r\n\r\n.\r\n")
        }.map { result in
            try result.assertSingleReply().assert(code: 250)
            
            return
        }
    }
}
