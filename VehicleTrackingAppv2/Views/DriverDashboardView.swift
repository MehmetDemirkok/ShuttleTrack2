import SwiftUI
import FirebaseAuth

struct DriverDashboardView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var tripViewModel = TripViewModel()
    @StateObject private var driverViewModel = DriverViewModel()
    @StateObject private var vehicleViewModel = VehicleViewModel()
    
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var showProfile = false
    @State private var showLogoutConfirm = false
    @State private var showStartTripConfirmation = false
    @State private var showCompleteTripConfirmation = false
    @State private var showCancelTripConfirmation = false
    @State private var selectedTripForAction: Trip? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                if appViewModel.currentCompany?.id == nil {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Şirket yükleniyor...")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Veriler yükleniyor...")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !errorMessage.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.largeTitle)
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        // Başlık ve özet
                        Section {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(greetingTitle())
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                                Text("Atanan İşler")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(ShuttleTrackTheme.Colors.tertiaryText)
                                HStack(spacing: 12) {
                                    StatPill(title: "Bugün", value: "\(todayTrips().count)", color: .blue)
                                    StatPill(title: "Devam", value: "\(inProgressTrips().count)", color: .green)
                                    StatPill(title: "Bekleyen", value: "\(assignedTrips().count)", color: .orange)
                                    StatPill(title: "Tamamlanan", value: "\(completedTrips().count)", color: .purple)
                                }
                                .padding(.top, 4)
                            }
                            .listRowBackground(Color.clear)
                        }
                        .listRowSeparator(.hidden)
                        
                        // Bildirimler ve Uyarılar
                        if !notifications().isEmpty {
                            Section(header: Text("Bildirimler")) {
                                ForEach(notifications(), id: \.self) { note in
                                    Text(note)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.vertical, 4)
                                }
                            }
                        }
                        
                        // Araç Bilgileri
                        if let vehicle = assignedVehicle() {
                            Section(header: Text("Araç Bilgileri")) {
                                ShuttleTrackCard {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Image(systemName: "car.fill")
                                                .foregroundColor(ShuttleTrackTheme.Colors.vehicleIcon)
                                            Text(vehicle.displayName)
                                                .font(.headline)
                                        }
                                        HStack(spacing: 12) {
                                            InfoChip(icon: "number", text: vehicle.plateNumber)
                                            InfoChip(icon: "person.3.fill", text: "\(vehicle.capacity) kişilik")
                                            InfoChip(icon: "paintpalette.fill", text: vehicle.color)
                                        }
                                        .padding(.top, 4)
                                        HStack(spacing: 12) {
                                            StatusChip(icon: "shield.fill", text: "Sigorta: \(vehicle.insuranceStatus)", color: vehicle.insuranceStatusColor)
                                            StatusChip(icon: "wrench.and.screwdriver.fill", text: "Muayene: \(vehicle.inspectionStatus)", color: vehicle.inspectionStatusColor)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Atanan İşler
                        Section(header: Text("Atanan İşler")) {
                            ForEach(getAssignedTrips()) { trip in
                                DriverTripCard(
                                    trip: trip,
                                    onStart: {
                                        showStartTripConfirmation = true
                                        selectedTripForAction = trip
                                    },
                                    onComplete: {
                                        showCompleteTripConfirmation = true
                                        selectedTripForAction = trip
                                    },
                                    onCancel: {
                                        showCancelTripConfirmation = true
                                        selectedTripForAction = trip
                                    }
                                )
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Sürücü Paneli")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        showProfile = true
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                    Button(role: .destructive) {
                        showLogoutConfirm = true
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
        }
        .onAppear {
            loadData()
        }
        .onChange(of: appViewModel.currentCompany?.id) { oldValue, newValue in
            if newValue != nil {
                loadData()
            }
        }
        .onChange(of: driverViewModel.currentDriver?.id) { oldValue, newValue in
            // Sürücü bilgisi yüklendiğinde işleri yeniden yükle
            if newValue != nil {
                print("✅ CurrentDriver yüklendi: \(newValue ?? "nil")")
                guard let companyId = appViewModel.currentCompany?.id else { return }
                tripViewModel.fetchTrips(for: companyId)
            }
        }
        .onChange(of: driverViewModel.drivers.count) { oldValue, newValue in
            // Drivers listesi yüklendiğinde işleri yeniden yükle
            if newValue > 0 {
                print("✅ Drivers listesi yüklendi: \(newValue) sürücü")
            }
        }
        .sheet(isPresented: $showProfile) {
            ProfileView().environmentObject(appViewModel)
        }
        .alert("Çıkış Yap", isPresented: $showLogoutConfirm) {
            Button("İptal", role: .cancel) { }
            Button("Çıkış Yap", role: .destructive) { appViewModel.signOut() }
        } message: {
            Text("Hesabınızdan çıkmak istediğinizden emin misiniz?")
        }
        .alert("Yola Çık", isPresented: $showStartTripConfirmation) {
            Button("İptal", role: .cancel) { 
                selectedTripForAction = nil
            }
            Button("Yola Çık", role: .none) {
                if let trip = selectedTripForAction {
                    print("🚀 Yola çık butonu tıklandı - Trip: \(trip.tripNumber), ID: \(trip.id ?? "nil")")
                    tripViewModel.startTrip(trip)
                }
                selectedTripForAction = nil
            }
        } message: {
            if let trip = selectedTripForAction {
                Text("\(trip.tripNumber) numaralı işe yola çıkmak istediğinizden emin misiniz?")
            }
        }
        .alert("Teslim Et", isPresented: $showCompleteTripConfirmation) {
            Button("İptal", role: .cancel) { 
                selectedTripForAction = nil
            }
            Button("Teslim Et", role: .none) {
                if let trip = selectedTripForAction {
                    print("✅ Teslim et butonu tıklandı - Trip: \(trip.tripNumber), ID: \(trip.id ?? "nil")")
                    tripViewModel.completeTrip(trip)
                }
                selectedTripForAction = nil
            }
        } message: {
            if let trip = selectedTripForAction {
                Text("\(trip.tripNumber) numaralı işi tamamladınız mı?")
            }
        }
        .alert("İşi İptal Et", isPresented: $showCancelTripConfirmation) {
            Button("İptal Etme", role: .cancel) { 
                selectedTripForAction = nil
            }
            Button("İptal Et", role: .destructive) {
                if let trip = selectedTripForAction {
                    print("❌ İptal butonu tıklandı - Trip: \(trip.tripNumber), ID: \(trip.id ?? "nil")")
                    tripViewModel.updateTripStatus(trip, status: .cancelled)
                }
                selectedTripForAction = nil
            }
        } message: {
            if let trip = selectedTripForAction {
                Text("\(trip.tripNumber) numaralı işi iptal etmek istediğinizden emin misiniz?")
            }
        }
        .onChange(of: tripViewModel.errorMessage) { oldValue, newValue in
            if !newValue.isEmpty {
                print("❌ TripViewModel error: \(newValue)")
            }
        }
    }
    
    private func loadData() {
        guard let companyId = appViewModel.currentCompany?.id else { return }
        isLoading = true
        tripViewModel.fetchTrips(for: companyId)
        vehicleViewModel.fetchVehicles(for: companyId)
        
        // Hem observeCurrentDriver hem de fetchDrivers çağır
        // observeCurrentDriver telefon numarasına göre bulur
        // fetchDrivers tüm sürücüleri getirir (fallback için)
        driverViewModel.fetchDrivers(for: companyId)
        
        if let phone = appViewModel.currentUserProfile?.phone {
            print("📞 Sürücü telefon numarası: \(phone)")
            driverViewModel.observeCurrentDriver(companyId: companyId, phone: phone)
        } else {
            print("⚠️ UserProfile'da telefon numarası bulunamadı")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isLoading = false
        }
    }
    
    private func getAssignedTrips() -> [Trip] {
        // Sürücü ID'sini al (Driver modelindeki id)
        // Önce currentDriver'dan al, yoksa drivers listesinden telefon numarasına göre bul
        var driverId: String?
        
        if let currentDriverId = driverViewModel.currentDriver?.id {
            driverId = currentDriverId
        } else if let phone = appViewModel.currentUserProfile?.phone,
                  let driver = driverViewModel.drivers.first(where: { 
                      normalizePhone($0.phoneNumber) == normalizePhone(phone) 
                  }) {
            driverId = driver.id
            print("✅ Sürücü drivers listesinden bulundu: \(driver.id)")
        }
        
        guard let driverId = driverId else {
            print("⚠️ Sürücü ID bulunamadı - currentDriver: \(driverViewModel.currentDriver?.id ?? "nil"), drivers count: \(driverViewModel.drivers.count)")
            return []
        }
        
        print("🔍 Sürücü ID: \(driverId) - Toplam iş sayısı: \(tripViewModel.trips.count)")
        
        // Bu sürücüye atanan tüm işleri getir (scheduled, assigned, inProgress, completed)
        let assignedTrips = tripViewModel.trips.filter { trip in
            trip.driverId == driverId && 
            (trip.status == .scheduled || trip.status == .assigned || trip.status == .inProgress || trip.status == .completed)
        }
        
        print("✅ Sürücüye atanan iş sayısı: \(assignedTrips.count)")
        for trip in assignedTrips {
            print("  - \(trip.tripNumber) - \(trip.statusText)")
        }
        
        return assignedTrips
    }
    
    // Telefon numarasını normalize et (boşluk, tire, parantez kaldır)
    private func normalizePhone(_ phone: String) -> String {
        return phone.replacingOccurrences(of: " ", with: "")
                   .replacingOccurrences(of: "-", with: "")
                   .replacingOccurrences(of: "(", with: "")
                   .replacingOccurrences(of: ")", with: "")
                   .replacingOccurrences(of: "+", with: "")
    }
    
    private func assignedVehicle() -> Vehicle? {
        // Önce currentDriver'dan al, yoksa drivers listesinden telefon numarasına göre bul
        var assignedVehicleId: String?
        
        if let currentDriverVehicleId = driverViewModel.currentDriver?.assignedVehicleId {
            assignedVehicleId = currentDriverVehicleId
        } else if let phone = appViewModel.currentUserProfile?.phone,
                  let driver = driverViewModel.drivers.first(where: { 
                      normalizePhone($0.phoneNumber) == normalizePhone(phone) 
                  }) {
            assignedVehicleId = driver.assignedVehicleId
        }
        
        guard let assignedId = assignedVehicleId else { return nil }
        return vehicleViewModel.vehicles.first(where: { $0.id == assignedId })
    }
    
    private func notifications() -> [String] {
        var items: [String] = []
        let assignedTrips = getAssignedTrips()
        // Yaklaşan işler
        let upcoming = assignedTrips.filter { $0.isUpcoming }
        if !upcoming.isEmpty {
            items.append("Yaklaşan \(upcoming.count) işiniz var (1 saat içinde)")
        }
        // Geciken işler
        let overdue = assignedTrips.filter { $0.isOverdue && $0.status != .completed && $0.status != .cancelled }
        if !overdue.isEmpty {
            items.append("Gecikmiş \(overdue.count) işiniz var")
        }
        // Araç uyarıları
        if let vehicle = assignedVehicle() {
            if vehicle.daysUntilInsuranceExpiry <= 30 {
                items.append("Sigorta: \(vehicle.insuranceStatus)")
            }
            if vehicle.daysUntilInspectionExpiry <= 30 {
                items.append("Muayene: \(vehicle.inspectionStatus)")
            }
        }
        return items
    }

    private func greetingTitle() -> String {
        let name = appViewModel.currentUserProfile?.fullName.isEmpty == false ? (appViewModel.currentUserProfile?.fullName ?? "") : "Sürücü"
        return "Merhaba, \(name)"
    }
    private func todayTrips() -> [Trip] {
        let cal = Calendar.current
        return getAssignedTrips().filter { cal.isDateInToday($0.scheduledPickupTime) }
    }
    private func inProgressTrips() -> [Trip] { 
        getAssignedTrips().filter { $0.status == .inProgress } 
    }
    private func assignedTrips() -> [Trip] { 
        getAssignedTrips().filter { $0.status == .assigned } 
    }
    private func completedTrips() -> [Trip] { 
        getAssignedTrips().filter { $0.status == .completed } 
    }
}

// MARK: - Driver Trip Card (Geliştirilmiş)
struct DriverTripCard: View {
    let trip: Trip
    let onStart: () -> Void
    let onComplete: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header - İş Numarası ve Durum
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.tripNumber)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    // Kategori badge
                    if let category = trip.category {
                        Text(category.titleText)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                // Durum badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(trip.statusColor)
                        .frame(width: 8, height: 8)
                    Text(trip.statusText)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(trip.statusColor)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(trip.statusColor.opacity(0.1))
                .cornerRadius(12)
            }
            
            Divider()
            
            // Lokasyon Bilgileri
            VStack(alignment: .leading, spacing: 8) {
                // Alış Noktası
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Alış")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(trip.pickupLocation.name)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
                
                // Ok işareti
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 2, height: 12)
                        .padding(.leading, 6)
                }
                
                // Bırakış Noktası
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bırakış")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(trip.dropoffLocation.name)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
            }
            
            Divider()
            
            // Detay Bilgileri
            HStack(spacing: 16) {
                // Tarih/Saat
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Alış Saati")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(formatTime(trip.scheduledPickupTime))
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
                
                // Yolcu Sayısı
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Yolcu")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(trip.passengerCount)")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
                
                // Ücret (varsa)
                if let fare = trip.fare {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "turkishlirasign.circle.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ücret")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(formatCurrency(fare))
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            
            // Gerçekleşen Zamanlar (varsa)
            if let actualPickup = trip.actualPickupTime {
                Divider()
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("Yola çıkış: \(formatDateTime(actualPickup))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let actualDropoff = trip.actualDropoffTime {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text("Teslim: \(formatDateTime(actualDropoff))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Aksiyon Butonları
            if trip.status != .completed && trip.status != .cancelled {
                Divider()
                HStack(spacing: 8) {
                    // Yola Çık butonu (sadece assigned durumunda)
                    if trip.status == .assigned {
                        Button(action: onStart) {
                            HStack(spacing: 6) {
                                Image(systemName: "play.circle.fill")
                                    .font(.caption)
                                Text("Yola Çık")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.green)
                            .cornerRadius(10)
                        }
                    }
                    
                    // Teslim Et butonu (sadece inProgress durumunda)
                    if trip.status == .inProgress {
                        Button(action: onComplete) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                Text("Teslim Et")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                    }
                    
                    Spacer()
                    
                    // İptal butonu (assigned veya inProgress durumunda)
                    if trip.status == .assigned || trip.status == .inProgress {
                        Button(action: onCancel) {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                Text("İptal")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.red)
                            .cornerRadius(10)
                        }
                    }
                }
            } else if trip.status == .completed {
                // Tamamlanan iş için bilgi göster
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("İş tamamlandı")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            } else if trip.status == .cancelled {
                // İptal edilen iş için bilgi göster
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    Text("İş iptal edildi")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(trip.statusColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: NSNumber(value: amount)) ?? String(format: "₺%.0f", amount)
    }
}

// MARK: - Driver Trip Row (Eski - Geriye dönük uyumluluk için)
struct DriverTripRow: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(trip.tripNumber)
                    .font(.headline)
                Spacer()
                Text(trip.statusText)
                    .font(.caption)
                    .foregroundColor(trip.statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(trip.statusColor.opacity(0.1))
                    .cornerRadius(8)
            }
            
            HStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.blue)
                Text(trip.pickupLocation.name)
                    .font(.subheadline)
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                Text(trip.dropoffLocation.name)
                    .font(.subheadline)
            }
            .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Label(trip.scheduledPickupTime, systemImage: "clock")
                    .font(.caption)
                Spacer()
                Label("\(trip.passengerCount)", systemImage: "person.2.fill")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
    }
}

// Yardımcı küçük bileşenler
struct StatPill: View {
    let title: String
    let value: String
    let color: Color
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 16, weight: .bold)).foregroundColor(ShuttleTrackTheme.Colors.primaryText)
            Text(title).font(.system(size: 11, weight: .medium)).foregroundColor(ShuttleTrackTheme.Colors.tertiaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }
}

struct InfoChip: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 12, weight: .semibold))
            Text(text).font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
        .background(ShuttleTrackTheme.Colors.inputBackground)
        .cornerRadius(10)
    }
}

struct StatusChip: View {
    let icon: String
    let text: String
    let color: Color
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 12, weight: .semibold))
            Text(text).font(.system(size: 12, weight: .semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .foregroundColor(color)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

private extension Label where Title == Text, Icon == Image {
    init(_ date: Date, systemImage: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        self.init { Text(formatter.string(from: date)) } icon: { Image(systemName: systemImage) }
    }
}


