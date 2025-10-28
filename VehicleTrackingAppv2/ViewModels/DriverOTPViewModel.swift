import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
class DriverOTPViewModel: ObservableObject {
    @Published var phoneNumber: String = ""
    @Published var smsCode: String = ""
    @Published var verificationId: String?
    @Published var isCodeSent: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var infoMessage: String = ""
    
    private let db = Firestore.firestore()
    
    func sendCode() {
        errorMessage = ""
        infoMessage = ""
        let phone = normalizePhone(phoneNumber)
        guard let phone = phone else {
            errorMessage = "Telefon numarası gerekli"
            return
        }
        isLoading = true
        PhoneAuthProvider.provider().verifyPhoneNumber(phone, uiDelegate: nil) { [weak self] verificationID, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                self?.verificationId = verificationID
                self?.isCodeSent = true
                self?.infoMessage = "Doğrulama kodu gönderildi"
            }
        }
    }
    
    func verifyAndSignIn(appViewModel: AppViewModel) {
        errorMessage = ""
        guard let verificationId = verificationId else {
            errorMessage = "Doğrulama ID bulunamadı"
            return
        }
        let code = smsCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else {
            errorMessage = "SMS kodu gerekli"
            return
        }
        isLoading = true
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationId, verificationCode: code)
        Auth.auth().signIn(with: credential) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                    return
                }
                guard let self = self, let user = result?.user else {
                    self?.isLoading = false
                    self?.errorMessage = "Kullanıcı bilgisi alınamadı"
                    return
                }
                // Sürücü kaydı eşleştir
                self.handlePostSignIn(user: user, appViewModel: appViewModel)
            }
        }
    }
    
    private func handlePostSignIn(user: User, appViewModel: AppViewModel) {
        let phone = normalizePhone(phoneNumber) ?? phoneNumber
        // Sürücüyü telefonla bul (aktif)
        db.collection("drivers")
            .whereField("phoneNumber", isEqualTo: phone)
            .whereField("isActive", isEqualTo: true)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.isLoading = false
                        self?.errorMessage = error.localizedDescription
                        self?.signOutIfNeeded()
                        return
                    }
                    guard let document = snapshot?.documents.first,
                          let driver = try? document.data(as: Driver.self) else {
                        self?.isLoading = false
                        self?.errorMessage = "Telefon numarasına kayıtlı aktif sürücü bulunamadı"
                        self?.signOutIfNeeded()
                        return
                    }
                    // Profil var mı kontrol et, yoksa oluştur
                    self?.ensureDriverProfile(user: user, driver: driver, appViewModel: appViewModel)
                }
            }
    }
    
    private func normalizePhone(_ input: String) -> String? {
        let trimmed = input.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
        if trimmed.hasPrefix("+90") {
            let digits = trimmed.dropFirst(3)
            return digits.count == 10 ? trimmed : nil
        }
        if trimmed.hasPrefix("0") {
            let rest = trimmed.dropFirst(1)
            return rest.count == 10 ? "+90" + rest : nil
        }
        if trimmed.count == 10, let _ = Int(trimmed) { return "+90" + trimmed }
        return nil
    }
    
    private func ensureDriverProfile(user: User, driver: Driver, appViewModel: AppViewModel) {
        db.collection("userProfiles").document(user.uid).getDocument { [weak self] doc, _ in
            DispatchQueue.main.async {
                if let doc = doc, doc.exists {
                    // Profil var, AppViewModel zaten state'i güncelleyecek
                    self?.isLoading = false
                    self?.infoMessage = "Giriş başarılı"
                    return
                }
                // Yeni profil oluştur
                var profile = UserProfile(
                    userId: user.uid,
                    userType: .driver,
                    email: user.email ?? "",
                    fullName: driver.fullName,
                    phone: self?.phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines),
                    companyId: driver.companyId,
                    driverLicenseNumber: nil
                )
                profile.id = profile.userId
                do {
                    try self?.db.collection("userProfiles").document(profile.userId).setData(from: profile) { error in
                        DispatchQueue.main.async {
                            self?.isLoading = false
                            if let error = error {
                                self?.errorMessage = error.localizedDescription
                                self?.signOutIfNeeded()
                            } else {
                                self?.infoMessage = "Profil oluşturuldu"
                                // AppViewModel auth listener'ı profili ve şirketi yükleyecek
                            }
                        }
                    }
                } catch {
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                    self?.signOutIfNeeded()
                }
            }
        }
    }
    
    private func signOutIfNeeded() {
        do { try Auth.auth().signOut() } catch { }
    }
}


