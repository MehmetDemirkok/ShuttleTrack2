import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

struct SignUpView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var companyName = ""
    @State private var displayName = ""
    @State private var fullName = ""
    @State private var phone = ""
    @State private var selectedUserType: UserType = .companyAdmin
    @State private var address = ""
    @State private var licenseNumber = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Kayıt Ol")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                VStack(spacing: 15) {
                    // Kullanıcı Tipi Seçimi
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Kullanıcı Tipi")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        ForEach(UserType.allCases, id: \.self) { userType in
                            Button(action: {
                                selectedUserType = userType
                            }) {
                                HStack {
                                    Image(systemName: userType.icon)
                                        .foregroundColor(selectedUserType == userType ? .white : .blue)
                                        .frame(width: 20)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(userType.displayName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(selectedUserType == userType ? .white : .primary)
                                        
                                        Text(userType.description)
                                            .font(.caption)
                                            .foregroundColor(selectedUserType == userType ? .white.opacity(0.8) : .secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedUserType == userType {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding()
                                .background(selectedUserType == userType ? Color.blue : Color.gray.opacity(0.1))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedUserType == userType ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    Divider()
                    
                    // Kişisel Bilgiler
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Kişisel Bilgiler")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        TextField("Ad Soyad", text: $fullName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Telefon", text: $phone)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.phonePad)
                    }
                    
                    // Şirket Bilgileri (sadece şirket yetkilisi için)
                    if selectedUserType == .companyAdmin {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Şirket Bilgileri")
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            TextField("Şirket Adı", text: $companyName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("Adres", text: $address)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("Lisans Numarası", text: $licenseNumber)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    Divider()
                    
                    // Hesap Bilgileri
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Hesap Bilgileri")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        TextField("E-posta", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        SecureField("Şifre", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        SecureField("Şifre Tekrar", text: $confirmPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button(action: signUp) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isLoading ? "Kayıt Olunuyor..." : "Kayıt Ol")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading || !isFormValid)
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("İptal") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private var isFormValid: Bool {
        let basicValidation = !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        !fullName.isEmpty &&
        !phone.isEmpty &&
        password == confirmPassword &&
        password.count >= 6
        
        if selectedUserType == .companyAdmin {
            return basicValidation &&
            !companyName.isEmpty &&
            !address.isEmpty &&
            !licenseNumber.isEmpty
        } else if selectedUserType == .driver {
            return basicValidation
        }
        
        return basicValidation
    }
    
    private func signUp() {
        isLoading = true
        errorMessage = ""
        
        Auth.auth().createUser(withEmail: email, password: password) { [self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                } else if let user = result?.user {
                    // Kullanıcı oluşturuldu, şimdi şirket ve profil verilerini kaydet
                    self.saveCompanyAndProfileData(user: user)
                }
            }
        }
    }
    
    private func saveCompanyAndProfileData(user: User) {
        let db = Firestore.firestore()
        
        // Şirket verilerini kaydet (sadece şirket yetkilisi için)
        var company: Company? = nil
        if selectedUserType == .companyAdmin {
            company = Company(
                name: companyName,
                email: email,
                phone: phone,
                address: address,
                licenseNumber: licenseNumber
            )
        }
        
        // Kullanıcı profilini oluştur
        let userProfile = UserProfile(
            userId: user.uid,
            userType: selectedUserType,
            email: email,
            fullName: fullName,
            phone: phone,
            companyId: selectedUserType == .companyAdmin ? user.uid : nil,
            driverLicenseNumber: nil
        )
        
        // Firebase'e kaydet
        Task {
            do {
                // Şirket verilerini kaydet (sadece şirket yetkilisi için)
                if let company = company {
                    try db.collection("companies").document(user.uid).setData(from: company)
                }
                
                // Kullanıcı profilini kaydet
                var profileData = userProfile
                profileData.id = userProfile.userId
                try db.collection("userProfiles").document(userProfile.userId).setData(from: profileData)
                
                await MainActor.run {
                    self.isLoading = false
                    self.presentationMode.wrappedValue.dismiss()
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Veriler kaydedilirken hata oluştu: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
