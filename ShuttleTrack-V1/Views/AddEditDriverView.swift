import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth

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
            .navigationTitle(isEditing ? "Sürücü Düzenle" : "Yeni Sürücü")
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
                    .font(.headline)
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

        // Email'i normalize et (lowercase)
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1) E-posta şirket yetkilisinin kendi e-postası mı? (Aynı mail ile sürücü eklenemez)
        if let adminEmail = appViewModel.currentUserProfile?.email, adminEmail.lowercased() == normalizedEmail {
            errorMessage = "Bu e‑posta şirket yetkilisine ait. Sürücü eklenemez."
            isLoading = false
            return
        }
        
        // 2) Aynı şirkette aynı e‑posta ile sürücü var mı? (Düzenleme durumunda mevcut sürücüyü hariç tut)
        let emailDup = viewModel.drivers.contains { driver in
            driver.companyId == companyId 
            && driver.email.lowercased() == normalizedEmail
            && (isEditing ? driver.id != self.driver?.id : true) // Düzenleme durumunda mevcut sürücüyü hariç tut
        }
        if emailDup {
            errorMessage = "Bu e‑posta ile kayıtlı bir sürücü zaten mevcut."
            isLoading = false
            return
        }
        // 3) Telefon dup kontrolü (Düzenleme durumunda mevcut sürücüyü hariç tut)
        let phoneDup = viewModel.drivers.contains { driver in
            driver.phoneNumber == normalizedPhone
            && (isEditing ? driver.id != self.driver?.id : true) // Düzenleme durumunda mevcut sürücüyü hariç tut
        }
        if phoneDup {
            errorMessage = "Bu telefon numarası zaten kayıtlı"
            isLoading = false
            return
        }

        // Firebase Auth kullanıcısı oluşturma işlemi login anına bırakıldı
        // Bu sayede admin oturumu korunur ve Cloud Function gerekmez
        // Sürücü login olurken, eğer isActive ise ve authUserId yoksa Firebase Auth ile kullanıcı oluşturulur
        
        // Yeni driver için ID nil bırakılır (Firestore otomatik oluşturur)
        // Düzenleme için mevcut ID kullanılır
        // Email'i lowercase'e çevirerek kaydet (tutarlılık için)
        let newDriver = Driver(
            id: isEditing ? driver?.id : nil,
            firstName: firstName,
            lastName: lastName,
            phoneNumber: normalizedPhone,
            email: normalizedEmail,
            isActive: isActive,
            companyId: companyId
        )
        
        // Düzenleme durumunda: Eğer email değiştiyse ve authUserId varsa, 
        // mevcut authUserId'yi koruyoruz (email değişikliği Firebase Auth'ta manuel yapılmalı)
        var driverWithAuth = newDriver
        if isEditing, let existingAuthUserId = driver?.authUserId {
            driverWithAuth.authUserId = existingAuthUserId
            // Düzenleme durumunda: authUserId varsa UserProfile'ı güncelle
            await updateDriverUserProfile(
                userId: existingAuthUserId,
                driver: driverWithAuth
            )
        }

        if isEditing {
            viewModel.updateDriver(driverWithAuth)
        } else {
            viewModel.addDriver(driverWithAuth)
            print("✅ Sürücü kaydedildi. Sürücü ilk girişinde Firebase Auth hesabı otomatik oluşturulacak.")
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