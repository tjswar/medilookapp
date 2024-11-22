import SwiftUI
import LocalAuthentication

enum AutoLockDuration: TimeInterval, CaseIterable, Identifiable {
    case fifteenSeconds = 15
    case thirtySeconds = 30
    case oneMinute = 60
    case fiveMinutes = 300
    
    var id: TimeInterval { self.rawValue }
    
    var displayName: String {
        switch self {
        case .fifteenSeconds: return "15 seconds"
        case .thirtySeconds: return "30 seconds"
        case .oneMinute: return "1 minute"
        case .fiveMinutes: return "5 minutes"
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: MedicineViewModel
    @StateObject private var appLockManager = AppLockManager()
    @State private var showClearHistoryAlert = false
    @State private var showBiometricAlert = false
    @State private var biometricError: String?
    
    private let context = LAContext()
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // App Lock Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Security")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Toggle(isOn: $appLockManager.isLockEnabled) {
                                HStack {
                                    Image(systemName: "lock.shield")
                                        .foregroundColor(.blue)
                                    VStack(alignment: .leading) {
                                        Text("App Lock")
                                        Text(appLockManager.biometricType)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .onChange(of: appLockManager.isLockEnabled) { _, newValue in
                                if newValue {
                                    authenticateForLockEnable()
                                }
                            }
                            
                            if appLockManager.isLockEnabled {
                                Text("App will require authentication to access")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if appLockManager.isLockEnabled {
                                Picker("Auto-Lock After", selection: Binding(
                                    get: {
                                        AutoLockDuration.allCases.first { $0.rawValue == appLockManager.autoLockDuration } ?? .thirtySeconds
                                    },
                                    set: { newValue in
                                        appLockManager.autoLockDuration = newValue.rawValue
                                    }
                                )) {
                                    ForEach(AutoLockDuration.allCases) { duration in
                                        Text(duration.displayName).tag(duration)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(15)
                        
                        // Privacy Information Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Privacy Information")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Text("Your search history is stored only on your device and is never shared with anyone. We respect your privacy and do not collect any personal information.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(15)
                        
                        // Clear History Section
                        VStack(alignment: .leading, spacing: 15) {
                            Button(action: {
                                showClearHistoryAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                    Text("Clear Search History")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(15)
                        
                        // App Info Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("App Information")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            InfoRow(title: "Version", value: "1.0.0")
                            InfoRow(title: "Build", value: "1")
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(15)
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Clear Search History", isPresented: $showClearHistoryAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    viewModel.clearSearchHistory()
                }
            } message: {
                Text("Are you sure you want to clear your search history? This action cannot be undone.")
            }
            .alert("Biometric Authentication", isPresented: $showBiometricAlert) {
                Button("OK", role: .cancel) {
                    if let error = biometricError {
                        appLockManager.isLockEnabled = false
                    }
                }
            } message: {
                Text(biometricError ?? "Authentication successful")
            }
        }
    }
    
    private func authenticateForLockEnable() {
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthentication,
                                 localizedReason: "Enable app lock with biometric authentication") { success, authError in
                DispatchQueue.main.async {
                    if success {
                        // Keep the lock enabled
                    } else {
                        biometricError = authError?.localizedDescription ?? "Authentication failed"
                        showBiometricAlert = true
                        appLockManager.isLockEnabled = false
                    }
                }
            }
        } else {
            biometricError = error?.localizedDescription ?? "Biometric authentication not available"
            showBiometricAlert = true
            appLockManager.isLockEnabled = false
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
        }
    }
}

#Preview {
    SettingsView(viewModel: MedicineViewModel())
} 