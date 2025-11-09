import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
class DriverViewModel: ObservableObject {
    @Published var drivers: [Driver] = []
    @Published var currentDriver: Driver?
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showRetryButton = false
    @Published var lastFailedAction: (() -> Void)?
    
    private let db = Firestore.firestore()
    private let errorHandler = ErrorHandler.shared
    private let networkMonitor = NetworkMonitor.shared
    private var cancellables = Set<AnyCancellable>()
    private var currentDriverListener: ListenerRegistration?
    
    func fetchDrivers(for companyId: String) {
        isLoading = true
        errorMessage = ""
        
        // Optimize edilmiş sorgu
        db.collection("drivers")
            .whereField("companyId", isEqualTo: companyId)
            .limit(to: 50) // Maksimum 50 şoför
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        let localizedError = self?.errorHandler.getLocalizedErrorMessage(error) ?? "Bir hata oluştu"
                        self?.errorMessage = localizedError
                        self?.showRetryButton = true
                        self?.lastFailedAction = { [weak self] in
                            self?.fetchDrivers(for: companyId)
                        }
                        print("❌ Driver fetch error: \(error.localizedDescription)")
                        return
                    }
                    
                    // Başarılı olduğunda retry butonunu gizle
                    self?.showRetryButton = false
                    self?.lastFailedAction = nil
                    
                    guard let documents = snapshot?.documents else {
                        self?.drivers = []
                        return
                    }
                    
                    print("👨‍💼 Fetched \(documents.count) drivers")
                    
                    let drivers = documents.compactMap { document in
                        try? document.data(as: Driver.self)
                    }
                    // Client-side sorting to avoid index requirement
                    self?.drivers = drivers.sorted { $0.createdAt > $1.createdAt }
                }
            }
    }
    
    // Aktif oturumdaki sürücüyü (telefon numarasına göre) gözlemle
    func observeCurrentDriver(companyId: String, phone: String) {
        currentDriverListener?.remove()
        isLoading = true
        errorMessage = ""
        currentDriver = nil
        
        // Telefon numarasını normalize et
        let normalizedPhone = normalizePhone(phone)
        print("🔍 Sürücü aranıyor - Company: \(companyId), Phone: \(phone) -> Normalized: \(normalizedPhone)")
        
        // Önce normalize edilmiş telefon numarasıyla dene
        currentDriverListener = db.collection("drivers")
            .whereField("companyId", isEqualTo: companyId)
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        let localizedError = self?.errorHandler.getLocalizedErrorMessage(error) ?? "Bir hata oluştu"
                        self?.errorMessage = localizedError
                        self?.showRetryButton = true
                        self?.lastFailedAction = { [weak self] in
                            self?.observeCurrentDriver(companyId: companyId, phone: phone)
                        }
                        print("❌ Current driver observe error: \(error.localizedDescription)")
                        return
                    }
                    
                    // Başarılı olduğunda retry butonunu gizle
                    self?.showRetryButton = false
                    self?.lastFailedAction = nil
                    
                    // Client-side'da telefon numarasına göre filtrele
                    let drivers = snapshot?.documents.compactMap { doc -> Driver? in
                        guard let driver = try? doc.data(as: Driver.self) else { return nil }
                        let driverPhoneNormalized = self?.normalizePhone(driver.phoneNumber) ?? ""
                        return driverPhoneNormalized == normalizedPhone ? driver : nil
                    } ?? []
                    
                    if let driver = drivers.first {
                        self?.currentDriver = driver
                        print("✅ Sürücü bulundu: \(driver.id ?? "nil") - \(driver.fullName)")
                    } else {
                        self?.currentDriver = nil
                        print("⚠️ Sürücü bulunamadı - Normalized phone: \(normalizedPhone)")
                    }
                }
            }
    }
    
    // Telefon numarasını normalize et (boşluk, tire, parantez kaldır)
    private func normalizePhone(_ phone: String) -> String {
        return phone.replacingOccurrences(of: " ", with: "")
                   .replacingOccurrences(of: "-", with: "")
                   .replacingOccurrences(of: "(", with: "")
                   .replacingOccurrences(of: ")", with: "")
                   .replacingOccurrences(of: "+", with: "")
    }
    
    deinit {
        currentDriverListener?.remove()
    }
    
    func addDriver(_ driver: Driver) {
        isLoading = true
        errorMessage = ""
        
        // ID varsa setData kullan, yoksa addDocument kullan (Firestore otomatik ID oluşturur)
        if let driverId = driver.id {
            // Mevcut ID ile kaydet
            do {
                try db.collection("drivers").document(driverId).setData(from: driver) { [weak self] error in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if let error = error {
                            self?.errorMessage = error.localizedDescription
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        } else {
            // Yeni document, Firestore otomatik ID oluşturur
            do {
                _ = try db.collection("drivers").addDocument(from: driver) { [weak self] error in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if let error = error {
                            self?.errorMessage = error.localizedDescription
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func updateDriver(_ driver: Driver) {
        guard let driverId = driver.id else {
            isLoading = false
            errorMessage = "Sürücü ID bulunamadı"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        var updatedDriver = driver
        updatedDriver.updatedAt = Date()
        
        do {
            try db.collection("drivers").document(driverId).setData(from: updatedDriver) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func deleteDriver(_ driver: Driver) {
        guard let driverId = driver.id else {
            isLoading = false
            errorMessage = "Sürücü ID bulunamadı"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        db.collection("drivers").document(driverId).delete { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func toggleDriverStatus(_ driver: Driver) {
        var updatedDriver = driver
        updatedDriver.isActive.toggle()
        updatedDriver.updatedAt = Date()
        
        updateDriver(updatedDriver)
    }
    
    func assignVehicleToDriver(_ driver: Driver, vehicleId: String?) {
        var updatedDriver = driver
        updatedDriver.assignedVehicleId = vehicleId
        updatedDriver.updatedAt = Date()
        
        updateDriver(updatedDriver)
    }
}
