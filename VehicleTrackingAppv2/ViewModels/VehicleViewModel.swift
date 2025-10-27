import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseFirestoreSwift

class VehicleViewModel: ObservableObject {
    @Published var vehicles: [Vehicle] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    func fetchVehicles(for companyId: String) {
        isLoading = true
        errorMessage = ""
        
        // Optimize edilmiş sorgu - sadece gerekli alanları çek
        db.collection("vehicles")
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
                    self?.vehicles = vehicles.sorted { $0.createdAt > $1.createdAt }
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
            do {
                try self?.db.collection("vehicles").document(vehicle.id).setData(from: vehicle) { [weak self] error in
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
        isLoading = true
        errorMessage = ""
        
        // Düzenleme sırasında plaka kontrolü (kendi ID'si hariç)
        checkPlateNumberExistsForUpdate(plateNumber: vehicle.plateNumber, companyId: vehicle.companyId, excludeId: vehicle.id) { [weak self] exists in
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
                try self?.db.collection("vehicles").document(vehicle.id).setData(from: updatedVehicle) { [weak self] error in
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
    private func checkPlateNumberExistsForUpdate(plateNumber: String, companyId: String, excludeId: String, completion: @escaping (Bool) -> Void) {
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
                    document.documentID != excludeId
                }
                
                completion(exists)
            }
    }
    
    func deleteVehicle(_ vehicle: Vehicle) {
        isLoading = true
        errorMessage = ""
        
        db.collection("vehicles").document(vehicle.id).delete { [weak self] error in
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
}
