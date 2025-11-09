import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
class TripViewModel: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var vehicles: [Vehicle] = []
    @Published var drivers: [Driver] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showRetryButton = false
    @Published var lastFailedAction: (() -> Void)?
    
    private let db = Firestore.firestore()
    private let errorHandler = ErrorHandler.shared
    private let networkMonitor = NetworkMonitor.shared
    private var cancellables = Set<AnyCancellable>()
    private var tripsListener: ListenerRegistration?
    private var vehiclesListener: ListenerRegistration?
    private var driversListener: ListenerRegistration?
    private var isInitialLoad = true
    
    func fetchTrips(for companyId: String) {
        // Önceki listener'ı temizle
        tripsListener?.remove()
        isLoading = true
        errorMessage = ""
        isInitialLoad = true
        
        // Index gerektirmeyen basit sorgu
        tripsListener = db.collection("trips")
            .whereField("companyId", isEqualTo: companyId)
            .limit(to: 50) // Maksimum 50 trip
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    self.isLoading = false
                    
                    if let error = error {
                        let localizedError = self.errorHandler.getLocalizedErrorMessage(error)
                        self.errorMessage = localizedError
                        self.showRetryButton = true
                        self.lastFailedAction = { [weak self] in
                            self?.fetchTrips(for: companyId)
                        }
                        print("❌ Trip fetch error: \(error.localizedDescription)")
                        return
                    }
                    
                    // Başarılı olduğunda retry butonunu gizle
                    self.showRetryButton = false
                    self.lastFailedAction = nil
                    
                    guard let snapshot = snapshot else {
                        self.trips = []
                        return
                    }
                    
                    // İlk yüklemede tüm document'ları al
                    if self.isInitialLoad {
                        self.isInitialLoad = false
                        let documents = snapshot.documents
                        print("🚌 İlk yükleme - Fetched \(documents.count) trips")
                        
                        let trips = documents.compactMap { document in
                            try? document.data(as: Trip.self)
                        }
                        
                        // Client-side filtering - son 30 gün
                        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                        let filteredTrips = trips.filter { $0.scheduledPickupTime >= thirtyDaysAgo }
                        
                        // Client-side sorting
                        self.trips = filteredTrips.sorted { $0.scheduledPickupTime < $1.scheduledPickupTime }
                    } else {
                        // Sonraki güncellemelerde sadece değişiklikleri işle
                        for change in snapshot.documentChanges {
                            switch change.type {
                            case .added:
                                if let trip = try? change.document.data(as: Trip.self) {
                                    // Yeni trip ekle (eğer yoksa)
                                    if !self.trips.contains(where: { $0.id == trip.id }) {
                                        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                                        if trip.scheduledPickupTime >= thirtyDaysAgo {
                                            self.trips.append(trip)
                                            print("➕ Yeni trip eklendi: \(trip.tripNumber) - ID: \(trip.id ?? "nil")")
                                        } else {
                                            print("⏭️ Trip filtrelendi (30 günden eski): \(trip.tripNumber)")
                                        }
                                    } else {
                                        print("⚠️ Trip zaten listede var, eklenmedi: \(trip.tripNumber) - ID: \(trip.id ?? "nil")")
                                    }
                                }
                            case .modified:
                                if let trip = try? change.document.data(as: Trip.self),
                                   let index = self.trips.firstIndex(where: { $0.id == trip.id }) {
                                    // Mevcut trip'i güncelle
                                    self.trips[index] = trip
                                    print("🔄 Trip güncellendi: \(trip.tripNumber)")
                                }
                            case .removed:
                                // Silinen trip'i listeden kaldır
                                let deletedId = change.document.documentID
                                let removedCount = self.trips.count
                                self.trips.removeAll { $0.id == deletedId }
                                if removedCount > self.trips.count {
                                    print("🗑️ Trip listener'dan kaldırıldı: \(deletedId)")
                                } else {
                                    print("⚠️ Trip listener'da bulunamadı (zaten kaldırılmış olabilir): \(deletedId)")
                                }
                            }
                        }
                        
                        // Client-side filtering - son 30 gün
                        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                        self.trips = self.trips.filter { $0.scheduledPickupTime >= thirtyDaysAgo }
                        
                        // Client-side sorting
                        self.trips.sort { $0.scheduledPickupTime < $1.scheduledPickupTime }
                    }
                }
            }
    }
    
    // Sürücüye özel: sadece o sürücünün işleri (assigned/in_progress)
    func fetchTripsForDriver(companyId: String, driverId: String) {
        // Önceki listener'ı temizle
        tripsListener?.remove()
        
        isLoading = true
        errorMessage = ""
        
        tripsListener = db.collection("trips")
            .whereField("companyId", isEqualTo: companyId)
            .whereField("driverId", isEqualTo: driverId)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        let localizedError = self?.errorHandler.getLocalizedErrorMessage(error) ?? "Bir hata oluştu"
                        self?.errorMessage = localizedError
                        self?.showRetryButton = true
                        self?.lastFailedAction = { [weak self] in
                            self?.fetchTripsForDriver(companyId: companyId, driverId: driverId)
                        }
                        print("❌ Trip fetch (driver) error: \(error.localizedDescription)")
                        return
                    }
                    
                    // Başarılı olduğunda retry butonunu gizle
                    self?.showRetryButton = false
                    self?.lastFailedAction = nil
                    guard let documents = snapshot?.documents else {
                        self?.trips = []
                        return
                    }
                    let trips = documents.compactMap { try? $0.data(as: Trip.self) }
                    // Sadece ilgili durumlar
                    let filtered = trips.filter { $0.status == .assigned || $0.status == .inProgress }
                    self?.trips = filtered.sorted { $0.scheduledPickupTime < $1.scheduledPickupTime }
                }
            }
    }
    
    func fetchVehicles(for companyId: String) {
        // Önceki listener'ı temizle
        vehiclesListener?.remove()
        
        vehiclesListener = db.collection("vehicles")
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
        // Önceki listener'ı temizle
        driversListener?.remove()
        
        driversListener = db.collection("drivers")
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
        // Network kontrolü
        guard networkMonitor.isConnected else {
            errorMessage = "İnternet bağlantınız yok. Lütfen bağlantınızı kontrol edin."
            showRetryButton = true
            lastFailedAction = { [weak self] in
                self?.addTrip(trip)
            }
            return
        }
        
        isLoading = true
        errorMessage = ""
        showRetryButton = false
        
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
                        let localizedError = self?.errorHandler.getLocalizedErrorMessage(error) ?? "Bir hata oluştu"
                        self?.errorMessage = localizedError
                        self?.showRetryButton = true
                        self?.lastFailedAction = { [weak self] in
                            self?.addTrip(trip)
                        }
                        print("Error adding trip: \(error)")
                    } else {
                        self?.showRetryButton = false
                        self?.lastFailedAction = nil
                        print("Trip added successfully: \(tripId)")
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                let localizedError = self.errorHandler.getLocalizedErrorMessage(error)
                self.errorMessage = localizedError
                self.showRetryButton = true
                self.lastFailedAction = { [weak self] in
                    self?.addTrip(trip)
                }
                print("Error encoding trip: \(error)")
            }
        }
    }
    
    func updateTrip(_ trip: Trip) {
        // Network kontrolü
        guard networkMonitor.isConnected else {
            errorMessage = "İnternet bağlantınız yok. Lütfen bağlantınızı kontrol edin."
            showRetryButton = true
            lastFailedAction = { [weak self] in
                self?.updateTrip(trip)
            }
            return
        }
        
        isLoading = true
        errorMessage = ""
        showRetryButton = false
        
        guard let tripId = trip.id else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Trip ID bulunamadı"
            }
            return
        }
        
        var updatedTrip = trip
        updatedTrip.updatedAt = Date()
        
        // Sadece güncellenebilir alanları gönder (sürücü için)
        // Admin için tüm alanları gönderebiliriz
        do {
            try db.collection("trips").document(tripId).setData(from: updatedTrip, merge: true) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        let localizedError = self?.errorHandler.getLocalizedErrorMessage(error) ?? "Bir hata oluştu"
                        self?.errorMessage = localizedError
                        self?.showRetryButton = true
                        self?.lastFailedAction = { [weak self] in
                            self?.updateTrip(trip)
                        }
                        print("❌ Trip update error: \(error.localizedDescription)")
                    } else {
                        self?.showRetryButton = false
                        self?.lastFailedAction = nil
                        print("✅ Trip updated successfully: \(tripId)")
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                let localizedError = self.errorHandler.getLocalizedErrorMessage(error)
                self.errorMessage = localizedError
                self.showRetryButton = true
                self.lastFailedAction = { [weak self] in
                    self?.updateTrip(trip)
                }
                print("❌ Trip update encoding error: \(error.localizedDescription)")
            }
        }
    }
    
    func deleteTrip(_ trip: Trip) {
        isLoading = true
        errorMessage = ""
        
        guard let tripId = trip.id else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "İş ID bulunamadı"
            }
            return
        }
        
        print("🗑️ Silme işlemi başlatıldı - Trip ID: \(tripId), Trip Number: \(trip.tripNumber)")
        
        // Silmeden önce trip'i sakla (hata durumunda geri eklemek için)
        let tripToRestore = trip
        
        // Önce local'den kaldır (optimistic update)
        if let index = trips.firstIndex(where: { $0.id == tripId }) {
            trips.remove(at: index)
            print("🗑️ Trip local listeden kaldırıldı: \(tripId)")
        }
        
        // Firestore'dan sil
        db.collection("trips").document(tripId).delete { [weak self] error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    let nsError = error as NSError
                    print("❌ Delete error - Domain: \(nsError.domain), Code: \(nsError.code), Description: \(error.localizedDescription)")
                    
                    // Firestore not-found hatası (code 7) - document zaten silinmiş olabilir
                    if nsError.domain == "FIRFirestoreErrorDomain" && nsError.code == 7 {
                        // Document zaten silinmiş, bu başarılı
                        print("✅ Trip zaten silinmiş (not-found): \(tripId)")
                        self.errorMessage = ""
                        self.showRetryButton = false
                        self.lastFailedAction = nil
                    } else if nsError.domain == "FIRFirestoreErrorDomain" && nsError.code == 9 {
                        // Permission denied - yetki hatası
                        let localizedError = "Bu işi silmek için yetkiniz bulunmamaktadır. Lütfen yöneticinizle iletişime geçin."
                        self.errorMessage = localizedError
                        self.showRetryButton = false
                        self.lastFailedAction = nil
                        
                        // Trip'i geri ekle
                        if !self.trips.contains(where: { $0.id == tripId }) {
                            self.trips.append(tripToRestore)
                            self.trips.sort { $0.scheduledPickupTime < $1.scheduledPickupTime }
                            print("⚠️ Yetki hatası, trip geri eklendi: \(tripId)")
                        }
                        print("❌ Permission denied - Silme yetkisi yok: \(tripId)")
                    } else {
                        // Diğer hatalar - trip'i geri ekle
                        if !self.trips.contains(where: { $0.id == tripId }) {
                            self.trips.append(tripToRestore)
                            self.trips.sort { $0.scheduledPickupTime < $1.scheduledPickupTime }
                            print("⚠️ Silme başarısız, trip geri eklendi: \(tripId)")
                        }
                        
                        let localizedError = self.errorHandler.getLocalizedErrorMessage(error)
                        self.errorMessage = localizedError
                        self.showRetryButton = true
                        self.lastFailedAction = { [weak self] in
                            self?.deleteTrip(tripToRestore)
                        }
                        print("❌ Error deleting trip: \(error.localizedDescription)")
                    }
                } else {
                    // Silme işlemi başarılı
                    self.errorMessage = ""
                    self.showRetryButton = false
                    self.lastFailedAction = nil
                    print("✅ Trip başarıyla Firestore'dan silindi: \(tripId)")
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
    
    // Sürücü: Yolculuğu başlat (pickup gerçekleşti)
    func startTrip(_ trip: Trip) {
        var updatedTrip = trip
        updatedTrip.status = .inProgress
        if updatedTrip.actualPickupTime == nil {
            updatedTrip.actualPickupTime = Date()
        }
        updatedTrip.updatedAt = Date()
        updateTrip(updatedTrip)
        print("✅ Trip started: \(trip.id ?? "unknown")")
    }
    
    // Sürücü: Yolculuğu tamamla (dropoff gerçekleşti)
    func completeTrip(_ trip: Trip) {
        var updatedTrip = trip
        updatedTrip.status = .completed
        if updatedTrip.actualDropoffTime == nil {
            updatedTrip.actualDropoffTime = Date()
        }
        updatedTrip.updatedAt = Date()
        updateTrip(updatedTrip)
        print("✅ Trip completed: \(trip.id ?? "unknown")")
    }
    
    func assignTrip(_ trip: Trip, vehicleId: String?, driverId: String?) {
        let previousDriverId = trip.driverId
        var updatedTrip = trip
        updatedTrip.vehicleId = vehicleId ?? ""
        updatedTrip.driverId = driverId ?? ""
        updatedTrip.status = (vehicleId != nil && driverId != nil) ? .assigned : .scheduled
        updatedTrip.updatedAt = Date()
        
        updateTrip(updatedTrip)
        
        // Yeni sürücüye bildirim gönder
        if let newDriverId = driverId, 
           !newDriverId.isEmpty,
           newDriverId != previousDriverId {
            Task { @MainActor in
                await DriverNotificationService.shared.sendTripAssignedNotification(
                    to: newDriverId,
                    companyId: updatedTrip.companyId,
                    trip: updatedTrip
                )
            }
        }
    }
    
    func getAvailableVehicles() -> [Vehicle] {
        let assignedVehicleIds = trips.compactMap { trip in
            trip.vehicleId.isEmpty ? nil : trip.vehicleId
        }
        return vehicles.filter { vehicle in
            guard let vehicleId = vehicle.id else { return false }
            return !assignedVehicleIds.contains(vehicleId)
        }
    }
    
    func getAvailableDrivers() -> [Driver] {
        let assignedDriverIds = trips.compactMap { trip in
            trip.driverId.isEmpty ? nil : trip.driverId
        }
        return drivers.filter { driver in
            guard let driverId = driver.id else { return false }
            return !assignedDriverIds.contains(driverId)
        }
    }
    
    // Sürücüye ait işleri getir
    func getTrips(forDriverId driverId: String, statuses: [Trip.TripStatus]? = nil) -> [Trip] {
        let filtered = trips.filter { $0.driverId == driverId }
        guard let statuses = statuses, !statuses.isEmpty else {
            return filtered
        }
        return filtered.filter { statuses.contains($0.status) }
    }
    
    // Atanmamış işleri getir (sürücüye atama için)
    func getUnassignedTrips() -> [Trip] {
        return trips.filter { trip in
            // Sadece scheduled durumunda ve driverId boş olan işler
            trip.status == .scheduled && trip.driverId.isEmpty
        }
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
    
    deinit {
        tripsListener?.remove()
        vehiclesListener?.remove()
        driversListener?.remove()
        cancellables.removeAll()
        print("✅ TripViewModel temizlendi")
    }
}
