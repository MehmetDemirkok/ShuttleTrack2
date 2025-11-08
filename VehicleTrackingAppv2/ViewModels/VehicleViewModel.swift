import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
class VehicleViewModel: ObservableObject {
    @Published var vehicles: [Vehicle] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var vehiclesListener: ListenerRegistration?
    
    func fetchVehicles(for companyId: String) {
        // Önceki listener'ı temizle
        vehiclesListener?.remove()
        isLoading = true
        errorMessage = ""
        
        // Optimize edilmiş sorgu - sadece gerekli alanları çek
        vehiclesListener = db.collection("vehicles")
            .whereField("companyId", isEqualTo: companyId)
            .limit(to: 50) // Maksimum 50 araç
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        print("❌ Vehicle fetch error: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self?.vehicles = []
                        return
                    }
                    
                    print("🚗 Fetched \(documents.count) vehicles")
                    
                    let vehicles = documents.compactMap { document in
                        try? document.data(as: Vehicle.self)
                    }
                    // Client-side sorting to avoid index requirement
                    let sorted = vehicles.sorted { $0.createdAt > $1.createdAt }
                    self?.vehicles = sorted
                    // Bildirim planlama (izin verilmişse)
                    NotificationService.shared.requestAuthorizationIfNeeded { granted in
                        guard granted else { return }
                        for vehicle in sorted {
                            NotificationService.shared.scheduleVehicleExpiryNotifications(for: vehicle)
                        }
                    }
                }
            }
    }
    
    func addVehicle(_ vehicle: Vehicle) {
        isLoading = true
        errorMessage = ""
        
        // Önce aynı plaka kontrolü yap
        checkPlateNumberExists(plateNumber: vehicle.plateNumber, companyId: vehicle.companyId) { [weak self] exists in
            if exists {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = "Bu plaka numarası zaten kayıtlı: \(vehicle.plateNumber)"
                }
                return
            }
            
            // Plaka yoksa araç ekle
            guard let vehicleId = vehicle.id ?? UUID().uuidString as String? else {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = "Araç ID oluşturulamadı"
                }
                return
            }
            
            do {
                try self?.db.collection("vehicles").document(vehicleId).setData(from: vehicle) { [weak self] error in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if let error = error {
                            self?.errorMessage = error.localizedDescription
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // Plaka numarası kontrolü
    private func checkPlateNumberExists(plateNumber: String, companyId: String, completion: @escaping (Bool) -> Void) {
        db.collection("vehicles")
            .whereField("companyId", isEqualTo: companyId)
            .whereField("plateNumber", isEqualTo: plateNumber)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error checking plate number: \(error)")
                    completion(false)
                    return
                }
                
                let exists = !(snapshot?.documents.isEmpty ?? true)
                completion(exists)
            }
    }
    
    func updateVehicle(_ vehicle: Vehicle) {
        guard let vehicleId = vehicle.id else {
            isLoading = false
            errorMessage = "Araç ID bulunamadı"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        // Düzenleme sırasında plaka kontrolü (kendi ID'si hariç)
        checkPlateNumberExistsForUpdate(plateNumber: vehicle.plateNumber, companyId: vehicle.companyId, excludeId: vehicleId) { [weak self] exists in
            if exists {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = "Bu plaka numarası zaten kayıtlı: \(vehicle.plateNumber)"
                }
                return
            }
            
            // Plaka yoksa araç güncelle
            var updatedVehicle = vehicle
            updatedVehicle.updatedAt = Date()
            
            do {
                try self?.db.collection("vehicles").document(vehicleId).setData(from: updatedVehicle) { [weak self] error in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if let error = error {
                            self?.errorMessage = error.localizedDescription
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // Güncelleme için plaka numarası kontrolü (kendi ID'si hariç)
    private func checkPlateNumberExistsForUpdate(plateNumber: String, companyId: String, excludeId: String?, completion: @escaping (Bool) -> Void) {
        db.collection("vehicles")
            .whereField("companyId", isEqualTo: companyId)
            .whereField("plateNumber", isEqualTo: plateNumber)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error checking plate number for update: \(error)")
                    completion(false)
                    return
                }
                
                // Kendi ID'si hariç aynı plaka var mı kontrol et
                let documents = snapshot?.documents ?? []
                let exists = documents.contains { document in
                    if let excludeId = excludeId {
                        return document.documentID != excludeId
                    }
                    return true // excludeId nil ise tüm eşleşmeleri say
                }
                
                completion(exists)
            }
    }
    
    func deleteVehicle(_ vehicle: Vehicle) {
        guard let vehicleId = vehicle.id else {
            isLoading = false
            errorMessage = "Araç ID bulunamadı"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        db.collection("vehicles").document(vehicleId).delete { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func toggleVehicleStatus(_ vehicle: Vehicle) {
        var updatedVehicle = vehicle
        updatedVehicle.isActive.toggle()
        updatedVehicle.updatedAt = Date()
        
        updateVehicle(updatedVehicle)
    }
    
    deinit {
        vehiclesListener?.remove()
        cancellables.removeAll()
        print("✅ VehicleViewModel temizlendi")
    }
}
