  import SwiftUI
import LocalAuthentication

struct SplashView: View {
    @State private var isActive = false
    @State private var animateLogo = false
    @State private var showAuthError = false
    @State private var authAttempts = 0
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var appLockManager = AppLockManager()
    
    private var shouldShowContent: Bool {
        isActive && (!appLockManager.isLocked || !appLockManager.isLockEnabled)
    }
    
    var body: some View {
        Group {
            if shouldShowContent {
                ContentView()
            } else {
                splashContent
            }
        }
        .onAppear {
            // Start logo animation immediately
            withAnimation(.easeInOut(duration: 1.2)) {
                self.animateLogo = true
            }
            
            // Check authentication after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if appLockManager.isLockEnabled {
                    authenticate()
                } else {
                    activateAfterDelay()
                }
            }
        }
    }
    
    private var splashContent: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            VStack {
                Text("MediLook")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .opacity(animateLogo ? 1 : 0)
                    .scaleEffect(animateLogo ? 1 : 0.5)
            }
        }
        .alert("Authentication Failed", isPresented: $showAuthError) {
            Button("Try Again") {
                authenticate()
            }
            if authAttempts >= 3 {
                Button("Exit", role: .destructive) {
                    exit(0)
                }
            }
        } message: {
            if authAttempts >= 3 {
                Text("Multiple authentication attempts failed. Please try again or exit the app.")
            } else {
                Text("Please authenticate to access the app")
            }
        }
    }
    
    private func activateAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                self.isActive = true
            }
        }
    }
    
    private func authenticate() {
        Task {
            let success = await appLockManager.authenticateUser()
            await MainActor.run {
                if success {
                    activateAfterDelay()
                } else {
                    authAttempts += 1
                    showAuthError = true
                }
            }
        }
    }
}

#Preview {
    SplashView()
} 
