import SwiftUI
import LocalAuthentication

class AppLockManager: ObservableObject {
    @Published var isLockEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isLockEnabled, forKey: "isAppLockEnabled")
        }
    }
    
    @Published var autoLockDuration: TimeInterval {
        didSet {
            UserDefaults.standard.set(autoLockDuration, forKey: "autoLockDuration")
        }
    }
    
    @Published var isLocked: Bool = false
    private var backgroundDate: Date?
    private let context = LAContext()
    
    init() {
        // Check if we're in preview mode
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        
        self.isLockEnabled = isPreview ? false : UserDefaults.standard.bool(forKey: "isAppLockEnabled")
        self.autoLockDuration = UserDefaults.standard.double(forKey: "autoLockDuration")
        
        // Set default auto-lock duration to 30 seconds if not set
        if self.autoLockDuration == 0 {
            self.autoLockDuration = 30
        }
        
        // Don't start locked on first launch or in preview
        if isPreview || !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            self.isLocked = false
        } else {
            self.isLocked = self.isLockEnabled
        }
        
        // Setup notification observers only if not in preview
        if !isPreview {
            setupNotificationObservers()
        }
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.backgroundDate = Date()
            if self?.isLockEnabled == true {
                self?.isLocked = true
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            if self.isLockEnabled {
                if let backgroundDate = self.backgroundDate {
                    let timeAway = Date().timeIntervalSince(backgroundDate)
                    if timeAway >= self.autoLockDuration {
                        self.isLocked = true
                    }
                }
            }
        }
    }
    
    func authenticateUser() async -> Bool {
        // Skip authentication in preview mode
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return true
        }
        
        guard isLockEnabled else { return true }
        
        let context = LAContext()
        var error: NSError?
        
        do {
            // First try biometric authentication
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                do {
                    let success = try await context.evaluatePolicy(
                        .deviceOwnerAuthenticationWithBiometrics,
                        localizedReason: "Unlock MediLook with \(biometricType)"
                    )
                    if success {
                        await MainActor.run {
                            self.isLocked = false
                        }
                        return true
                    }
                } catch {
                    print("Biometric authentication failed: \(error.localizedDescription)")
                }
            }
            
            // If biometric fails or isn't available, try passcode
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Unlock MediLook"
            )
            await MainActor.run {
                if success {
                    self.isLocked = false
                }
            }
            return success
        } catch {
            print("Authentication error: \(error.localizedDescription)")
            return false
        }
    }
    
    var biometricType: String {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return "Passcode"
        }
        
        switch context.biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        default:
            return "Passcode"
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
} 