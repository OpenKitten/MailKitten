import Foundation

struct Greeting {
    let extensions: [Array<UInt8>]
    
    var auth: [String] {
        for var ehloExtension in extensions where ehloExtension.starts(with: [UInt8]("AUTH".utf8)) {
            guard ehloExtension.count > 5 else {
                return []
            }
            
            ehloExtension.removeFirst(5)
            
            // split by " "
            return ehloExtension.split(separator: 0x20).flatMap { buffer in
                String(bytes: buffer, encoding: .utf8)
            }
        }
        
        return []
    }
    
    init(_ replies: Replies) {
        self.extensions = replies.replies.flatMap { reply in
            guard reply.line.count > 1 else {
                return nil
            }
            
            return Array(reply.line.dropFirst())
        }
    }
}
