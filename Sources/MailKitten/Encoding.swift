import Lynx

public enum Encoding : String {
    case binary = "BINARY"
    case base64 = "BASE64"
    
    internal func write(buffer: UnsafeBufferPointer<UInt8>, to client: TCPClient) throws {
        switch self {
        case .binary:
            try client.send(buffer: buffer)
        case .base64:
            // YES, I made this slow on purpose
            // I need to replace this with a streaming base64 algorithm and will implement one when I'm either bored or people notice this code
            try client.send(data: [UInt8](Base64.encode(Array(buffer)).utf8))
        }
    }
}
