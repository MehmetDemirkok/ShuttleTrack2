import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseFirestoreSwift

class TripViewModel: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var vehicles: [Vehicle] = []
    @Published var drivers: [Driver] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    func fetchTrips(for companyId: String) {
        isLoading = true
        errorMessage = ""
        
        // Index gerektirmeyen basit sorgu
        db.collection("trips")
            .whereField("companyId", isEqualTo: companyId)
            .limit(to: 50) // Maksimum 50 trip
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        print("❌ Trip fetch error: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self?.trips = []
                        return
                    }
                    
                    print("🚌 Fetched \(documents.count) trips")
                    
                    let trips = documents.compactMap { document in
                        try? document.data(as: Trip.self)
                    }
                    
                    // Client-side filtering - son 30 gün
                    let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                    let filteredTrips = trips.filter { $0.scheduledPickupTime >= thirtyDaysAgo }
                    
                    // Client-side sorting to avoid index requirement
                    self?.trips = filteredTrips.sorted { $0.scheduledPickupTime < $1.scheduledPickupTime }
                }
            }
    }
    
    func fetchVehicles(for companyId: String) {
        db.collection("vehicles")
            .whereField("companyId", isEqualTo: companyId)
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error fetching vehicles: \(error)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self?.vehicles = []
                        return
                    }
                    
                    self?.vehicles = documents.compactMap { document in
                        try? document.data(as: Vehicle.self)
                    }
                }
            }
    }
    
    func fetchDrivers(for companyId: String) {
        db.collection("drivers")
            .whereField("companyId", isEqualTo: companyId)
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error fetching drivers: \(error)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self?.drivers = []
                        return
                    }
                    
                    self?.drivers = documents.compactMap { document in
                        try? document.data(as: Driver.self)
                    }
                }
            }
    }
    
    func addTrip(_ trip: Trip) {
        isLoading = true
        errorMessage = ""
        
        guard let tripId = trip.id else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Trip ID bulunamadı"
            }
            return
        }
        
        do {
            try db.collection("trips").document(tripId).setData(from: trip) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        print("Error adding trip: \(error)")
                    } else {
                        print("Trip added successfully: \(tripId)")
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                print("Error encoding trip: \(error)")
            }
        }
    }
    
    func updateTrip(_ trip: Trip) {
        isLoading = true
        errorMessage = ""
        
        guard let tripId = trip.id else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Trip ID bulunamadı"
            }
            return
        }
        
        var updatedTrip = trip
        updatedTrip.updatedAt = Date()
        
        do {
            try db.collection("trips").document(tripId).setData(from: updatedTrip) { [weak self] error in
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
    
    func deleteTrip(_ trip: Trip) {
        isLoading = true
        errorMessage = ""
        
        guard let tripId = trip.id else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Trip ID bulunamadı"
            }
            return
        }
        
        db.collection("trips").document(tripId).delete { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    print("Error deleting trip: \(error)")
                } else {
                    print("Trip deleted successfully: \(tripId)")
                }
            }
        }
    }
    
    func updateTripStatus(_ trip: Trip, status: Trip.TripStatus) {
        var updatedTrip = trip
        updatedTrip.status = status
        updatedTrip.updatedAt = Date()
        
        updateTrip(updatedTrip)
        print("Trip status updated to: \(status.rawValue) for trip: \(trip.id ?? "unknown")")
    }
    
    func assignTrip(_ trip: Trip, vehicleId: String?, driverId: String?) {
        var updatedTrip = trip
        updatedTrip.vehicleId = vehicleId ?? ""
        updatedTrip.driverId = driverId ?? ""
        updatedTrip.status = (vehicleId != nil && driverId != nil) ? .assigned : .scheduled
        updatedTrip.updatedAt = Date()
        
        updateTrip(updatedTrip)
    }
    
    func getAvailableVehicles() -> [Vehicle] {
        let assignedVehicleIds = trips.compactMap { trip in
            trip.vehicleId.isEmpty ? nil : trip.vehicleId
        }
        return vehicles.filter { !assignedVehicleIds.contains($0.id) }
    }
    
    func getAvailableDrivers() -> [Driver] {
        let assignedDriverIds = trips.compactMap { trip in
            trip.driverId.isEmpty ? nil : trip.driverId
        }
        return drivers.filter { !assignedDriverIds.contains($0.id) }
    }
    
    // Otomatik transfer numarası oluştur
    func generateTripNumber(for companyId: String, completion: @escaping (String) -> Void) {
        // Bugünün tarihini al
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: Date())
        
        // Bugünkü transferleri say
        db.collection("trips")
            .whereField("companyId", isEqualTo: companyId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Transfer sayısı alınırken hata: \(error)")
                    // Hata durumunda basit bir numara oluştur
                    let randomNumber = Int.random(in: 1000...9999)
                    completion("TR-\(dateString)-\(randomNumber)")
                    return
                }
                
                // Bugünkü transferleri filtrele
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
                
                // Main actor'da decode et
                Task { @MainActor in
                    let todaysTrips = snapshot?.documents.compactMap { document in
                        try? document.data(as: Trip.self)
                    }.filter { trip in
                        trip.createdAt >= today && trip.createdAt < tomorrow
                    } ?? []
                    
                    // Sıradaki numara
                    let nextNumber = todaysTrips.count + 1
                    let tripNumber = String(format: "TR-%@-%03d", dateString, nextNumber)
                    
                    print("✅ Yeni transfer numarası oluşturuldu: \(tripNumber)")
                    completion(tripNumber)
                }
            }
    }
}
