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
    @State private var taxNumber = ""
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
                    // Kullanıcı Tipi sabit: Şirket Yetkilisi
                    HStack {
                        Text("Kullanıcı Tipi:")
                            .font(.headline)
                            .foregroundColor(.blue)
                        Text("Şirket Yetkilisi")
                            .font(.subheadline)
                            .fontWeight(.semibold)
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
                    if true {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Şirket Bilgileri")
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            TextField("Şirket Adı", text: $companyName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("Adres", text: $address)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("Vergi Numarası", text: $taxNumber)
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
        
        return basicValidation &&
        !companyName.isEmpty &&
        !address.isEmpty &&
        !taxNumber.isEmpty
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
        var company = Company(
            name: companyName,
            email: email,
            phone: phone,
            address: address,
            taxNumber: taxNumber
        )
        // Şirket başlangıçta pasif; yönetici onayı sonrası aktif edilir
        company.isActive = false
        
        // Kullanıcı profilini oluştur
        var userProfile = UserProfile(
            userId: user.uid,
            userType: .companyAdmin,
            email: email,
            fullName: fullName,
            phone: phone,
            companyId: user.uid,
            driverLicenseNumber: nil
        )
        // Yönetici onayı gereksinimi: başlangıçta pasif
        userProfile.isActive = false
        
        // Firebase'e kaydet
        Task {
            do {
                // Şirket verilerini kaydet
                try db.collection("companies").document(user.uid).setData(from: company)
                
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
