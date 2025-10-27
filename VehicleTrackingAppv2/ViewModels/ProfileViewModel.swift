import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine
import FirebaseFirestoreSwift

class ProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var successMessage = ""
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadUserProfile()
    }
    
    func loadUserProfile() {
        guard let user = Auth.auth().currentUser else { 
            errorMessage = "Kullanıcı oturumu bulunamadı"
            return 
        }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let document = try await db.collection("userProfiles").document(user.uid).getDocument()
                
                if document.exists {
                    do {
                        let profile = try document.data(as: UserProfile.self)
                        await MainActor.run {
                            self.userProfile = profile
                            self.isLoading = false
                        }
                    } catch {
                        // Eğer veri formatı uyumsuzsa, varsayılan profil oluştur
                        print("Profil verisi uyumsuz, yeni profil oluşturuluyor: \(error)")
                        await MainActor.run {
                            self.isLoading = false
                            self.createUserProfile()
                        }
                    }
                } else {
                    // Profil bulunamadı, yeni profil oluştur
                    print("Profil bulunamadı, yeni profil oluşturuluyor")
                    await MainActor.run {
                        self.isLoading = false
                        self.createUserProfile()
                    }
                }
            } catch {
                await MainActor.run {
                    if error.localizedDescription.contains("permissions") {
                        self.errorMessage = "Firebase güvenlik kuralları nedeniyle profil yüklenemedi. Lütfen Firebase Console'da güvenlik kurallarını kontrol edin."
                    } else {
                        self.errorMessage = "Profil yüklenirken hata oluştu: \(error.localizedDescription)"
                    }
                    self.isLoading = false
                }
            }
        }
    }
    
    func updateProfile(fullName: String, phone: String?, userType: UserType) {
        guard var profile = userProfile else {
            errorMessage = "Profil bulunamadı"
            return
        }
        
        isLoading = true
        errorMessage = ""
        successMessage = ""
        
        profile.fullName = fullName
        profile.phone = phone
        profile.userType = userType
        profile.updatedAt = Date()
        
        Task {
            do {
                guard let userId = profile.id else { return }
                var updatedProfile = profile
                updatedProfile.updatedAt = Date()
                try db.collection("userProfiles").document(userId).setData(from: updatedProfile, merge: true)
                DispatchQueue.main.async {
                    self.userProfile = profile
                    self.isLoading = false
                    self.successMessage = "Profil başarıyla güncellendi"
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Profil güncellenirken hata oluştu: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func updateEmail(newEmail: String) {
        guard let user = Auth.auth().currentUser else { return }
        
        isLoading = true
        errorMessage = ""
        successMessage = ""
        
        Task {
            do {
                try await user.sendEmailVerification(beforeUpdatingEmail: newEmail)
                
                // Update profile in Firestore
                if var profile = userProfile {
                    profile.email = newEmail
                    profile.updatedAt = Date()
                    guard let userId = profile.id else { return }
                    try db.collection("userProfiles").document(userId).setData(from: profile, merge: true)
                    
                    DispatchQueue.main.async {
                        self.userProfile = profile
                        self.isLoading = false
                        self.successMessage = "E-posta adresi başarıyla güncellendi"
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "E-posta güncellenirken hata oluştu: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func updatePassword(currentPassword: String, newPassword: String) {
        guard let user = Auth.auth().currentUser else { return }
        
        isLoading = true
        errorMessage = ""
        successMessage = ""
        
        Task {
            do {
                // Re-authenticate user before changing password
                let credential = EmailAuthProvider.credential(withEmail: user.email ?? "", password: currentPassword)
                try await user.reauthenticate(with: credential)
                
                // Update password
                try await user.updatePassword(to: newPassword)
                
                await MainActor.run {
                    self.isLoading = false
                    self.successMessage = "Şifre başarıyla güncellendi"
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Şifre güncellenirken hata oluştu: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func createUserProfile() {
        guard let user = Auth.auth().currentUser else { 
            errorMessage = "Kullanıcı oturumu bulunamadı"
            return 
        }
        
        isLoading = true
        errorMessage = ""
        
        var newProfile = UserProfile(
            userId: user.uid,
            userType: .companyAdmin,
            email: user.email ?? "",
            fullName: user.displayName ?? "",
            phone: nil,
            companyId: getCurrentCompanyId(),
            driverLicenseNumber: nil
        )
        newProfile.id = newProfile.userId
        
        Task {
            do {
                try db.collection("userProfiles").document(newProfile.userId).setData(from: newProfile)
                DispatchQueue.main.async {
                    self.userProfile = newProfile
                    self.isLoading = false
                    self.successMessage = "Profil başarıyla oluşturuldu"
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Profil oluşturulurken hata oluştu: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func getCurrentCompanyId() -> String? {
        // This should be integrated with AppViewModel to get current company
        return Auth.auth().currentUser?.uid
    }
    
    func clearMessages() {
        errorMessage = ""
        successMessage = ""
    }
}
