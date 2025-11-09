import SwiftUI
import FirebaseAuth

struct DriverDashboardView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var tripViewModel = TripViewModel()
    @StateObject private var driverViewModel = DriverViewModel()
    @StateObject private var vehicleViewModel = VehicleViewModel()
    @StateObject private var notificationViewModel = NotificationViewModel()
    
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var showProfile = false
    @State private var showLogoutConfirm = false
    @State private var showStartTripConfirmation = false
    @State private var showCompleteTripConfirmation = false
    @State private var showCancelTripConfirmation = false
    @State private var selectedTripForAction: Trip? = nil
    @State private var showNotifications = false
    
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
                    ScrollView {
                        VStack(spacing: 20) {
                            // Modern Header Section
                            VStack(alignment: .leading, spacing: 16) {
                                // Greeting
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(greetingTitle())
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                                    
                                    Text("Atanan İşler Özeti")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(ShuttleTrackTheme.Colors.secondaryText)
                                }
                                
                                // Modern Stat Cards
                                HStack(spacing: 12) {
                                    ModernStatCard(
                                        title: "Bugün",
                                        value: "\(todayTrips().count)",
                                        icon: "calendar",
                                        color: .blue
                                    )
                                    ModernStatCard(
                                        title: "Devam",
                                        value: "\(inProgressTrips().count)",
                                        icon: "play.circle.fill",
                                        color: .green
                                    )
                                    ModernStatCard(
                                        title: "Bekleyen",
                                        value: "\(assignedTrips().count)",
                                        icon: "clock.fill",
                                        color: .orange
                                    )
                                    ModernStatCard(
                                        title: "Tamamlanan",
                                        value: "\(completedTrips().count)",
                                        icon: "checkmark.circle.fill",
                                        color: .purple
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            
                            // Bildirimler ve Uyarılar
                            if !notifications().isEmpty {
                                VStack(spacing: 8) {
                                    ForEach(notifications(), id: \.self) { note in
                                        ModernNotificationCard(message: note)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            // Sürücü Bildirimleri
                            if !notificationViewModel.notifications.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("Bildirimler")
                                            .font(.system(size: 20, weight: .bold, design: .rounded))
                                            .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                                        
                                        Spacer()
                                        
                                        if notificationViewModel.unreadCount > 0 {
                                            Button(action: {
                                                markAllNotificationsAsRead()
                                            }) {
                                                Text("Tümünü Okundu İşaretle")
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundColor(ShuttleTrackTheme.Colors.primaryBlue)
                                            }
                                        }
                                        
                                        Button(action: {
                                            showNotifications = true
                                        }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "bell.fill")
                                                    .font(.system(size: 14, weight: .semibold))
                                                if notificationViewModel.unreadCount > 0 {
                                                    Text("\(notificationViewModel.unreadCount)")
                                                        .font(.system(size: 12, weight: .bold))
                                                        .foregroundColor(.white)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(Color.red)
                                                        .clipShape(Capsule())
                                                }
                                            }
                                            .foregroundColor(ShuttleTrackTheme.Colors.primaryBlue)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    
                                    // Son 3 bildirim (özet)
                                    ForEach(notificationViewModel.notifications.prefix(3)) { notification in
                                        DriverNotificationCard(
                                            notification: notification,
                                            onTap: {
                                                notificationViewModel.markAsRead(notification)
                                            },
                                            onDelete: {
                                                notificationViewModel.deleteNotification(notification)
                                            }
                                        )
                                        .padding(.horizontal, 20)
                                    }
                                    
                                    if notificationViewModel.notifications.count > 3 {
                                        Button(action: {
                                            showNotifications = true
                                        }) {
                                            Text("Tümünü Gör (\(notificationViewModel.notifications.count))")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(ShuttleTrackTheme.Colors.primaryBlue)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(ShuttleTrackTheme.Colors.primaryBlue.opacity(0.1))
                                                )
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                }
                                .padding(.top, 8)
                            }
                            
                            // Araç Bilgileri
                            if let vehicle = assignedVehicle() {
                                ModernVehicleCard(vehicle: vehicle)
                                    .padding(.horizontal, 20)
                            }
                            
                            // Atanan İşler
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Atanan İşler")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                
                                if getAssignedTrips().isEmpty {
                                    EmptyStateView(
                                        icon: "list.bullet.clipboard",
                                        title: "Henüz iş atanmamış",
                                        message: "Size atanan işler burada görünecek"
                                    )
                                    .padding(.horizontal, 20)
                                } else {
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
                                        .padding(.horizontal, 20)
                                    }
                                }
                            }
                            .padding(.top, 8)
                            
                            Spacer(minLength: 20)
                        }
                        .padding(.vertical, 16)
                    }
                    .background(ShuttleTrackTheme.Colors.background)
                }
            }
            .navigationTitle("Sürücü Paneli")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Bildirim İkonu (Badge'li)
                    Button {
                        showNotifications = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: notificationViewModel.unreadCount > 0 ? "bell.fill" : "bell")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                            
                            if notificationViewModel.unreadCount > 0 {
                                Text("\(notificationViewModel.unreadCount)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                    
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
            loadNotifications()
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
        .sheet(isPresented: $showNotifications) {
            DriverNotificationsView(viewModel: notificationViewModel)
        }
    }
    
    private func loadNotifications() {
        // Sürücü ID'sini al
        var driverId: String?
        
        if let currentDriverId = driverViewModel.currentDriver?.id {
            driverId = currentDriverId
        } else if let phone = appViewModel.currentUserProfile?.phone,
                  let driver = driverViewModel.drivers.first(where: { 
                      normalizePhone($0.phoneNumber) == normalizePhone(phone) 
                  }),
                  let driverIdValue = driver.id {
            driverId = driverIdValue
        }
        
        guard let driverId = driverId,
              let companyId = appViewModel.currentCompany?.id else {
            return
        }
        
        // Bildirim izni iste
        NotificationService.shared.requestAuthorizationIfNeeded()
        
        // Bildirimleri yükle
        notificationViewModel.fetchNotifications(for: driverId, companyId: companyId)
    }
    
    private func markAllNotificationsAsRead() {
        var driverId: String?
        
        if let currentDriverId = driverViewModel.currentDriver?.id {
            driverId = currentDriverId
        } else if let phone = appViewModel.currentUserProfile?.phone,
                  let driver = driverViewModel.drivers.first(where: { 
                      normalizePhone($0.phoneNumber) == normalizePhone(phone) 
                  }),
                  let driverIdValue = driver.id {
            driverId = driverIdValue
        }
        
        guard let driverId = driverId,
              let companyId = appViewModel.currentCompany?.id else {
            return
        }
        
        notificationViewModel.markAllAsRead(for: driverId, companyId: companyId)
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
                  }),
                  let driverIdValue = driver.id {
            driverId = driverIdValue
            print("✅ Sürücü drivers listesinden bulundu: \(driverIdValue)")
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
        return vehicleViewModel.vehicles.first(where: { 
            guard let vehicleId = $0.id else { return false }
            return vehicleId == assignedId 
        })
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
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(trip.tripNumber)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                    
                    // Kategori badge
                    if let category = trip.category {
                        Text(category.titleText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(ShuttleTrackTheme.Colors.secondaryText)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(ShuttleTrackTheme.Colors.secondaryText.opacity(0.1))
                            )
                    }
                }
                
                Spacer()
                
                // Durum badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(trip.statusColor)
                        .frame(width: 10, height: 10)
                    Text(trip.statusText)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(trip.statusColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(trip.statusColor.opacity(0.12))
                )
            }
            
            Divider()
                .background(ShuttleTrackTheme.Colors.borderColor)
                .padding(.vertical, 4)
            
            // Lokasyon Bilgileri
            VStack(alignment: .leading, spacing: 12) {
                // Alış Noktası
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(ShuttleTrackTheme.Colors.pickupIcon.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(ShuttleTrackTheme.Colors.pickupIcon)
                            .font(.system(size: 20, weight: .semibold))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Alış Noktası")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(ShuttleTrackTheme.Colors.secondaryText)
                        Text(trip.pickupLocation.name)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                // Ok işareti
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(ShuttleTrackTheme.Colors.borderColor)
                        .frame(width: 2, height: 16)
                        .padding(.leading, 20)
                }
                
                // Bırakış Noktası
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(ShuttleTrackTheme.Colors.dropoffIcon.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(ShuttleTrackTheme.Colors.dropoffIcon)
                            .font(.system(size: 20, weight: .semibold))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bırakış Noktası")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(ShuttleTrackTheme.Colors.secondaryText)
                        Text(trip.dropoffLocation.name)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            
            Divider()
                .background(ShuttleTrackTheme.Colors.borderColor)
                .padding(.vertical, 4)
            
            // Detay Bilgileri
            HStack(spacing: 20) {
                // Tarih/Saat
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ShuttleTrackTheme.Colors.timeIcon)
                        Text("Alış Saati")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(ShuttleTrackTheme.Colors.secondaryText)
                    }
                    Text(formatTime(trip.scheduledPickupTime))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                }
                
                Spacer()
                
                // Yolcu Sayısı
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ShuttleTrackTheme.Colors.personIcon)
                        Text("Yolcu")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(ShuttleTrackTheme.Colors.secondaryText)
                    }
                    Text("\(trip.passengerCount)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                }
                
                // Ücret (varsa)
                if let fare = trip.fare {
                    Spacer()
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "turkishlirasign.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(ShuttleTrackTheme.Colors.priceIcon)
                            Text("Ücret")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(ShuttleTrackTheme.Colors.secondaryText)
                        }
                        Text(formatCurrency(fare))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(ShuttleTrackTheme.Colors.cardBackground)
            )
            
            // Zaman Takibi Bölümü
            Divider()
                .background(ShuttleTrackTheme.Colors.borderColor)
                .padding(.vertical, 4)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Zaman Takibi")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                
                // Planlanan Zamanlar
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.fill")
                            .foregroundColor(ShuttleTrackTheme.Colors.warning)
                            .font(.system(size: 14, weight: .semibold))
                        Text("Planlanan")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                    }
                    
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .foregroundColor(ShuttleTrackTheme.Colors.pickupIcon)
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Alış")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(ShuttleTrackTheme.Colors.secondaryText)
                            }
                            Text(formatDateTime(trip.scheduledPickupTime))
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.down.circle.fill")
                                    .foregroundColor(ShuttleTrackTheme.Colors.dropoffIcon)
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Bırakış")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(ShuttleTrackTheme.Colors.secondaryText)
                            }
                            Text(formatDateTime(trip.scheduledDropoffTime))
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(ShuttleTrackTheme.Colors.warning.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ShuttleTrackTheme.Colors.warning.opacity(0.2), lineWidth: 1)
                )
                
                // Gerçekleşen Zamanlar
                if let actualPickup = trip.actualPickupTime {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(ShuttleTrackTheme.Colors.success)
                                .font(.system(size: 14, weight: .semibold))
                            Text("Gerçekleşen")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            // Yola Çıkış
                            HStack(spacing: 12) {
                                Image(systemName: "play.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Yola Çıkış")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                    Text(formatDateTime(actualPickup))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    // Gecikme/Erkenlik kontrolü
                                    let timeDiff = actualPickup.timeIntervalSince(trip.scheduledPickupTime)
                                    if abs(timeDiff) > 300 { // 5 dakikadan fazla fark varsa
                                        HStack(spacing: 4) {
                                            Image(systemName: timeDiff > 0 ? "arrow.up.circle" : "arrow.down.circle")
                                                .foregroundColor(timeDiff > 0 ? .red : .green)
                                                .font(.caption2)
                                            Text(timeDiff > 0 ? "\(Int(timeDiff / 60)) dk gecikme" : "\(Int(abs(timeDiff) / 60)) dk erken")
                                                .font(.caption2)
                                                .foregroundColor(timeDiff > 0 ? .red : .green)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 6)
                            
                            // Teslim (varsa)
                            if let actualDropoff = trip.actualDropoffTime {
                                Divider()
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.title3)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Teslim Edildi")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.blue)
                                        Text(formatDateTime(actualDropoff))
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        
                                        // Süre hesaplama
                                        let duration = actualDropoff.timeIntervalSince(actualPickup)
                                        let hours = Int(duration / 3600)
                                        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
                                        HStack(spacing: 4) {
                                            Image(systemName: "clock.fill")
                                                .foregroundColor(.blue)
                                                .font(.caption2)
                                            Text("Süre: \(hours)s \(minutes)dk")
                                                .font(.caption2)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(ShuttleTrackTheme.Colors.success.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ShuttleTrackTheme.Colors.success.opacity(0.2), lineWidth: 1)
                    )
                } else {
                    // Henüz başlamamış
                    HStack(spacing: 12) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(ShuttleTrackTheme.Colors.warning)
                            .font(.system(size: 16, weight: .semibold))
                        Text("Henüz başlamadı")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ShuttleTrackTheme.Colors.secondaryText)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(ShuttleTrackTheme.Colors.warning.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ShuttleTrackTheme.Colors.warning.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            
            // Aksiyon Butonları
            if trip.status != .completed && trip.status != .cancelled {
                Divider()
                VStack(spacing: 10) {
                    // Yola Çık butonu (sadece assigned durumunda)
                    if trip.status == .assigned {
                        Button(action: {
                            print("🚀 Yola Çık butonu tıklandı - Trip: \(trip.tripNumber)")
                            onStart()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "play.circle.fill")
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Yola Çık")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("İşe başladığınızı bildirin")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.9))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [Color.green, Color.green.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                            .shadow(color: Color.green.opacity(0.25), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Teslim Et butonu (sadece inProgress durumunda)
                    if trip.status == .inProgress {
                        Button(action: {
                            print("✅ Teslim Et butonu tıklandı - Trip: \(trip.tripNumber)")
                            onComplete()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Teslim Et")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("İşi tamamladığınızı bildirin")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.9))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                            .shadow(color: Color.blue.opacity(0.25), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // İptal butonu (assigned veya inProgress durumunda)
                    if trip.status == .assigned || trip.status == .inProgress {
                        Button(action: {
                            print("❌ İptal Et butonu tıklandı - Trip: \(trip.tripNumber)")
                            onCancel()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                Text("İşi İptal Et")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    colors: [Color.red, Color.red.opacity(0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                            .shadow(color: Color.red.opacity(0.25), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            } else if trip.status == .completed {
                // Tamamlanan iş için bilgi göster
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(ShuttleTrackTheme.Colors.success.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(ShuttleTrackTheme.Colors.success)
                            .font(.system(size: 20, weight: .semibold))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("İş Tamamlandı")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                        Text("Bu iş başarıyla tamamlanmıştır")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(ShuttleTrackTheme.Colors.secondaryText)
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(ShuttleTrackTheme.Colors.success.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ShuttleTrackTheme.Colors.success.opacity(0.2), lineWidth: 1)
                )
            } else if trip.status == .cancelled {
                // İptal edilen iş için bilgi göster
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(ShuttleTrackTheme.Colors.error.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(ShuttleTrackTheme.Colors.error)
                            .font(.system(size: 20, weight: .semibold))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("İş İptal Edildi")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                        Text("Bu iş iptal edilmiştir")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(ShuttleTrackTheme.Colors.secondaryText)
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(ShuttleTrackTheme.Colors.error.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ShuttleTrackTheme.Colors.error.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: ShuttleTrackTheme.Shadows.medium, radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(trip.statusColor.opacity(0.25), lineWidth: 1.5)
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

// MARK: - Modern Components
struct ModernNotificationCard: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(ShuttleTrackTheme.Colors.warning)
                .frame(width: 24, height: 24)
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(ShuttleTrackTheme.Colors.warning.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ShuttleTrackTheme.Colors.warning.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ModernVehicleCard: View {
    let vehicle: Vehicle
    
    private func formatInsuranceText(for vehicle: Vehicle) -> String {
        let days = vehicle.daysUntilInsuranceExpiry
        if days < 0 {
            return "Sigorta: Süresi Dolmuş"
        } else if days == 0 {
            return "Sigorta: Bugün Bitiyor"
        } else if days == 1 {
            return "Sigorta: 1 gün kaldı"
        } else {
            return "Sigorta: \(days) gün kaldı"
        }
    }
    
    private func formatInspectionText(for vehicle: Vehicle) -> String {
        let days = vehicle.daysUntilInspectionExpiry
        if days < 0 {
            return "Muayene: Süresi Dolmuş"
        } else if days == 0 {
            return "Muayene: Bugün Bitiyor"
        } else if days == 1 {
            return "Muayene: 1 gün kaldı"
        } else {
            return "Muayene: \(days) gün kaldı"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(ShuttleTrackTheme.Colors.vehicleIcon.opacity(0.15))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "car.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(ShuttleTrackTheme.Colors.vehicleIcon)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vehicle.displayName)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                        
                        Text("Atanan Araç")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(ShuttleTrackTheme.Colors.secondaryText)
                    }
                }
                
                Spacer()
            }
            
            Divider()
                .background(ShuttleTrackTheme.Colors.borderColor)
            
            // Vehicle Info Chips
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ModernInfoChip(icon: "number", text: vehicle.plateNumber, color: .blue)
                    ModernInfoChip(icon: "person.3.fill", text: "\(vehicle.capacity) kişilik", color: .green)
                    ModernInfoChip(icon: "paintpalette.fill", text: vehicle.color, color: .orange)
                }
                
                HStack(spacing: 12) {
                    ModernStatusChip(
                        icon: "shield.fill",
                        text: formatInsuranceText(for: vehicle),
                        color: vehicle.insuranceStatusColor
                    )
                    ModernStatusChip(
                        icon: "wrench.and.screwdriver.fill",
                        text: formatInspectionText(for: vehicle),
                        color: vehicle.inspectionStatusColor
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: ShuttleTrackTheme.Shadows.medium, radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(ShuttleTrackTheme.Colors.vehicleIcon.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ModernInfoChip: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
        )
    }
}

struct ModernStatusChip: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 64, weight: .light))
                .foregroundColor(ShuttleTrackTheme.Colors.tertiaryText)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ShuttleTrackTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ShuttleTrackTheme.Colors.cardBackground)
        )
    }
}

// Yardımcı küçük bileşenler (geriye dönük uyumluluk için)
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

// MARK: - Driver Notification Card
struct DriverNotificationCard: View {
    let notification: DriverNotification
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(notification.color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: notification.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(notification.color)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(notification.title)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                        
                        Spacer()
                        
                        if !notification.isRead {
                            Circle()
                                .fill(ShuttleTrackTheme.Colors.primaryBlue)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    Text(notification.message)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(ShuttleTrackTheme.Colors.secondaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 8) {
                        Text(formatNotificationDate(notification.createdAt))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(ShuttleTrackTheme.Colors.tertiaryText)
                        
                        if notification.isRead {
                            Text("• Okundu")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(ShuttleTrackTheme.Colors.tertiaryText)
                        }
                    }
                }
                
                // Delete button
                Button(action: {
                    onDelete()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(ShuttleTrackTheme.Colors.tertiaryText.opacity(0.6))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(notification.isRead ? ShuttleTrackTheme.Colors.cardBackground : ShuttleTrackTheme.Colors.primaryBlue.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(notification.isRead ? ShuttleTrackTheme.Colors.borderColor.opacity(0.5) : notification.color.opacity(0.3), lineWidth: notification.isRead ? 1 : 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatNotificationDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
            return "Bugün \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "HH:mm"
            return "Dün \(formatter.string(from: date))"
        } else {
            formatter.dateFormat = "dd.MM.yyyy HH:mm"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Driver Notifications View
struct DriverNotificationsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: NotificationViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.notifications.isEmpty {
                        EmptyStateView(
                            icon: "bell.slash.fill",
                            title: "Bildirim Yok",
                            message: "Henüz bildiriminiz bulunmuyor"
                        )
                        .padding(.top, 100)
                    } else {
                        // Okunmamış bildirimler
                        let unreadNotifications = viewModel.notifications.filter { !$0.isRead }
                        if !unreadNotifications.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Okunmamış (\(unreadNotifications.count))")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        if let first = unreadNotifications.first {
                                            viewModel.markAllAsRead(for: first.driverId, companyId: first.companyId)
                                        }
                                    }) {
                                        Text("Tümünü Okundu İşaretle")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(ShuttleTrackTheme.Colors.primaryBlue)
                                    }
                                }
                                .padding(.horizontal, 20)
                                
                                ForEach(unreadNotifications) { notification in
                                    DriverNotificationCard(
                                        notification: notification,
                                        onTap: {
                                            viewModel.markAsRead(notification)
                                        },
                                        onDelete: {
                                            viewModel.deleteNotification(notification)
                                        }
                                    )
                                    .padding(.horizontal, 20)
                                }
                            }
                            .padding(.top, 8)
                        }
                        
                        // Okunmuş bildirimler
                        let readNotifications = viewModel.notifications.filter { $0.isRead }
                        if !readNotifications.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Okunmuş")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                                    .padding(.horizontal, 20)
                                    .padding(.top, unreadNotifications.isEmpty ? 0 : 16)
                                
                                ForEach(readNotifications) { notification in
                                    DriverNotificationCard(
                                        notification: notification,
                                        onTap: {
                                            // Zaten okunmuş, sadece detay göster
                                        },
                                        onDelete: {
                                            viewModel.deleteNotification(notification)
                                        }
                                    )
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .background(ShuttleTrackTheme.Colors.background)
            .navigationTitle("Bildirimler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}


