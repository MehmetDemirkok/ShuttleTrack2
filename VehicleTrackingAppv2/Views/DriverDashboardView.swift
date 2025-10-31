import SwiftUI
import FirebaseAuth

struct DriverDashboardView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var tripViewModel = TripViewModel()
    @StateObject private var driverViewModel = DriverViewModel()
    @StateObject private var vehicleViewModel = VehicleViewModel()
    
    @State private var isLoading = true
    @State private var errorMessage = ""
    
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
                                            HStack {
                                                Image(systemName: "shield.fill")
                                                    .foregroundColor(vehicle.insuranceStatusColor)
                                                Text("Sigorta: \(vehicle.insuranceStatus)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            HStack {
                                                Image(systemName: "wrench.and.screwdriver.fill")
                                                    .foregroundColor(vehicle.inspectionStatusColor)
                                                Text("Muayene: \(vehicle.inspectionStatus)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
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
        }
        .onAppear {
            loadData()
        }
        .onChange(of: appViewModel.currentCompany?.id) { oldValue, newValue in
            if newValue != nil {
                loadData()
            }
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

private extension Label where Title == Text, Icon == Image {
    init(_ date: Date, systemImage: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        self.init { Text(formatter.string(from: date)) } icon: { Image(systemName: systemImage) }
    }
}


