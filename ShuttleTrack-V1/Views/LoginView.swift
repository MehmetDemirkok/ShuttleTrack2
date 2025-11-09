import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

struct LoginView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var driverIdentifier = "" // e-posta veya telefon
    @State private var isDriverFlow = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingSignUp = false
    @State private var showAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: ShuttleTrackTheme.Spacing.xl) {
                // Logo
                VStack(spacing: ShuttleTrackTheme.Spacing.md) {
                    LogoView(size: 120)
                        .padding(.top, ShuttleTrackTheme.Spacing.xxl)
                }
                
                Spacer()
                
                // Giriş Formu
                ShuttleTrackCard {
                    VStack(spacing: ShuttleTrackTheme.Spacing.md) {
                        // Mod seçimi
                        Picker("Giriş Türü", selection: $isDriverFlow) {
                            Text("Admin/Yetkili").tag(false)
                            Text("Sürücü").tag(true)
                        }
                        .pickerStyle(.segmented)

                        // Admin/Yetkili: Email & Şifre
                        if !isDriverFlow {
                            // Email Field
                        VStack(alignment: .leading, spacing: ShuttleTrackTheme.Spacing.sm) {
                            Text("E-posta")
                                .shuttleTrackCaption()
                                .foregroundColor(.primary)
                            
                            TextField("ornek@email.com", text: $email)
                                .textFieldStyle(ShuttleTrackTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: ShuttleTrackTheme.Spacing.sm) {
                                Text("Şifre")
                                    .shuttleTrackCaption()
                                    .foregroundColor(.primary)
                                
                                SecureField("••••••••", text: $password)
                                    .textFieldStyle(ShuttleTrackTextFieldStyle())
                            }
                        } else {
                            // Sürücü: Email veya Telefon
                            VStack(alignment: .leading, spacing: ShuttleTrackTheme.Spacing.sm) {
                                Text("E-posta veya Telefon")
                                    .shuttleTrackCaption()
                                    .foregroundColor(.primary)
                                
                                TextField("ornek@email.com veya +90 5xx xxx xx xx", text: $driverIdentifier)
                                    .textFieldStyle(ShuttleTrackTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                        }
                        
                        // Error Message
                        if !errorMessage.isEmpty {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(ShuttleTrackTheme.Colors.error)
                                Text(errorMessage)
                                    .shuttleTrackCaption()
                                    .foregroundColor(ShuttleTrackTheme.Colors.error)
                            }
                            .padding(.top, ShuttleTrackTheme.Spacing.sm)
                        }
                        
                        // Login Button
                        Button(action: {
                            if isDriverFlow { driverQuickLogin() } else { signIn() }
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                }
                                Text(isDriverFlow ? "Sürücü Paneline Git" : "Giriş Yap")
                            }
                        }
                        .buttonStyle(ShuttleTrackButtonStyle(variant: .primary, size: .large))
                        .disabled(isLoading || (!isDriverFlow && (email.isEmpty || password.isEmpty)) || (isDriverFlow && driverIdentifier.isEmpty))
                        .padding(.top, ShuttleTrackTheme.Spacing.md)
                    }
                }
                .padding(.horizontal, ShuttleTrackTheme.Spacing.lg)
                
                // Sign Up Link
                VStack(spacing: 8) {
                    HStack {
                        Text("Hesabınız yok mu?")
                            .shuttleTrackCaption()
                        Button("Kayıt Ol") {
                            showingSignUp = true
                        }
                        .foregroundColor(ShuttleTrackTheme.Colors.primaryBlue)
                        .font(.system(size: 14, weight: .semibold))
                    }
                }
                
                Spacer()
            }
            .background(ShuttleTrackTheme.Colors.background)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingSignUp) {
            SignUpView()
        }
        .onReceive(appViewModel.$authMessage) { message in
            if !message.isEmpty {
                self.errorMessage = message
                self.showAlert = true
                appViewModel.authMessage = ""
            }
        }
        .onAppear {
            // Sign-out sonrası AppViewModel.authMessage zaten dolu olabilir; giriş ekranı açılır açılmaz göster
            if !appViewModel.authMessage.isEmpty {
                self.errorMessage = appViewModel.authMessage
                self.showAlert = true
                appViewModel.authMessage = ""
            }
        }
        .ignoresSafeArea(.keyboard)
        .alert("Bilgi", isPresented: $showAlert) {
            Button("Tamam") { showAlert = false }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func signIn() {
        isLoading = true
        errorMessage = ""
        
        let loginEmail: String = (email == "Admin") ? "admin@shuttletrack.local" : email
        Auth.auth().signIn(withEmail: loginEmail, password: password) { result, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = error.localizedDescription
                } else if let user = result?.user {
                    // Profili kontrol et: aktif değilse çıkış yap ve bilgilendir
                    let db = Firestore.firestore()
                    db.collection("userProfiles").document(user.uid).getDocument { snapshot, err in
                        DispatchQueue.main.async {
                            if let err = err {
                                // Sessizce geç; AppViewModel yüklemeye çalışacak
                                print("⚠️ Profil kontrol hatası: \(err.localizedDescription)")
                                return
                            }
                            if let snapshot = snapshot, snapshot.exists {
                                do {
                                    let profile = try snapshot.data(as: UserProfile.self)
                                    // Sadece sürücüler için aktiflik kontrolü yap
                                    if profile.userType == .driver && profile.isActive == false {
                                        do { try Auth.auth().signOut() } catch { }
                                        self.errorMessage = "Hesabınız onay beklemektedir. Lütfen uygulama yetkilileri tarafından onaylanana kadar bekleyiniz."
                                        self.showAlert = true
                                    }
                                } catch {
                                    // Decode hatası durumunda bir şey yapma
                                }
                            } else {
                                // Profil yoksa büyük ihtimalle onay süreci bekleniyor
                                do { try Auth.auth().signOut() } catch { }
                                self.errorMessage = "Hesabınız onay beklemektedir. Lütfen uygulama yetkilileri tarafından onaylanana kadar bekleyiniz."
                                self.showAlert = true
                            }
                        }
                    }
                }
            }
        }
    }

    private func driverQuickLogin() {
        isLoading = true
        errorMessage = ""
        let raw = driverIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        let (maybeEmail, maybePhone) = classify(raw)
        
        // Önce sürücüyü Firestore'dan bul (anonymous giriş yapmadan)
        let db = Firestore.firestore()
        var query = db.collection("drivers").whereField("isActive", isEqualTo: true)
        if let email = maybeEmail {
            query = query.whereField("email", isEqualTo: email)
        } else if let phone = maybePhone {
            query = query.whereField("phoneNumber", isEqualTo: phone)
        } else {
            self.isLoading = false
            self.errorMessage = "Lütfen geçerli e‑posta veya telefon girin"
            return
        }
        
        query.getDocuments { snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.isLoading = false
                    self.errorMessage = ErrorHandler.shared.getLocalizedErrorMessage(error)
                    return
                }
                
                guard let doc = snapshot?.documents.first, let driver = try? doc.data(as: Driver.self) else {
                    self.isLoading = false
                    self.errorMessage = "Kayıtlı aktif sürücü bulunamadı"
                    return
                }
                
                // Eğer sürücüde authUserId varsa, direkt email/password ile giriş yap
                if let authUserId = driver.authUserId, !authUserId.isEmpty {
                    // Email/password kullanıcısına direkt giriş yap (anonymous oluşturma)
                    let defaultPassword = "000000"
                    Auth.auth().signIn(withEmail: driver.email, password: defaultPassword) { signInResult, signInError in
                        DispatchQueue.main.async {
                            if let signInError = signInError {
                                self.isLoading = false
                                let nsError = signInError as NSError
                                // Şifre yanlış veya kullanıcı bulunamadı hatası
                                if nsError.domain == "FIRAuthErrorDomain" {
                                    if nsError.code == 17008 { // Wrong password
                                        self.errorMessage = "Şifre hatalı. Lütfen yöneticinizle iletişime geçin."
                                    } else if nsError.code == 17011 { // User not found
                                        self.errorMessage = "Giriş hesabı bulunamadı. Lütfen yöneticinizle iletişime geçin."
                                    } else {
                                        self.errorMessage = ErrorHandler.shared.getLocalizedErrorMessage(signInError)
                                    }
                                } else {
                                    self.errorMessage = ErrorHandler.shared.getLocalizedErrorMessage(signInError)
                                }
                                return
                            }
                            
                            // Email/password girişi başarılı
                            print("✅ Email/password kullanıcısına giriş yapıldı")
                            if let user = signInResult?.user {
                                // Profil zaten var mı kontrol et, yoksa oluştur
                                self.checkAndCreateProfileIfNeeded(driver: driver, userId: user.uid)
                            }
                        }
                    }
                } else {
                    // authUserId yoksa, anonymous giriş yap (eski sürücüler için)
                    print("⚠️ Sürücüde authUserId yok, anonymous giriş yapılıyor")
                    Auth.auth().signInAnonymously { _, anonErr in
                        DispatchQueue.main.async {
                            if let anonErr = anonErr {
                                self.isLoading = false
                                self.errorMessage = ErrorHandler.shared.getLocalizedErrorMessage(anonErr)
                                return
                            }
                            
                            guard let currentUser = Auth.auth().currentUser else {
                                self.isLoading = false
                                self.errorMessage = "Kullanıcı oluşturulamadı"
                                return
                            }
                            
                            // Anonymous ile devam et
                            self.createUserProfileAndContinue(driver: driver, userId: currentUser.uid)
                        }
                    }
                }
            }
        }
    }
    
    // Profil var mı kontrol et, yoksa oluştur
    private func checkAndCreateProfileIfNeeded(driver: Driver, userId: String) {
        let db = Firestore.firestore()
        db.collection("userProfiles").document(userId).getDocument { snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("⚠️ Profil kontrol hatası: \(error.localizedDescription)")
                    // Hata olsa bile profil oluşturmayı dene
                    self.createUserProfileAndContinue(driver: driver, userId: userId)
                    return
                }
                
                if let snapshot = snapshot, snapshot.exists {
                    // Profil zaten var, AppViewModel yükleyecek
                    print("✅ Profil zaten mevcut, AppViewModel yükleyecek")
                    self.isLoading = false
                    // AppViewModel'in authStateListener'ı otomatik olarak profili yükleyecek
                } else {
                    // Profil yok, oluştur
                    print("ℹ️ Profil bulunamadı, oluşturuluyor...")
                    self.createUserProfileAndContinue(driver: driver, userId: userId)
                }
            }
        }
    }

    private func createUserProfileAndContinue(driver: Driver, userId: String) {
        let now = Date()
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
        profile.isActive = true
        profile.lastLoginAt = now
        
        do {
            try Firestore.firestore().collection("userProfiles").document(userId).setData(from: profile, merge: true) { setErr in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let setErr = setErr {
                        // Profil oluşturma başarısız, hata mesajı göster ama çıkış yapma
                        // Çünkü kullanıcı zaten giriş yapmış olabilir
                        let errorMsg = ErrorHandler.shared.getLocalizedErrorMessage(setErr)
                        print("❌ Profil oluşturma başarısız: \(setErr.localizedDescription)")
                        self.errorMessage = errorMsg
                        
                        // Eğer kullanıcı zaten giriş yapmışsa, AppViewModel profili yüklemeye çalışacak
                        // Eğer yüklenemezse timeout mekanizması devreye girecek
                        // Burada signOut yapmıyoruz çünkü kullanıcı zaten giriş yapmış olabilir
                    } else {
                        // AppViewModel'a bildir: profil oluşturuldu, şirketi yükle ve yönlendir
                        print("✅ Profil başarıyla oluşturuldu: \(userId)")
                        self.appViewModel.reloadAfterDriverProfileCreated(profile)
                    }
                }
            }
        } catch {
            self.isLoading = false
            let errorMsg = ErrorHandler.shared.getLocalizedErrorMessage(error)
            print("❌ Profil oluşturma hatası: \(error.localizedDescription)")
            self.errorMessage = errorMsg
            // Hata olsa bile çıkış yapma, AppViewModel profili yüklemeye çalışacak
        }
    }
    
    private func classify(_ input: String) -> (String?, String?) {
        // email?
        let emailPattern = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$"
        if input.range(of: emailPattern, options: [.regularExpression, .caseInsensitive]) != nil {
            return (input, nil)
        }
        // phone?
        let normalized = input.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
        if normalized.hasPrefix("+90") {
            let digits = normalized.dropFirst(3)
            return (nil, digits.count == 10 ? normalized : nil)
        }
        if normalized.hasPrefix("0") {
            let rest = normalized.dropFirst(1)
            return (nil, rest.count == 10 ? "+90" + rest : nil)
        }
        if normalized.count == 10, Int(normalized) != nil { return (nil, "+90" + normalized) }
        return (nil, nil)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
