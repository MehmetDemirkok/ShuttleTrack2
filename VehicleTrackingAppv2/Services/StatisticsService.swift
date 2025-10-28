import Foundation
import FirebaseFirestore
import Combine
import FirebaseFirestoreSwift

@MainActor
class StatisticsService: ObservableObject {
    @Published var totalVehicles = 0
    @Published var activeDrivers = 0
    @Published var todaysTrips = 0
    @Published var completedTrips = 0
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var listeners: [ListenerRegistration] = []
    
    func fetchStatistics(for companyId: String) {
        print("📊 İstatistikler yükleniyor - Company ID: \(companyId)")
        isLoading = true
        errorMessage = ""
        
        // Önceki listener'ları temizle
        stopRealTimeUpdates()
        
        // Real-time listener'lar kur
        setupVehicleListener(for: companyId)
        setupDriverListener(for: companyId)
        setupTodaysTripsListener(for: companyId)
        setupCompletedTripsListener(for: companyId)
        
        // İlk yüklemeden sonra loading'i kapat
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isLoading = false
        }
    }
    
    private func setupVehicleListener(for companyId: String) {
        print("🚗 Araç listener kuruluyor - Company ID: \(companyId)")
        let listener = db.collection("vehicles")
            .whereField("companyId", isEqualTo: companyId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Araç sayısı yüklenirken hata: \(error.localizedDescription)")
                        self.errorMessage = "Araç verileri yüklenemedi: \(error.localizedDescription)"
                        return
                    }
                    
                    let count = snapshot?.documents.count ?? 0
                    print("🚗 Araç sayısı güncellendi: \(count)")
                    self.totalVehicles = count
                }
            }
        listeners.append(listener)
        print("✅ Araç listener eklendi - Toplam listener: \(listeners.count)")
    }
    
    private func setupDriverListener(for companyId: String) {
        print("👨‍💼 Sürücü listener kuruluyor - Company ID: \(companyId)")
        let listener = db.collection("drivers")
            .whereField("companyId", isEqualTo: companyId)
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Aktif sürücü sayısı yüklenirken hata: \(error.localizedDescription)")
                        return
                    }
                    
                    let count = snapshot?.documents.count ?? 0
                    print("👨‍💼 Aktif sürücü sayısı güncellendi: \(count)")
                    self.activeDrivers = count
                }
            }
        listeners.append(listener)
        print("✅ Sürücü listener eklendi - Toplam listener: \(listeners.count)")
    }
    
    private func setupTodaysTripsListener(for companyId: String) {
        print("📅 Bugünkü işler listener kuruluyor - Company ID: \(companyId)")
        let listener = db.collection("trips")
            .whereField("companyId", isEqualTo: companyId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Bugünkü işler yüklenirken hata: \(error.localizedDescription)")
                        return
                    }
                    
                    let calendar = Calendar.current
                    let today = calendar.startOfDay(for: Date())
                    let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
                    
                    let allTrips = snapshot?.documents.compactMap { document in
                        try? document.data(as: Trip.self)
                    } ?? []
                    
                    let todaysTrips = allTrips.filter { trip in
                        trip.scheduledPickupTime >= today && trip.scheduledPickupTime < tomorrow
                    }.count
                    
                    print("📅 Bugünkü işler sayısı güncellendi: \(todaysTrips)")
                    self.todaysTrips = todaysTrips
                }
            }
        listeners.append(listener)
        print("✅ Bugünkü işler listener eklendi - Toplam listener: \(listeners.count)")
    }
    
    private func setupCompletedTripsListener(for companyId: String) {
        print("✅ Tamamlanan işler listener kuruluyor - Company ID: \(companyId)")
        let listener = db.collection("trips")
            .whereField("companyId", isEqualTo: companyId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Tamamlanan işler yüklenirken hata: \(error.localizedDescription)")
                        return
                    }
                    
                    let allTrips = snapshot?.documents.compactMap { document in
                        try? document.data(as: Trip.self)
                    } ?? []
                    
                    let completedTrips = allTrips.filter { trip in
                        trip.status == .completed
                    }.count
                    
                    print("✅ Tamamlanan işler sayısı güncellendi: \(completedTrips)")
                    self.completedTrips = completedTrips
                }
            }
        listeners.append(listener)
        print("✅ Tamamlanan işler listener eklendi - Toplam listener: \(listeners.count)")
    }
    
    // Real-time istatistik güncellemeleri için listener'lar
    func startRealTimeUpdates(for companyId: String) {
        print("🔄 Real-time istatistik güncellemeleri başlatılıyor - Company ID: \(companyId)")
        
        // Önceki listener'ları temizle
        stopRealTimeUpdates()
        
        // Araç sayısı listener
        let vehicleListener = db.collection("vehicles")
            .whereField("companyId", isEqualTo: companyId)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Error listening to vehicles: \(error)")
                        self?.errorMessage = "Araç verileri güncellenemedi: \(error.localizedDescription)"
                        return
                    }
                    let count = snapshot?.documents.count ?? 0
                    print("🚗 Real-time araç sayısı güncellendi: \(count)")
                    self?.totalVehicles = count
                }
            }
        listeners.append(vehicleListener)
        
        // Aktif sürücü sayısı listener
        let driverListener = db.collection("drivers")
            .whereField("companyId", isEqualTo: companyId)
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Error listening to active drivers: \(error)")
                        self?.errorMessage = "Sürücü verileri güncellenemedi: \(error.localizedDescription)"
                        return
                    }
                    let count = snapshot?.documents.count ?? 0
                    print("👨‍💼 Real-time aktif sürücü sayısı güncellendi: \(count)")
                    self?.activeDrivers = count
                }
            }
        listeners.append(driverListener)
        
        // Bugünkü işler listener - Company ID filtresi eklendi
        let todaysTripsListener = db.collection("trips")
            .whereField("companyId", isEqualTo: companyId)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Error listening to today's trips: \(error)")
                        self?.errorMessage = "Bugünkü işler güncellenemedi: \(error.localizedDescription)"
                        return
                    }
                    
                    let calendar = Calendar.current
                    let today = calendar.startOfDay(for: Date())
                    let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
                    
                    let todaysTrips = snapshot?.documents.compactMap { document in
                        try? document.data(as: Trip.self)
                    }.filter { trip in
                        trip.scheduledPickupTime >= today && trip.scheduledPickupTime < tomorrow
                    }.count ?? 0
                    
                    print("📅 Real-time bugünkü işler güncellendi: \(todaysTrips)")
                    self?.todaysTrips = todaysTrips
                }
            }
        listeners.append(todaysTripsListener)
        
        // Tamamlanan işler listener
        let completedTripsListener = db.collection("trips")
            .whereField("companyId", isEqualTo: companyId)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Error listening to completed trips: \(error)")
                        self?.errorMessage = "Tamamlanan işler güncellenemedi: \(error.localizedDescription)"
                        return
                    }
                    
                    let completedTrips = snapshot?.documents.compactMap { document in
                        try? document.data(as: Trip.self)
                    }.filter { trip in
                        trip.status == .completed
                    }.count ?? 0
                    
                    print("✅ Real-time tamamlanan işler güncellendi: \(completedTrips)")
                    self?.completedTrips = completedTrips
                }
            }
        listeners.append(completedTripsListener)
        
        print("✅ Real-time listener'lar başlatıldı - Toplam: \(listeners.count)")
    }
    
    func stopRealTimeUpdates() {
        print("🛑 Real-time listener'lar durduruluyor...")
        // Listener'ları durdur
        for listener in listeners {
            listener.remove()
        }
        listeners.removeAll()
        cancellables.removeAll()
        print("✅ Real-time listener'lar durduruldu")
    }
    
    // İstatistikleri manuel olarak yenile
    func refreshStatistics(for companyId: String) {
        print("🔄 İstatistikler yenileniyor...")
        fetchStatistics(for: companyId)
    }
    
    // Hata mesajını temizle
    func clearError() {
        errorMessage = ""
    }
    
    // Deinitializer - Memory leak önleme
    deinit {
        print("🛑 StatisticsService deinit çağrıldı")
        // Listener'ları direkt durdur (Task kullanmadan)
        for listener in listeners {
            listener.remove()
        }
        listeners.removeAll()
        cancellables.removeAll()
        print("✅ StatisticsService temizlendi")
    }
}
