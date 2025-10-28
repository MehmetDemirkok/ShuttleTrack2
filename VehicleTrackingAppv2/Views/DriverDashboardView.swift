import SwiftUI
import FirebaseAuth

struct DriverDashboardView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var tripViewModel = TripViewModel()
    
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
                        Section(header: Text("Atanan İşler")) {
                            ForEach(getAssignedTrips()) { trip in
                                DriverTripRow(trip: trip)
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isLoading = false
        }
    }
    
    private func getAssignedTrips() -> [Trip] { tripViewModel.trips }
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


