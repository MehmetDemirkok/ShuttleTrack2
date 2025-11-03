import SwiftUI
import FirebaseFirestore

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

        // 1) E-posta şirket yetkilisi tarafından kullanılıyor mu?
        let db = Firestore.firestore()
        let adminQuery = db.collection("userProfiles")
            .whereField("email", isEqualTo: email)
            .whereField("userType", isEqualTo: UserType.companyAdmin.rawValue)
        
        adminQuery.getDocuments { snapshot, err in
            DispatchQueue.main.async {
                if let err = err {
                    self.errorMessage = err.localizedDescription
                    self.isLoading = false
                    return
                }
                if let docs = snapshot?.documents, !docs.isEmpty {
                    self.errorMessage = "Bu e‑posta zaten şirket yetkilisi olarak kayıtlı. Şoför eklenemez."
                    self.isLoading = false
                    return
                }
                
                // 2) Aynı şirkette aynı e‑posta ile şoför var mı?
                let emailDup = self.viewModel.drivers.contains { $0.companyId == companyId && $0.email.lowercased() == self.email.lowercased() }
                if emailDup {
                    self.errorMessage = "Bu e‑posta ile kayıtlı bir şoför zaten mevcut."
                    self.isLoading = false
                    return
                }
                // 3) Telefon dup kontrolü (mevcut davranış)
                let phoneDup = self.viewModel.drivers.contains { $0.phoneNumber == normalizedPhone }
                if phoneDup {
                    self.errorMessage = "Bu telefon numarası zaten kayıtlı"
                    self.isLoading = false
                    return
                }
                
                let newDriver = Driver(
                    id: self.driver?.id ?? UUID().uuidString,
                    firstName: self.firstName,
                    lastName: self.lastName,
                    phoneNumber: normalizedPhone,
                    email: self.email,
                    isActive: self.isActive,
                    companyId: companyId
                )
                
                if self.isEditing {
                    self.viewModel.updateDriver(newDriver)
                } else {
                    self.viewModel.addDriver(newDriver)
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

struct AddEditDriverView_Previews: PreviewProvider {
    static var previews: some View {
        AddEditDriverView(
            viewModel: DriverViewModel(),
            appViewModel: AppViewModel()
        )
    }
}