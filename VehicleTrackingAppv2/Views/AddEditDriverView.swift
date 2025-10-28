import SwiftUI

struct AddEditDriverView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: DriverViewModel
    @StateObject private var appViewModel: AppViewModel
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phoneNumber = ""
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
        !firstName.isEmpty && !lastName.isEmpty && !phoneNumber.isEmpty
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

        let newDriver = Driver(
            id: driver?.id ?? UUID().uuidString,
            firstName: firstName,
            lastName: lastName,
            phoneNumber: normalizedPhone,
            isActive: isActive,
            companyId: companyId
        )
        
        if isEditing {
            viewModel.updateDriver(newDriver)
        } else {
            // Aynı telefonda aktif kayıt var mı kontrol et
            let exists = viewModel.drivers.contains { $0.phoneNumber == normalizedPhone }
            if exists {
                errorMessage = "Bu telefon numarası zaten kayıtlı"
                isLoading = false
                return
            }
            viewModel.addDriver(newDriver)
        }
        
        // Simulate save completion
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 saniye
        
        isLoading = false
        
        if viewModel.errorMessage.isEmpty {
            presentationMode.wrappedValue.dismiss()
        } else {
            errorMessage = viewModel.errorMessage
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
}

struct AddEditDriverView_Previews: PreviewProvider {
    static var previews: some View {
        AddEditDriverView(
            viewModel: DriverViewModel(),
            appViewModel: AppViewModel()
        )
    }
}