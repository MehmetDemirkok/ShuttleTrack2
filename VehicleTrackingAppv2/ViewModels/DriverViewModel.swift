import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseFirestoreSwift

class DriverViewModel: ObservableObject {
    @Published var drivers: [Driver] = []
    @Published var currentDriver: Driver?
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let db = Firestore.firestore()
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
                        self?.errorMessage = error.localizedDescription
                        print("❌ Driver fetch error: \(error.localizedDescription)")
                        return
                    }
                    
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
        
        currentDriverListener = db.collection("drivers")
            .whereField("companyId", isEqualTo: companyId)
            .whereField("phoneNumber", isEqualTo: phone)
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        print("❌ Current driver observe error: \(error.localizedDescription)")
                        return
                    }
                    guard let doc = snapshot?.documents.first else {
                        self?.currentDriver = nil
                        return
                    }
                    self?.currentDriver = try? doc.data(as: Driver.self)
                }
            }
    }
    
    deinit {
        currentDriverListener?.remove()
    }
    
    func addDriver(_ driver: Driver) {
        isLoading = true
        errorMessage = ""
        
        do {
            try db.collection("drivers").document(driver.id).setData(from: driver) { [weak self] error in
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
    
    func updateDriver(_ driver: Driver) {
        isLoading = true
        errorMessage = ""
        
        var updatedDriver = driver
        updatedDriver.updatedAt = Date()
        
        do {
            try db.collection("drivers").document(driver.id).setData(from: updatedDriver) { [weak self] error in
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
        isLoading = true
        errorMessage = ""
        
        db.collection("drivers").document(driver.id).delete { [weak self] error in
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
