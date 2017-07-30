import Foundation

struct SMTPExtensions {}

extension SMTPExtensions {
    struct EHLO {
        let keyword: [UInt8]
        let params: [Array<UInt8>]
        
        init(_ reply: Reply) throws {
            guard reply.lines.count > 1 else {
                throw SMTPError.invalidEHLOMessage
            }
            
            let arguments = reply.lines[1].split(separator: 0x20)
            
            guard let keyword = arguments.first, !keyword.isEmpty else {
                throw SMTPError.invalidEHLOMessage
            }
            
            self.keyword = Array(keyword)
            self.params = arguments.dropFirst().map(Array.init)
        }
    }
}

extension Reply {
    struct Greeting {
        let domain: String
        let message: String
        
        init?(_ reply: Reply) throws {
            guard reply.lines.count > 1 else {
                throw SMTPError.noGreeting
            }
            
            let lines = reply.lines[1].split(separator: 0x20)
            
            guard lines.count == 2,
                let domain = String(bytes: lines[0], encoding: .utf8),
                let message = String(bytes: lines[1], encoding: .utf8) else {
                    throw SMTPError.noGreeting
            }
            
            self.domain = domain
            self.message = message
        }
    }
}
