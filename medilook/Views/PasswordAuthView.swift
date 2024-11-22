import SwiftUI

struct PasswordAuthView: View {
    @ObservedObject var passwordManager: PasswordManager
    @Binding var isAuthenticated: Bool
    @State private var password = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showingSetPassword = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            if passwordManager.isPasswordSet {
                // Login with password
                SecureField("Enter Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button("Login") {
                    if passwordManager.validatePassword(password) {
                        isAuthenticated = true
                    } else {
                        showError = true
                        errorMessage = "Invalid password"
                    }
                }
                .buttonStyle(.borderedProminent)
            } else {
                // Set new password
                VStack(spacing: 15) {
                    SecureField("New Password", text: $newPassword)
                    SecureField("Confirm Password", text: $confirmPassword)
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                
                Button("Set Password") {
                    if newPassword.count < 6 {
                        showError = true
                        errorMessage = "Password must be at least 6 characters"
                    } else if newPassword != confirmPassword {
                        showError = true
                        errorMessage = "Passwords don't match"
                    } else {
                        if passwordManager.setPassword(newPassword) {
                            isAuthenticated = true
                        } else {
                            showError = true
                            errorMessage = "Failed to set password"
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
} 