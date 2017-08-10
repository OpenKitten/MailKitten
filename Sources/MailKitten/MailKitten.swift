import Foundation
import Schrodinger
import Lynx

public final class SMTPClient {
    var client: TCPClient!
    var greeting: Greeting!
    var replyFuture = Future<Replies>()
    
    public init(to hostname: String, at port: UInt16? = nil, currentHost: String = "localhost", ssl: Bool = false) throws {
        func onRead(pointer: UnsafePointer<UInt8>, count: Int) {
            _ = try? replyFuture.complete {
                return try Replies(from: pointer, count: count)
            }
        }
        
        if ssl {
            let client = try TCPSSLClient(hostname: hostname, port: port ?? 465, onRead: onRead)
            
            try client.connect()
            
            self.client = client
        } else {
            let client = try TCPClient(hostname: hostname, port: port ?? 25, onRead: onRead)
            
            try client.connect()
            
            self.client = client
        }
        
        guard try replyFuture.await(for: .seconds(30)).replies.first?.code == 220 else {
            throw SMTPError.noGreeting
        }
        
        let hostnameBytes = [UInt8](currentHost.utf8)
        
        var replies = try self.send([UInt8]("EHLO ".utf8) + hostnameBytes).await(for: .seconds(30))
        
        if replies.replies.first?.code == 500 {
            replies = try self.send([UInt8]("HELO ".utf8) + hostnameBytes).await(for: .seconds(30))
        }
        
        guard replies.replies.count > 0, replies.replies.removeFirst().code == 250 else {
            self.close()
            throw SMTPError.noGreeting
        }
        
        self.greeting = Greeting(replies)
    }
    
    public func close() {
        _ = try? self.send([UInt8]("QUIT".utf8))
        self.client.close()
    }
    
    deinit {
        close()
    }
}
