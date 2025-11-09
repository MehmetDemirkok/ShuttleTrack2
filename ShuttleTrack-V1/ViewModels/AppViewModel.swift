import SwiftUI
@preconcurrency import FirebaseAuth
import FirebaseFirestore
import Combine
import Foundation
import FirebaseFirestoreSwift

@MainActor
class AppViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var currentCompany: Company?
    @Published var currentUserProfile: UserProfile?
    @Published var authMessage: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    private var companyCache: [String: Company] = [:]
    private var lastCompanyLoadTime: Date?
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var profileLoadStartTime: Date?
    private var profileLoadTimer: Timer?
    
    init() {
        checkAuthenticationStatus()
    }
    
    private func checkAuthenticationStatus() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.isAuthenticated = user != nil
                self?.currentUser = user
                if let user = user {
                    self?.loadUserProfileAndCompany(for: user)
                } else {
                    self?.currentUserProfile = nil
                    self?.currentCompany = nil
                }
            }
        }
    }
    
    private func loadUserProfileAndCompany(for user: User) {
        // Önce profil, ardından profile göre şirket yükle
        loadUserProfile(for: user)
    }

    // Sürücü hızlı giriş akışında profil oluşturulduktan sonra UI'yı ilerletmek için
    func reloadAfterDriverProfileCreated(_ profile: UserProfile) {
        Task { @MainActor in
            print("🔄 reloadAfterDriverProfileCreated çağrıldı: \(profile.userId)")
            print("🔄 Profil detayları - Email: \(profile.email), CompanyId: \(profile.companyId ?? "nil"), isActive: \(profile.isActive)")
            
            // Timer'ı iptal et (profil başarıyla yüklendi)
            profileLoadTimer?.invalidate()
            profileLoadTimer = nil
            profileLoadStartTime = nil
            
            // Profili set et
            self.currentUserProfile = profile
            print("✅ currentUserProfile set edildi: \(profile.userId)")
            
            // Şirket ID'sini belirle
            guard let companyId = profile.companyId else {
                print("⚠️ Profilde companyId yok, userId kullanılıyor: \(profile.userId)")
                // Kısa bir gecikme sonrası şirket yükle (Firestore rules'ın profili görmesi için)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.loadCompanyData(companyId: profile.userId)
                }
                return
            }
            
            print("🏢 Şirket yükleniyor: \(companyId)")
            // Firestore rules'ın profili görmesi için kısa bir gecikme
            // Profil yeni oluşturuldu, Firestore rules henüz görmeyebilir
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.loadCompanyData(companyId: companyId)
            }
        }
    }
    
    private func loadUserProfile(for user: User) {
        // Eğer profil zaten yüklenmişse ve aynı kullanıcı ise tekrar yükleme
        if let existingProfile = currentUserProfile, existingProfile.userId == user.uid {
            print("ℹ️ User profile zaten yüklü: \(user.uid) — tekrar yükleme atlanıyor")
            // Timer'ı iptal et
            profileLoadTimer?.invalidate()
            profileLoadTimer = nil
            profileLoadStartTime = nil
            // Şirket bilgisi yoksa yükle
            if currentCompany == nil {
                let companyId = existingProfile.companyId ?? user.uid
                print("🏢 Şirket bilgisi yok, yükleniyor: \(companyId)")
                loadCompanyData(companyId: companyId)
            } else {
                print("✅ Profil ve şirket bilgisi zaten yüklü")
            }
            return
        }
        
        // Profil yükleme başlangıç zamanını kaydet
        profileLoadStartTime = Date()
        
        let db = Firestore.firestore()
        
        db.collection("userProfiles").document(user.uid).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                // Yükleme sırasında profil başka bir yerden yüklenmişse (örneğin reloadAfterDriverProfileCreated)
                // tekrar yükleme yapma
                if let existingProfile = self?.currentUserProfile, existingProfile.userId == user.uid {
                    print("ℹ️ User profile zaten yüklü (yükleme sırasında): \(user.uid) — tekrar yükleme atlanıyor")
                    // Timer'ı iptal et
                    self?.profileLoadTimer?.invalidate()
                    self?.profileLoadTimer = nil
                    self?.profileLoadStartTime = nil
                    if self?.currentCompany == nil {
                        let companyId = existingProfile.companyId ?? user.uid
                        self?.loadCompanyData(companyId: companyId)
                    }
                    return
                }
                
                if let document = document, document.exists {
                    do {
                        let profile = try document.data(as: UserProfile.self)
                        // Timer'ı iptal et
                        self?.profileLoadTimer?.invalidate()
                        self?.profileLoadTimer = nil
                        self?.profileLoadStartTime = nil
                        // Profil aktif mi kontrol et
                        // Owner ve CompanyAdmin kullanıcıları onay beklemeden erişebilir
                        if profile.isActive || profile.userType == .owner || profile.userType == .companyAdmin {
                            self?.currentUserProfile = profile
                            print("✅ User profile yüklendi: \(user.uid)")
                            // Profilden şirket ID'sini belirle
                            let companyId = profile.companyId ?? user.uid
                            self?.loadCompanyData(companyId: companyId)
                        } else {
                            print("⚠️ User profile deaktif: \(user.uid) — giriş engellenecek")
                            // Deaktif kullanıcıları tamamen çıkışa yönlendir
                            // Sürücüler için: Şirket yetkilisi maili ekledikten sonra isActive=true yapılmalı
                            if profile.userType == .driver {
                                self?.authMessage = "Hesabınız henüz onaylanmamış. Lütfen şirket yetkilinizle iletişime geçin."
                            } else {
                                self?.authMessage = "Hesabınız onay beklemektedir. Lütfen uygulama yetkilileri tarafından onaylanana kadar bekleyiniz."
                            }
                            self?.currentUserProfile = nil
                            self?.currentCompany = nil
                            self?.signOut()
                        }
                    } catch {
                        print("❌ User profile decode hatası: \(error)")
                        self?.profileLoadTimer?.invalidate()
                        self?.profileLoadTimer = nil
                        self?.profileLoadStartTime = nil
                        self?.signOut()
                    }
                } else {
                    print("⚠️ User profile not found for user: \(user.uid)")
                    // Anonim oturumlar için varsayılan owner profili OLUŞTURMA.
                    // Sürücü hızlı giriş akışı profilini kendisi oluşturur.
                    if user.isAnonymous {
                        // Anonymous kullanıcı için timeout: 10 saniye içinde profil yüklenmezse çıkış yap
                        self?.startProfileLoadTimeout(for: user)
                        return
                    }
                    // Email/password ile giriş yapan kullanıcılar için (sürücü dahil)
                    // LoginView profil oluşturacak, bu yüzden timeout başlat ve bekle
                    // Sürücü login akışında profil LoginView tarafından oluşturulur
                    print("ℹ️ Profil bulunamadı, LoginView tarafından oluşturulması bekleniyor...")
                    self?.startProfileLoadTimeout(for: user, extendedTimeout: true)
                }
            }
        }
    }
    
    // Profil yükleme timeout'u: Belirli bir süre içinde profil yüklenmezse çıkış yap
    private func startProfileLoadTimeout(for user: User, extendedTimeout: Bool = false) {
        // Önceki timer'ı iptal et
        profileLoadTimer?.invalidate()
        
        // Sürücü login akışında profil oluşturma daha uzun sürebilir, bu yüzden timeout süresini artır
        let timeoutInterval: TimeInterval = extendedTimeout ? 30.0 : 10.0
        
        let userId = user.uid
        let timer = Timer.scheduledTimer(withTimeInterval: timeoutInterval, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                // Hala profil yüklenmemişse ve aynı kullanıcı ise çıkış yap
                if self.currentUserProfile == nil, 
                   let currentUser = Auth.auth().currentUser,
                   currentUser.uid == userId {
                    let timeoutMessage = extendedTimeout ? 
                        "⏱️ Profil yükleme timeout: 30 saniye içinde profil yüklenmedi, çıkış yapılıyor" :
                        "⏱️ Profil yükleme timeout: 10 saniye içinde profil yüklenmedi, çıkış yapılıyor"
                    print(timeoutMessage)
                    self.authMessage = "Profil yüklenemedi. Lütfen tekrar giriş yapmayı deneyin."
                    self.signOut()
                }
                self.profileLoadTimer = nil
                self.profileLoadStartTime = nil
            }
        }
        profileLoadTimer = timer
    }
    
    private func loadCompanyData(companyId: String) {
        // Cache kontrolü - 10 dakika içinde yüklenmişse cache'den al
        if let lastLoad = lastCompanyLoadTime,
           Date().timeIntervalSince(lastLoad) < 600, // 10 dakika
           let cachedCompany = companyCache[companyId] {
            print("📦 Company data loaded from cache")
            currentCompany = cachedCompany
            return
        }
        
        // Zaten yükleniyorsa tekrar yükleme
        if lastCompanyLoadTime != nil && Date().timeIntervalSince(lastCompanyLoadTime!) < 10 {
            print("⏳ Company data already loading, skipping...")
            return
        }
        
        print("🌐 Loading company data from Firebase... CompanyId: \(companyId)")
        lastCompanyLoadTime = Date()
        let db = Firestore.firestore()
        
        db.collection("companies").document(companyId).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                if let error = error {
                    let nsError = error as NSError
                    print("❌ Error loading company data: \(error.localizedDescription)")
                    print("❌ Error code: \(nsError.code), domain: \(nsError.domain)")
                    
                    // Permission denied hatası ise, profil henüz yüklenmemiş olabilir
                    // Birkaç saniye sonra tekrar dene
                    if nsError.domain == "FIRFirestoreErrorDomain" && nsError.code == 7 {
                        print("⚠️ Permission denied, 2 saniye sonra tekrar deneniyor...")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            // Profil yüklendiyse tekrar dene
                            if self?.currentUserProfile != nil {
                                print("🔄 Profil yüklendi, şirket verisi tekrar yükleniyor...")
                                self?.loadCompanyData(companyId: companyId)
                            }
                        }
                    }
                    return
                }
                
                if let document = document, document.exists {
                    do {
                        let company = try document.data(as: Company.self)
                        self?.currentCompany = company
                        self?.companyCache[companyId] = company
                        print("✅ Company data loaded successfully: \(company.name)")
                    } catch {
                        print("❌ Error decoding company: \(error)")
                    }
                } else {
                    print("⚠️ Company document not found for id: \(companyId)")
                }
            }
        }
    }
    
    func signOut() {
        // Timer'ı iptal et
        profileLoadTimer?.invalidate()
        profileLoadTimer = nil
        profileLoadStartTime = nil
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
            currentUser = nil
            currentCompany = nil
        } catch {
            print("Sign out error: \(error)")
        }
    }

    private func createDefaultProfileIfMissing(for user: User) {
        let db = Firestore.firestore()
        var defaultProfile = UserProfile(
            userId: user.uid,
            userType: .owner,
            email: user.email ?? "",
            fullName: user.displayName ?? (user.email ?? "Kullanıcı"),
            phone: nil,
            companyId: user.uid,
            driverLicenseNumber: nil
        )
        // Owner için ilk profil varsayılan olarak aktif olmalı
        defaultProfile.id = user.uid
        defaultProfile.isActive = true

        do {
            try db.collection("userProfiles").document(user.uid).setData(from: defaultProfile, merge: true) { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Default profile create error: \(error)")
                        self?.signOut()
                        return
                    }
                    print("✅ Default owner profile created for user: \(user.uid)")
                    self?.currentUserProfile = defaultProfile
                    self?.loadCompanyData(companyId: defaultProfile.companyId ?? user.uid)
                }
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                print("❌ Encoding default profile error: \(error)")
                self?.signOut()
            }
        }
    }
    
    deinit {
        // Timer'ı iptal et
        profileLoadTimer?.invalidate()
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
        cancellables.removeAll()
        print("✅ AppViewModel temizlendi")
    }
}
