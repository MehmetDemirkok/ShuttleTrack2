import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseFunctions
import FirebaseAuth

// Cloud Function hataları için özel error type
struct CloudFunctionError: LocalizedError {
    let message: String
    
    var errorDescription: String? {
        return message
    }
    
    var localizedDescription: String {
        return message
    }
}

struct AddEditDriverView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: DriverViewModel
    @StateObject private var appViewModel: AppViewModel
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var isActive = true
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    let driver: Driver?
    let isEditing: Bool
    
    init(driver: Driver? = nil, viewModel: DriverViewModel, appViewModel: AppViewModel) {
        self.driver = driver
        self.isEditing = driver != nil
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._appViewModel = StateObject(wrappedValue: appViewModel)
        
        if let driver = driver {
            _firstName = State(initialValue: driver.firstName)
            _lastName = State(initialValue: driver.lastName)
            _phoneNumber = State(initialValue: driver.phoneNumber)
            _email = State(initialValue: driver.email)
            _isActive = State(initialValue: driver.isActive)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Kişisel Bilgiler
                    FormCard {
                        FormSectionHeader(title: "Kişisel Bilgiler", icon: "person.fill", iconColor: ShuttleTrackTheme.Colors.personIcon)
                        
                        FormInputField(
                            title: "Ad",
                            placeholder: "Ad",
                            icon: "person.text.rectangle",
                            iconColor: ShuttleTrackTheme.Colors.personIcon,
                            text: $firstName
                        )
                        
                        FormInputField(
                            title: "Soyad",
                            placeholder: "Soyad",
                            icon: "person.text.rectangle",
                            iconColor: ShuttleTrackTheme.Colors.personIcon,
                            text: $lastName
                        )
                        
                        FormInputField(
                            title: "Telefon",
                            placeholder: "+90 5xx xxx xx xx",
                            icon: "phone.fill",
                            iconColor: ShuttleTrackTheme.Colors.phoneIcon,
                            text: $phoneNumber,
                            keyboardType: .phonePad
                        )

                        FormInputField(
                            title: "E-posta",
                            placeholder: "ornek@eposta.com",
                            icon: "envelope.fill",
                            iconColor: ShuttleTrackTheme.Colors.info,
                            text: $email,
                            keyboardType: .emailAddress
                        )
                    }
                    
                    // Durum
                    FormCard {
                        FormSectionHeader(title: "Durum", icon: "power", iconColor: ShuttleTrackTheme.Colors.info)
                        
                        FormToggleField(
                            title: "Aktif",
                            icon: "power",
                            iconColor: ShuttleTrackTheme.Colors.info,
                            isOn: $isActive
                        )
                    }
                    
                    // Hata Mesajı
                    if !errorMessage.isEmpty {
                        VStack {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(ShuttleTrackTheme.Colors.error)
                                Text(errorMessage)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(ShuttleTrackTheme.Colors.error)
                            }
                            .padding()
                            .background(ShuttleTrackTheme.Colors.error.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                    
                    // Bottom padding
                    Spacer(minLength: 100)
                }
            }
            .background(ShuttleTrackTheme.Colors.background)
            .navigationTitle(isEditing ? "Şoför Düzenle" : "Yeni Şoför")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark")
                        Text("İptal")
                    }
                    .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                },
                trailing: Button(action: {
                    Task {
                        await saveDriver()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                        Text("Kaydet")
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(isFormValid ? ShuttleTrackTheme.Colors.primaryBlue : ShuttleTrackTheme.Colors.tertiaryText)
                }
                .disabled(!isFormValid || isLoading)
            )
            .overlay(
                Group {
                    if isLoading {
                        ZStack {
                            Color.black.opacity(0.3)
                                .ignoresSafeArea()
                            
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                
                                Text("Kaydediliyor...")
                                    .foregroundColor(.white)
                                    .font(.headline)
                            }
                            .padding(30)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(16)
                        }
                    }
                }
            )
        }
    }
    
    private var isFormValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !phoneNumber.isEmpty && isValidEmail(email)
    }
    
    private func saveDriver() async {
        isLoading = true
        errorMessage = ""
        
        guard let companyId = appViewModel.currentCompany?.id else {
            errorMessage = "Şirket bilgisi bulunamadı"
            isLoading = false
            return
        }
        
        // Telefonu E.164'e normalize et
        guard let normalizedPhone = normalizePhoneToE164(phoneNumber) else {
            errorMessage = "Telefon formatı geçersiz. Örn: +905xxxxxxxxx"
            isLoading = false
            return
        }

        // 1) E-posta şirket yetkilisinin kendi e-postası mı? (Aynı mail ile şoför eklenemez)
        if let adminEmail = appViewModel.currentUserProfile?.email, adminEmail.lowercased() == email.lowercased() {
            errorMessage = "Bu e‑posta şirket yetkilisine ait. Şoför eklenemez."
            isLoading = false
            return
        }

        // 2) Aynı şirkette aynı e‑posta ile şoför var mı?
        let emailDup = viewModel.drivers.contains { $0.companyId == companyId && $0.email.lowercased() == email.lowercased() }
        if emailDup {
            errorMessage = "Bu e‑posta ile kayıtlı bir şoför zaten mevcut."
            isLoading = false
            return
        }
        // 3) Telefon dup kontrolü (mevcut davranış)
        let phoneDup = viewModel.drivers.contains { $0.phoneNumber == normalizedPhone }
        if phoneDup {
            errorMessage = "Bu telefon numarası zaten kayıtlı"
            isLoading = false
            return
        }

        // Cloud Function ile sürücü için Auth kullanıcısı oluştur
        // Not: Fallback mekanizması kaldırıldı çünkü admin oturumunu korumak için şifre gerekiyor
        // Cloud Function başarısız olursa, sürücü kaydedilir ama authUserId olmadan (anonymous giriş yapacak)
        var createdAuthUid: String? = nil
        do {
            createdAuthUid = try await createDriverAuthUser(email: email, fullName: "\(firstName) \(lastName)", companyId: companyId)
            print("✅ Cloud Function ile sürücü Auth kullanıcısı oluşturuldu: \(createdAuthUid ?? "nil")")
        } catch {
            let nsError = error as NSError
            var friendly = "Bilinmeyen hata"
            
            // CloudFunctionError mesajını kontrol et
            if let cfError = error as? CloudFunctionError {
                friendly = cfError.message
            } else if nsError.domain == FunctionsErrorDomain {
                friendly = "Şoför için giriş hesabı oluşturulamadı. Lütfen Cloud Functions dağıtımını kontrol edin."
            } else if nsError.domain == NSURLErrorDomain {
                friendly = "Ağ/bağlantı veya Functions erişim hatası. İnternet ve proje ayarlarını kontrol edin."
            } else {
                friendly = error.localizedDescription
            }
            
            print("❌ createDriverUser hata: \(friendly) [domain=\(nsError.domain) code=\(nsError.code)]")
            print("❌ Hata detayı: \(error)")
            print("⚠️ Cloud Function başarısız, sürücü kaydedilecek ancak authUserId olmadan")
            
            // Cloud Function başarısız, kullanıcıya uyarıyı göster ama kaydı sürdür
            // Admin oturumu korunuyor çünkü signOut yapmıyoruz
            if let cfError = error as? CloudFunctionError, cfError.message.contains("hiçbir bölgede bulunamadı") {
                // Cloud Function hiç deploy edilmemiş
                self.errorMessage = "⚠️ Sürücü kaydedildi ancak giriş hesabı oluşturulamadı. Cloud Function deploy edilmemiş. Sürücü ilk girişinde anonymous olarak giriş yapacak."
            } else {
                // Diğer hatalar
                self.errorMessage = "⚠️ Sürücü kaydedildi ancak giriş hesabı oluşturulamadı. Sürücü ilk girişinde anonymous olarak giriş yapacak."
            }
        }
        
        let newDriver = Driver(
            id: driver?.id ?? UUID().uuidString,
            firstName: firstName,
            lastName: lastName,
            phoneNumber: normalizedPhone,
            email: email,
            isActive: isActive,
            companyId: companyId
        )
        // Auth UID'yi driver kaydına iliştir
        var driverWithAuth = newDriver
        driverWithAuth.authUserId = createdAuthUid

        if isEditing {
            viewModel.updateDriver(driverWithAuth)
            // Düzenleme durumunda: authUserId varsa UserProfile'ı güncelle
            if let authUid = driverWithAuth.authUserId ?? createdAuthUid {
                await updateDriverUserProfile(
                    userId: authUid,
                    driver: driverWithAuth
                )
            }
        } else {
            viewModel.addDriver(driverWithAuth)
            // Yeni sürücü: authUserId varsa UserProfile oluştur
            if let authUid = createdAuthUid {
                await createDriverUserProfile(
                    userId: authUid,
                    driver: driverWithAuth
                )
            }
        }

        // Kaydetme sonucu bekle (kısa gecikme)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
            if self.viewModel.errorMessage.isEmpty {
                self.presentationMode.wrappedValue.dismiss()
            } else {
                self.errorMessage = self.viewModel.errorMessage
            }
        }
    }

    // Cloud Function: createDriverUser(email, fullName, companyId) -> { uid }
    // Birden fazla bölgeyi deneyerek Cloud Function'ı bulmaya çalışır
    private func createDriverAuthUser(email: String, fullName: String, companyId: String) async throws -> String {
        // Yaygın Firebase Functions bölgeleri (sırayla denenir)
        let regions = ["us-central1", "europe-west1", "asia-northeast1", "us-east1"]
        let data: [String: Any] = [
            "email": email,
            "fullName": fullName,
            "companyId": companyId,
            "defaultPassword": "000000"
        ]
        
        // Her bölgeyi sırayla dene
        for region in regions {
            do {
                let functions = Functions.functions(region: region)
                let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
                    functions.httpsCallable("createDriverUser").call(data) { result, error in
                        if let error = error {
                            let nsError = error as NSError
                            print("❌ Cloud Function hata [\(region)]: domain=\(nsError.domain), code=\(nsError.code), description=\(error.localizedDescription)")
                            
                            if nsError.domain == FunctionsErrorDomain {
                                if let code = FunctionsErrorCode(rawValue: nsError.code), code == .notFound {
                                    // Bu bölgede bulunamadı, bir sonraki bölgeyi dene
                                    continuation.resume(throwing: CloudFunctionError(message: "NOT_FOUND"))
                                } else {
                                    // Başka bir Functions hatası
                                    let errorMessage = "Cloud Function hatası: \(error.localizedDescription)"
                                    continuation.resume(throwing: CloudFunctionError(message: errorMessage))
                                }
                            } else {
                                continuation.resume(throwing: error)
                            }
                            return
                        }
                        
                        // Yanıt kontrolü
                        guard let result = result else {
                            print("❌ Cloud Function yanıtı nil [\(region)]")
                            continuation.resume(throwing: CloudFunctionError(message: "Cloud Function yanıt vermedi"))
                            return
                        }
                        
                        // Yanıt formatını kontrol et
                        let responseData = result.data
                        print("📊 Cloud Function yanıtı [\(region)]: \(String(describing: responseData))")
                        
                        // Dictionary olarak parse et
                        guard let dict = responseData as? [String: Any] else {
                            print("❌ Cloud Function yanıtı dictionary değil [\(region)]: \(type(of: responseData))")
                            continuation.resume(throwing: CloudFunctionError(message: "Cloud Function geçersiz yanıt formatı döndürdü. Beklenen: dictionary, Alınan: \(type(of: responseData))"))
                            return
                        }
                        
                        // UID'yi al
                        guard let uid = dict["uid"] as? String, !uid.isEmpty else {
                            print("❌ Cloud Function yanıtında 'uid' bulunamadı [\(region)]: \(dict)")
                            continuation.resume(throwing: CloudFunctionError(message: "Cloud Function yanıtında 'uid' bulunamadı. Yanıt: \(dict)"))
                            return
                        }
                        
                        print("✅ Cloud Function başarılı [\(region)], UID: \(uid)")
                        continuation.resume(returning: uid)
                    }
                }
                
                // Başarılı oldu, sonucu döndür
                return result
                
            } catch {
                // NOT_FOUND hatası ise bir sonraki bölgeyi dene
                if let cfError = error as? CloudFunctionError, cfError.message == "NOT_FOUND" {
                    print("⚠️ Cloud Function '\(region)' bölgesinde bulunamadı, bir sonraki bölge deneniyor...")
                    continue
                } else {
                    // Başka bir hata, direkt fırlat
                    throw error
                }
            }
        }
        
        // Tüm bölgeler denenmiş ve bulunamadı
        throw CloudFunctionError(message: "Cloud Function 'createDriverUser' hiçbir bölgede bulunamadı. Lütfen Firebase Console'dan Cloud Functions'ı deploy edin. Denenen bölgeler: \(regions.joined(separator: ", "))")
    }
    
    // Sürücü için UserProfile oluştur
    private func createDriverUserProfile(userId: String, driver: Driver) async {
        let db = Firestore.firestore()
        
        var profile = UserProfile(
            userId: userId,
            userType: .driver,
            email: driver.email,
            fullName: driver.fullName,
            phone: driver.phoneNumber,
            companyId: driver.companyId,
            driverLicenseNumber: nil
        )
        profile.id = userId
        profile.isActive = driver.isActive // Sürücü aktifse profil de aktif
        profile.lastLoginAt = nil // İlk giriş yapılmadı
        
        do {
            try db.collection("userProfiles").document(userId).setData(from: profile, merge: true) { error in
                if let error = error {
                    print("❌ Sürücü UserProfile oluşturma hatası: \(error.localizedDescription)")
                } else {
                    print("✅ Sürücü UserProfile başarıyla oluşturuldu: \(userId)")
                }
            }
        } catch {
            print("❌ Sürücü UserProfile encode hatası: \(error.localizedDescription)")
        }
    }
    
    // Sürücü için UserProfile güncelle
    private func updateDriverUserProfile(userId: String, driver: Driver) async {
        let db = Firestore.firestore()
        
        do {
            // Önce mevcut profili kontrol et
            let document = try await db.collection("userProfiles").document(userId).getDocument()
            
            if document.exists {
                // Profil var, güncelle
                let updateData: [String: Any] = [
                    "email": driver.email,
                    "fullName": driver.fullName,
                    "phone": driver.phoneNumber,
                    "companyId": driver.companyId,
                    "isActive": driver.isActive,
                    "updatedAt": Date()
                ]
                
                try await db.collection("userProfiles").document(userId).updateData(updateData)
                print("✅ Sürücü UserProfile başarıyla güncellendi: \(userId)")
            } else {
                // Profil yok, oluştur
                await createDriverUserProfile(userId: userId, driver: driver)
            }
        } catch {
            print("❌ Sürücü UserProfile güncelleme hatası: \(error.localizedDescription)")
        }
    }
    
    private func normalizePhoneToE164(_ input: String) -> String? {
        // Basit TR örneği: baştaki 0'ı at, +90 ekle; +90 ile başlıyorsa kabul
        let trimmed = input.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
        if trimmed.hasPrefix("+90") {
            let digits = trimmed.dropFirst(3)
            return digits.count == 10 ? trimmed : nil
        }
        if trimmed.hasPrefix("0") {
            let rest = trimmed.dropFirst(1)
            return rest.count == 10 ? "+90" + rest : nil
        }
        // 10 haneli çıplak numara ise TR kabul et
        if trimmed.count == 10, let _ = Int(trimmed) {
            return "+90" + trimmed
        }
        return nil
    }

    private func isValidEmail(_ value: String) -> Bool {
        // Basit e-posta kontrolü (RFC kapsamlı değil, UI validasyonu için yeterli)
        let pattern = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$"
        return value.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
}

// Preview removed - ViewModel requires @MainActor context