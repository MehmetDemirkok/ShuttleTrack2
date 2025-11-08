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
        DispatchQueue.main.async {
            self.currentUserProfile = profile
            let companyId = profile.companyId ?? profile.userId
            self.loadCompanyData(companyId: companyId)
        }
    }
    
    private func loadUserProfile(for user: User) {
        let db = Firestore.firestore()
        
        db.collection("userProfiles").document(user.uid).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                if let document = document, document.exists {
                    do {
                        let profile = try document.data(as: UserProfile.self)
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
                            self?.authMessage = "Hesabınız onay beklemektedir. Lütfen uygulama yetkilileri tarafından onaylanana kadar bekleyiniz."
                            self?.currentUserProfile = nil
                            self?.currentCompany = nil
                            self?.signOut()
                        }
                    } catch {
                        print("❌ User profile decode hatası: \(error)")
                        self?.signOut()
                    }
                } else {
                    print("⚠️ User profile not found for user: \(user.uid)")
                    // Anonim oturumlar için varsayılan owner profili OLUŞTURMA.
                    // Sürücü hızlı giriş akışı profilini kendisi oluşturur.
                    if user.isAnonymous {
                        return
                    }
                    // Diğer kullanıcı tipleri için ilk girişte otomatik profil oluştur
                    self?.createDefaultProfileIfMissing(for: user)
                }
            }
        }
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
        
        print("🌐 Loading company data from Firebase...")
        lastCompanyLoadTime = Date()
        let db = Firestore.firestore()
        
        db.collection("companies").document(companyId).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error loading company data: \(error)")
                    return
                }
                
                if let document = document, document.exists {
                    do {
                        let company = try document.data(as: Company.self)
                        self?.currentCompany = company
                        self?.companyCache[companyId] = company
                        print("✅ Company data loaded successfully")
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
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
        cancellables.removeAll()
        print("✅ AppViewModel temizlendi")
    }
}
