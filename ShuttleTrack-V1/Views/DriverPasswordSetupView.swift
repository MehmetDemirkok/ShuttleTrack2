import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

struct DriverPasswordSetupView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Hoş Geldiniz!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    Text("İlk girişiniz için yeni bir şifre belirleyin")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 32)
                
                FormCard {
                    VStack(spacing: 0) {
                        FormSectionHeader(title: "Şifre Belirleme", icon: "lock.fill", iconColor: ShuttleTrackTheme.Colors.info)
                        
                        FormInputField(
                            title: "Yeni Şifre",
                            placeholder: "En az 6 karakter",
                            icon: "key.fill",
                            iconColor: ShuttleTrackTheme.Colors.info,
                            text: $newPassword
                        )
                        
                        FormInputField(
                            title: "Şifre Tekrar",
                            placeholder: "Yeni şifreyi tekrar yazın",
                            icon: "key.horizontal.fill",
                            iconColor: ShuttleTrackTheme.Colors.info,
                            text: $confirmPassword
                        )
                    }
                }
                .padding(.top, 8)
                
                if !errorMessage.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(ShuttleTrackTheme.Colors.error)
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ShuttleTrackTheme.Colors.error)
                    }
                    .padding(.horizontal, 20)
                }
                
                Button(action: submit) {
                    HStack {
                        if isLoading { ProgressView().tint(.white) }
                        Text("Onayla ve Devam Et")
                    }
                }
                .buttonStyle(ShuttleTrackButtonStyle(variant: .primary, size: .large))
                .disabled(!isFormValid || isLoading)
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .background(ShuttleTrackTheme.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Şifre Belirleme")
        }
    }
    
    private var isFormValid: Bool {
        newPassword.count >= 6 && newPassword == confirmPassword
    }
    
    private func submit() {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "Oturum bulunamadı"
            return
        }
        guard let userId = appViewModel.currentUser?.uid else {
            errorMessage = "Kullanıcı bilgisi alınamadı"
            return
        }
        isLoading = true
        errorMessage = ""
        
        user.updatePassword(to: newPassword) { err in
            DispatchQueue.main.async {
                if let err = err {
                    self.isLoading = false
                    self.errorMessage = err.localizedDescription
                    return
                }
                let db = Firestore.firestore()
                let now = Date()
                db.collection("userProfiles").document(userId).updateData([
                    "lastLoginAt": now,
                    "updatedAt": now
                ]) { updateErr in
                    DispatchQueue.main.async {
                        self.isLoading = false
                        if let updateErr = updateErr {
                            self.errorMessage = updateErr.localizedDescription
                            return
                        }
                        // Yerel profili güncelle ve sürücü paneline geçişe izin ver
                        self.appViewModel.currentUserProfile?.lastLoginAt = now
                    }
                }
            }
        }
    }
}

struct DriverPasswordSetupView_Previews: PreviewProvider {
    static var previews: some View {
        DriverPasswordSetupView().environmentObject(AppViewModel())
    }
}


