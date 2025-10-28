import SwiftUI

struct TripAssignmentView: View {
    @StateObject private var viewModel = TripViewModel()
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var exportService = ExportService()
    @State private var showingAddTrip = false
    @State private var selectedTrip: Trip?
    @State private var showingDeleteAlert = false
    @State private var tripToDelete: Trip?
    @State private var selectedStatus: Trip.TripStatus? = nil // nil = "Tümü"
    @State private var showingExportOptions = false
    @State private var exportedFileURL: URL?
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Başlık
                HStack {
                    Text("Transferler")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Horizontal Scrollable Filter Buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Tümü butonu
                        FilterButton(
                            title: "Tümü",
                            isSelected: selectedStatus == nil,
                            action: { selectedStatus = nil }
                        )
                        
                        // Diğer status butonları
                        ForEach(Trip.TripStatus.allCases, id: \.self) { status in
                            FilterButton(
                                title: status.statusShortText,
                                isSelected: selectedStatus == status,
                                action: { selectedStatus = status }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                // İçerik
                if viewModel.isLoading {
                    ProgressView("İşler yükleniyor...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredTrips.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Henüz iş eklenmemiş")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("İlk işinizi eklemek için + butonuna tıklayın")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(filteredTrips) { trip in
                                TransferCardView(
                                    trip: trip,
                                    onEdit: { selectedTrip = trip },
                                    onDelete: {
                                        tripToDelete = trip
                                        showingDeleteAlert = true
                                    },
                                    onStatusChange: { newStatus in
                                        viewModel.updateTripStatus(trip, status: newStatus)
                                    }
                                )
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
            }
            .background(ShuttleTrackTheme.Colors.background)
            .navigationTitle("")
            .navigationBarHidden(true)
            .navigationBarItems(
                leading: Button(action: {
                    showingExportOptions = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                },
                trailing: Button(action: {
                    showingAddTrip = true
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                }
            )
            .onAppear {
                loadTrips()
            }
            .sheet(isPresented: $showingAddTrip) {
                AddEditTripView(viewModel: viewModel, appViewModel: appViewModel)
            }
            .sheet(item: $selectedTrip) { trip in
                AddEditTripView(trip: trip, viewModel: viewModel, appViewModel: appViewModel)
            }
            .alert("İşi Sil", isPresented: $showingDeleteAlert) {
                Button("İptal", role: .cancel) { }
                Button("Sil", role: .destructive) {
                    if let trip = tripToDelete {
                        viewModel.deleteTrip(trip)
                    }
                }
            } message: {
                Text("Bu işi silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.")
            }
            .sheet(isPresented: $showingExportOptions) {
                ExportOptionsView(
                    trips: filteredTrips,
                    exportService: exportService,
                    onExport: { fileURL in
                        exportedFileURL = fileURL
                        showingExportOptions = false
                        showingShareSheet = true
                    }
                )
            }
            .sheet(isPresented: $showingShareSheet) {
                if let fileURL = exportedFileURL {
                    ShareSheet(activityItems: [fileURL])
                }
            }
        }
    }
    
    private var filteredTrips: [Trip] {
        if selectedStatus == nil {
            return viewModel.trips
        } else {
            return viewModel.trips.filter { $0.status == selectedStatus }
        }
    }
    
    private func loadTrips() {
        guard let companyId = appViewModel.currentCompany?.id else { return }
        viewModel.fetchTrips(for: companyId)
        viewModel.fetchVehicles(for: companyId)
        viewModel.fetchDrivers(for: companyId)
    }
}

// MARK: - Transfer Card
struct TransferCardView: View {
    let trip: Trip
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onStatusChange: (Trip.TripStatus) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Üst satır: iş numarası ve durum rozeti
            HStack {
                Text(trip.tripNumber)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                HStack(spacing: 6) {
                    Circle().fill(trip.statusColor).frame(width: 8, height: 8)
                    Text(trip.statusText)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(trip.statusColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(trip.statusColor.opacity(0.12))
                        .cornerRadius(16)
                }
            }

            // Konumlar
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Circle().fill(ShuttleTrackTheme.Colors.success).frame(width: 14, height: 14)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(trip.pickupLocation.name).font(.system(size: 16, weight: .semibold))
                        if !trip.pickupLocation.address.isEmpty {
                            Text(trip.pickupLocation.address).font(.system(size: 12)).foregroundColor(.secondary)
                        }
                    }
                }
                HStack(alignment: .top, spacing: 12) {
                    Circle().fill(ShuttleTrackTheme.Colors.warning).frame(width: 14, height: 14)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(trip.dropoffLocation.name).font(.system(size: 16, weight: .semibold))
                        if !trip.dropoffLocation.address.isEmpty {
                            Text(trip.dropoffLocation.address).font(.system(size: 12)).foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Bilgi satırları
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: "calendar").foregroundColor(ShuttleTrackTheme.Colors.timeIcon)
                    Text("Tarih").font(.caption).foregroundColor(.secondary)
                    Text(dateTimeString(trip.scheduledPickupTime)).font(.system(size: 14, weight: .semibold))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: "person.2").foregroundColor(ShuttleTrackTheme.Colors.personIcon)
                    Text("Yolcu").font(.caption).foregroundColor(.secondary)
                    Text("\(trip.passengerCount) kişi").font(.system(size: 14, weight: .semibold))
                }
                Spacer()
            }

            // Aksiyonlar
            HStack(spacing: 12) {
                Button("Düzenle") { onEdit() }
                    .buttonStyle(ShuttleTrackButtonStyle(variant: .secondary, size: .small))

                Menu("Durum") {
                    ForEach(Trip.TripStatus.allCases, id: \.self) { status in
                        if status != trip.status {
                            Button(status.statusShortText) { onStatusChange(status) }
                        }
                    }
                }
                .font(.caption)
                .foregroundColor(.orange)

                Button("Sil") { onDelete() }
                    .buttonStyle(ShuttleTrackButtonStyle(variant: .outline, size: .small))
            }
        }
        .padding(16)
        .background(ShuttleTrackTheme.Colors.cardBackground)
        .cornerRadius(20)
        .shadow(color: ShuttleTrackTheme.Shadows.small, radius: 8, x: 0, y: 2)
    }

    private func dateTimeString(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "tr_TR")
        dateFormatter.dateFormat = "d MMM, HH:mm"
        return dateFormatter.string(from: date)
    }
}
struct TripRowView: View {
    let trip: Trip
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onStatusChange: (Trip.TripStatus) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.tripNumber)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(trip.pickupLocation.name) → \(trip.dropoffLocation.name)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Yolcu Sayısı: \(trip.passengerCount) kişi")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Circle()
                            .fill(trip.statusColor)
                            .frame(width: 8, height: 8)
                        
                        Text(trip.statusText)
                            .font(.caption)
                            .foregroundColor(trip.statusColor)
                    }
                    
                    Text(trip.scheduledPickupTime, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if trip.isOverdue {
                        Text("⚠️ Geçti")
                            .font(.caption2)
                            .foregroundColor(.red)
                    } else {
                        Text("⏰ \(trip.timeRemaining)")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            if !trip.vehicleId.isEmpty && !trip.driverId.isEmpty {
                HStack {
                    Text("🚗 Araç atanmış")
                        .font(.caption2)
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    Text("👨‍💼 Şoför atanmış")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    onEdit()
                }) {
                    Text("Düzenle")
                }
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
                
                if trip.status != .completed && trip.status != .cancelled {
                    Menu("Durum") {
                        ForEach(Trip.TripStatus.allCases, id: \.self) { status in
                            if status != trip.status {
                                Button(status.statusShortText) {
                                    onStatusChange(status)
                                }
                            }
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
                }
                
                Button(action: {
                    onDelete()
                }) {
                    Text("Sil")
                }
                .font(.caption)
                .foregroundColor(.red)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ExportOptionsView: View {
    let trips: [Trip]
    let exportService: ExportService
    let onExport: (URL?) -> Void
    
    @State private var selectedFormat: ExportFormat = .excel
    @Environment(\.presentationMode) var presentationMode
    
    enum ExportFormat: String, CaseIterable {
        case excel = "Excel"
        case pdf = "PDF"
        
        var displayName: String {
            switch self {
            case .excel: return "Excel (.csv)"
            case .pdf: return "PDF"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export Seçenekleri")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("\(trips.count) iş export edilecek")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Button(action: {
                            selectedFormat = format
                        }) {
                            HStack {
                                Image(systemName: selectedFormat == format ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedFormat == format ? .blue : .gray)
                                
                                Text(format.displayName)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            .padding()
                            .background(selectedFormat == format ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
                
                if exportService.isExporting {
                    VStack(spacing: 12) {
                        ProgressView(value: exportService.exportProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                        
                        Text(exportService.exportMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button("İptal") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    Button("Export Et") {
                        exportTrips()
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(exportService.isExporting ? Color.gray : Color.blue)
                    .cornerRadius(8)
                    .disabled(exportService.isExporting)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarHidden(true)
        }
    }
    
    private func exportTrips() {
        let fileURL: URL?
        
        switch selectedFormat {
        case .excel:
            fileURL = exportService.exportToExcel(trips: trips)
        case .pdf:
            fileURL = exportService.exportToPDF(trips: trips)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onExport(fileURL)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
struct TripAssignmentView_Previews: PreviewProvider {
    static var previews: some View {
        TripAssignmentView()
    }
}

// MARK: - FilterButton Component
struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? ShuttleTrackTheme.Colors.primaryBlue : Color.gray.opacity(0.1))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

