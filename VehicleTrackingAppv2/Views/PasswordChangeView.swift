import SwiftUI
import FirebaseAuth

struct PasswordChangeView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    @State private var showingSuccessAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Mevcut Şifre")) {
                    SecureField("Mevcut Şifre", text: $currentPassword)
                        .textFieldStyle(ShuttleTrackTextFieldStyle())
                }
                
                Section(header: Text("Yeni Şifre")) {
                    SecureField("Yeni Şifre", text: $newPassword)
                        .textFieldStyle(ShuttleTrackTextFieldStyle())
                    
                    SecureField("Şifre Tekrar", text: $confirmPassword)
                        .textFieldStyle(ShuttleTrackTextFieldStyle())
                }
                
                Section(footer: Text("Şifre en az 6 karakter olmalıdır")) {
                    EmptyView()
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                if !successMessage.isEmpty {
                    Section {
                        Text(successMessage)
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Şifre Değiştir")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("İptal") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Kaydet") {
                    changePassword()
                }
                .disabled(isLoading || !isPasswordValid)
            )
            .alert("Şifre Değiştirildi", isPresented: $showingSuccessAlert) {
                Button("Tamam") {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Şifreniz başarıyla değiştirildi.")
            }
        }
    }
    
    private var isPasswordValid: Bool {
        return !currentPassword.isEmpty &&
               !newPassword.isEmpty &&
               newPassword == confirmPassword &&
               newPassword.count >= 6
    }
    
    private func changePassword() {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "Kullanıcı oturumu bulunamadı"
            return
        }
        
        isLoading = true
        errorMessage = ""
        successMessage = ""
        
        // Re-authenticate user with current password
        let credential = EmailAuthProvider.credential(withEmail: user.email ?? "", password: currentPassword)
        
        user.reauthenticate(with: credential) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.isLoading = false
                    self?.errorMessage = "Mevcut şifre yanlış: \(error.localizedDescription)"
                    return
                }
                
                // Update password
                user.updatePassword(to: self?.newPassword ?? "") { error in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        
                        if let error = error {
                            self?.errorMessage = "Şifre değiştirilemedi: \(error.localizedDescription)"
                        } else {
                            self?.successMessage = "Şifre başarıyla değiştirildi"
                            self?.showingSuccessAlert = true
                        }
                    }
                }
            }
        }
    }
}

struct PasswordChangeView_Previews: PreviewProvider {
    static var previews: some View {
        PasswordChangeView()
    }
}
