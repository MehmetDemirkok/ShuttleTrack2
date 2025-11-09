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
        
        // Email sorgusu case-sensitive olabilir, bu yüzden tüm aktif sürücüleri çekip client-side filtreleme yapıyoruz
        let query = db.collection("drivers").whereField("isActive", isEqualTo: true)
        
        query.getDocuments { snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.isLoading = false
                    self.errorMessage = ErrorHandler.shared.getLocalizedErrorMessage(error)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.isLoading = false
                    self.errorMessage = "Kayıtlı aktif sürücü bulunamadı"
                    return
                }
                
                // Client-side filtreleme (case-insensitive email karşılaştırması)
                print("🔍 Sürücü arama - Toplam aktif sürücü: \(documents.count)")
                if let email = maybeEmail {
                    print("📧 Email ile aranıyor: \(email)")
                } else if let phone = maybePhone {
                    print("📱 Telefon ile aranıyor: \(phone)")
                }
                
                let drivers = documents.compactMap { doc -> Driver? in
                    guard let driver = try? doc.data(as: Driver.self) else { return nil }
                    
                    if let email = maybeEmail {
                        // Email karşılaştırması case-insensitive
                        let driverEmailLower = driver.email.lowercased()
                        let searchEmailLower = email.lowercased()
                        print("  🔎 Karşılaştırma: '\(driverEmailLower)' == '\(searchEmailLower)' ? \(driverEmailLower == searchEmailLower)")
                        if driverEmailLower == searchEmailLower {
                            print("✅ Eşleşme bulundu: \(driver.fullName) - \(driver.email)")
                            return driver
                        }
                    } else if let phone = maybePhone {
                        // Telefon karşılaştırması (normalize edilmiş)
                        let driverPhoneNormalized = self.normalizePhoneForComparison(driver.phoneNumber)
                        let searchPhoneNormalized = self.normalizePhoneForComparison(phone)
                        if driverPhoneNormalized == searchPhoneNormalized {
                            print("✅ Telefon eşleşmesi bulundu: \(driver.fullName) - \(driver.phoneNumber)")
                            return driver
                        }
                    }
                    return nil
                }
                
                print("📊 Eşleşen sürücü sayısı: \(drivers.count)")
                
                guard let driver = drivers.first else {
                    self.isLoading = false
                    if let email = maybeEmail {
                        self.errorMessage = "Bu e-posta adresi ile kayıtlı aktif sürücü bulunamadı: \(email)"
                    } else if let phone = maybePhone {
                        self.errorMessage = "Bu telefon numarası ile kayıtlı aktif sürücü bulunamadı: \(phone)"
                    } else {
                        self.errorMessage = "Aranan kayıt bulunamadı"
                    }
                    return
                }
                
                // Eğer sürücüde authUserId varsa, direkt email/password ile giriş yap
                if let authUserId = driver.authUserId, !authUserId.isEmpty {
                    // Email/password kullanıcısına direkt giriş yap (anonymous oluşturma)
                    let defaultPassword = "000000"
                    // Email'i normalize et (lowercase)
                    let driverEmail = driver.email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    Auth.auth().signIn(withEmail: driverEmail, password: defaultPassword) { signInResult, signInError in
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
                    // authUserId yoksa, geçici çözüm: direkt Firebase Auth ile kullanıcı oluştur veya giriş yap
                    print("⚠️ Sürücüde authUserId yok, Firebase Auth ile kullanıcı oluşturuluyor/giriş yapılıyor")
                    self.createOrSignInDriver(driver: driver)
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
    
    // Geçici çözüm: Cloud Function olmadan Firebase Auth ile sürücü kullanıcısı oluştur veya giriş yap
    private func createOrSignInDriver(driver: Driver) {
        let defaultPassword = "000000"
        // Email'i normalize et (lowercase)
        let driverEmail = driver.email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Önce giriş yapmayı dene (kullanıcı zaten varsa)
        Auth.auth().signIn(withEmail: driverEmail, password: defaultPassword) { signInResult, signInError in
            DispatchQueue.main.async {
                if let signInError = signInError {
                    let nsError = signInError as NSError
                    
                    // Kullanıcı bulunamadı hatası (17011) - yeni kullanıcı oluştur
                    if nsError.domain == "FIRAuthErrorDomain" && nsError.code == 17011 {
                        print("ℹ️ Kullanıcı bulunamadı, yeni kullanıcı oluşturuluyor...")
                        self.createDriverAuthUser(driver: driver, password: defaultPassword)
                    } else if nsError.code == 17008 {
                        // Şifre yanlış - kullanıcı var ama şifre farklı
                        self.isLoading = false
                        self.errorMessage = "Şifre hatalı. Lütfen yöneticinizle iletişime geçin."
                    } else {
                        // Diğer hatalar
                        self.isLoading = false
                        self.errorMessage = ErrorHandler.shared.getLocalizedErrorMessage(signInError)
                    }
                    return
                }
                
                // Giriş başarılı
                print("✅ Mevcut kullanıcıya giriş yapıldı")
                if let user = signInResult?.user {
                    // Driver kaydını güncelle: authUserId ekle
                    self.updateDriverWithAuthUserId(driver: driver, authUserId: user.uid)
                    // Profil kontrolü ve oluşturma
                    self.checkAndCreateProfileIfNeeded(driver: driver, userId: user.uid)
                }
            }
        }
    }
    
    // Firebase Auth ile sürücü kullanıcısı oluştur
    private func createDriverAuthUser(driver: Driver, password: String) {
        // Email'i normalize et (lowercase)
        let driverEmail = driver.email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        Auth.auth().createUser(withEmail: driverEmail, password: password) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.isLoading = false
                    let nsError = error as NSError
                    
                    // Email zaten kullanılıyor hatası (17007) - tekrar giriş yapmayı dene
                    if nsError.domain == "FIRAuthErrorDomain" && nsError.code == 17007 {
                        print("ℹ️ Email zaten kullanılıyor, giriş yapılıyor...")
                        Auth.auth().signIn(withEmail: driverEmail, password: password) { signInResult, signInError in
                            DispatchQueue.main.async {
                                if let signInError = signInError {
                                    self.isLoading = false
                                    self.errorMessage = ErrorHandler.shared.getLocalizedErrorMessage(signInError)
                                } else if let user = signInResult?.user {
                                    self.updateDriverWithAuthUserId(driver: driver, authUserId: user.uid)
                                    self.checkAndCreateProfileIfNeeded(driver: driver, userId: user.uid)
                                }
                            }
                        }
                    } else {
                        self.errorMessage = ErrorHandler.shared.getLocalizedErrorMessage(error)
                    }
                    return
                }
                
                // Kullanıcı oluşturuldu
                print("✅ Yeni sürücü kullanıcısı oluşturuldu")
                if let user = result?.user {
                    // Driver kaydını güncelle: authUserId ekle
                    self.updateDriverWithAuthUserId(driver: driver, authUserId: user.uid)
                    // Profil oluştur
                    self.createUserProfileAndContinue(driver: driver, userId: user.uid)
                }
            }
        }
    }
    
    // Driver kaydına authUserId ekle
    private func updateDriverWithAuthUserId(driver: Driver, authUserId: String) {
        guard let driverId = driver.id else {
            print("⚠️ Driver ID bulunamadı, authUserId güncellenemedi")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("drivers").document(driverId).updateData([
            "authUserId": authUserId,
            "updatedAt": Date()
        ]) { error in
            if let error = error {
                print("⚠️ Driver authUserId güncelleme hatası: \(error.localizedDescription)")
            } else {
                print("✅ Driver authUserId güncellendi: \(authUserId)")
            }
        }
    }
    
    // Telefon numarasını karşılaştırma için normalize et
    private func normalizePhoneForComparison(_ phone: String) -> String {
        return phone.replacingOccurrences(of: " ", with: "")
                   .replacingOccurrences(of: "-", with: "")
                   .replacingOccurrences(of: "(", with: "")
                   .replacingOccurrences(of: ")", with: "")
                   .replacingOccurrences(of: "+", with: "")
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
