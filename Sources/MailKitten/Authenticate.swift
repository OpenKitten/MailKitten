import CryptoKitten

extension SMTPClient {
    public func authenticate(_ user: String, withPassword password: String) throws {
        let mechanisms = self.greeting.auth
        
        if mechanisms.contains("PLAIN") {
            guard !user.characters.contains("\0"), !password.characters.contains("\0") else {
                throw SMTPError.invalidCredentials
            }
            
            let authString = Base64.encode([UInt8]("\0\(user)\0\(password)".utf8))
            
            let replies = try send("AUTH PLAIN " + authString).await(for: .seconds(30))
            
            guard replies.replies.count == 1, replies.replies.first?.code == 235 else {
                throw SMTPError.invalidCredentials
            }
            
            return
        }
        
        throw SMTPError.unsupportedMechanisms(mechanisms)
    }
}
