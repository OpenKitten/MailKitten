import Schrodinger
import Lynx

public final class SMTPClient {
    var client: TCPClient!
    var replyFuture = Future<Reply>()
    
    public init(to hostname: String, at port: UInt16? = nil, currentHost: String = "localhost", ssl: Bool = false) throws {
        func onRead(pointer: UnsafePointer<UInt8>, count: Int) {
            print(String(bytes: UnsafeBufferPointer(start: pointer, count: count), encoding: .utf8)!)
            
            _ = try? replyFuture.complete {
                return try Reply(from: pointer, count: count)
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
        
        guard try replyFuture.await(for: .seconds(30)).code == 220 else {
            throw SMTPError.noGreeting
        }
        
        let hostnameBytes = [UInt8](currentHost.utf8)
        
        var reply = try self.send([UInt8]("EHLO ".utf8) + hostnameBytes).await(for: .seconds(30))
        
        if reply.code == 500 {
            reply = try self.send([UInt8]("HELO ".utf8) + hostnameBytes).await(for: .seconds(30))
        }
        
        guard reply.code == 250 else {
            self.close()
            throw SMTPError.noGreeting
        }
        
        let greeting = try Reply.Greeting(reply)
        
        print(greeting)
    }
    
    public func close() {
        self.client.close()
    }
    
    deinit {
        close()
    }
}

// MARK - transport

extension SMTPClient {
    func send(_ command: [UInt8]) throws -> Future<Reply> {
        try self.client.send(data: command + [0x20, 0x0d, 0x0a])
        
        let future = Future<Reply>()
        
        self.replyFuture = future
        
        return future
    }
}

enum SMTPError : Error {
    case invalidReply, multipleSimultaniousCommands, noGreeting, invalidEHLOMessage
}

struct Reply {
    let code: Int
    let lines: [Array<UInt8>]
    
    init(from pointer: UnsafePointer<UInt8>, count: Int) throws {
        guard count > 5,
            let string = String(bytes: UnsafeBufferPointer(start: pointer, count: 3), encoding: .utf8),
            let code = Int(string) else {
            throw SMTPError.invalidReply
        }
        
        self.code = code
        
        var pointer = pointer.advanced(by: 4)
        let count = count &- 4
        var position = 0
        var lines = [Array<UInt8>]()
        
        while position < count {
            defer { position = position &+ 1 }
            
            if pointer[position] == 0x0d && pointer[position &+ 1] == 0x0a {
                defer { position = position &+ 1}
                
                lines.append(Array(UnsafeBufferPointer(start: pointer, count: position)))
                pointer = pointer.advanced(by: position &+ 2)
            }
        }
        
        self.lines = lines
    }
}
