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
                                VStack(alignment: .leading, spacing: 8) {
                                    DriverTripRow(trip: trip)
                                    
                                    // Duruma göre aksiyon butonları
                                    HStack(spacing: 8) {
                                        if trip.status == .assigned {
                                            Button {
                                                tripViewModel.startTrip(trip)
                                            } label: {
                                                Text("Yola Çık")
                                            }
                                            .buttonStyle(ShuttleTrackButtonStyle(variant: .primary, size: .small))
                                        }
                                        if trip.status == .inProgress {
                                            Button {
                                                tripViewModel.completeTrip(trip)
                                            } label: {
                                                Text("Teslim Et")
                                            }
                                            .buttonStyle(ShuttleTrackButtonStyle(variant: .success, size: .small))
                                        }
                                        if trip.status == .assigned || trip.status == .inProgress {
                                            Button {
                                                tripViewModel.updateTripStatus(trip, status: .cancelled)
                                            } label: {
                                                Text("İptal")
                                            }
                                            .buttonStyle(ShuttleTrackButtonStyle(variant: .warning, size: .small))
                                        }
                                    }
                                }
                                .padding(.vertical, 6)
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
        .sheet(isPresented: $showProfile) {
            ProfileView().environmentObject(appViewModel)
        }
        .alert("Çıkış Yap", isPresented: $showLogoutConfirm) {
            Button("İptal", role: .cancel) { }
            Button("Çıkış Yap", role: .destructive) { appViewModel.signOut() }
        } message: {
            Text("Hesabınızdan çıkmak istediğinizden emin misiniz?")
        }
    }
    
    private func loadData() {
        guard let companyId = appViewModel.currentCompany?.id else { return }
        guard let driverId = appViewModel.currentUser?.uid else {
            errorMessage = "Kullanıcı bulunamadı"
            isLoading = false
            return
        }
        isLoading = true
        tripViewModel.fetchTripsForDriver(companyId: companyId, driverId: driverId)
        vehicleViewModel.fetchVehicles(for: companyId)
        if let phone = appViewModel.currentUserProfile?.phone {
            driverViewModel.observeCurrentDriver(companyId: companyId, phone: phone)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isLoading = false
        }
    }
    
    private func getAssignedTrips() -> [Trip] { tripViewModel.trips }
    
    private func assignedVehicle() -> Vehicle? {
        guard let assignedId = driverViewModel.currentDriver?.assignedVehicleId else { return nil }
        return vehicleViewModel.vehicles.first(where: { $0.id == assignedId })
    }
    
    private func notifications() -> [String] {
        var items: [String] = []
        // Yaklaşan işler
        let upcoming = tripViewModel.trips.filter { $0.isUpcoming }
        if !upcoming.isEmpty {
            items.append("Yaklaşan \(upcoming.count) işiniz var (1 saat içinde)")
        }
        // Geciken işler
        let overdue = tripViewModel.trips.filter { $0.isOverdue && $0.status != .completed && $0.status != .cancelled }
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
        return tripViewModel.trips.filter { cal.isDateInToday($0.scheduledPickupTime) }
    }
    private func inProgressTrips() -> [Trip] { tripViewModel.trips.filter { $0.status == .inProgress } }
    private func assignedTrips() -> [Trip] { tripViewModel.trips.filter { $0.status == .assigned } }
}

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


