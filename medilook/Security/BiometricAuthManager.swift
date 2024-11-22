import LocalAuthentication
import SwiftUI

class BiometricAuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var showPasswordOption = false
    private let context = LAContext()
    private var error: NSError?
    
    var biometricType: String {
        context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        switch context.biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        default:
            return "Biometric auth"
        }
    }
    
    var isBiometricAvailable: Bool {
        context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    func authenticate() async {
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate to access MediLook"
            
            do {
                let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
                await MainActor.run {
                    self.isAuthenticated = success
                }
            } catch {
                print(error.localizedDescription)
                await MainActor.run {
                    self.showPasswordOption = true
                }
            }
        } else {
            await MainActor.run {
                self.showPasswordOption = true
            }
        }
    }
} 