import Foundation
import KeychainSwift

class PasswordManager: ObservableObject {
    private let keychain = KeychainSwift()
    private let passwordKey = "medilook_password"
    
    @Published var isPasswordSet: Bool
    
    init() {
        isPasswordSet = keychain.get(passwordKey) != nil
    }
    
    func setPassword(_ password: String) -> Bool {
        let success = keychain.set(password, forKey: passwordKey)
        isPasswordSet = success
        return success
    }
    
    func validatePassword(_ password: String) -> Bool {
        guard let storedPassword = keychain.get(passwordKey) else {
            return false
        }
        return password == storedPassword
    }
    
    func removePassword() -> Bool {
        let success = keychain.delete(passwordKey)
        isPasswordSet = !success
        return success
    }
} 