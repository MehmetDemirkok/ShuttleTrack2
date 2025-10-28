import SwiftUI

struct TripAssignmentView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = TripViewModel()
    @StateObject private var exportService = ExportService()
    @State private var showingAddTrip = false
    @State private var showingTripDetail = false
    @State private var tripForDetail: Trip?
    @State private var showingDeleteAlert = false
    @State private var tripToDelete: Trip?
    @State private var selectedStatus: Trip.TripStatus? = nil
    @State private var showingExportOptions = false
    @State private var exportedFileURL: URL?
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Filtre - Araçlar sayfası stiline uygun kompakt başlık
                HStack {
                    Picker("Durum", selection: $selectedStatus) {
                        Text("Tümü").tag(nil as Trip.TripStatus?)
                        ForEach(Trip.TripStatus.allCases, id: \.self) { status in
                            Text(displayName(for: status)).tag(status as Trip.TripStatus?)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.horizontal)
                
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
                    List {
                        ForEach(filteredTrips) { trip in
                            TripRowCard(
                                trip: trip,
                                onTap: {
                                    tripForDetail = trip
                                    showingTripDetail = true
                                }
                            )
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
            }
            .navigationTitle("Transfer Yönetimi")
            .navigationBarItems(
                leading: Button(action: {
                    showingExportOptions = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                },
                trailing: Button(action: {
                    showingAddTrip = true
                }) {
                    Image(systemName: "plus")
                }
            )
            .onAppear {
                loadTrips()
            }
            .sheet(isPresented: $showingAddTrip) {
                AddEditTripView(viewModel: viewModel, appViewModel: appViewModel)
            }
            .sheet(isPresented: $showingTripDetail) {
                if let trip = tripForDetail {
                    TripDetailView(
                        trip: trip,
                        viewModel: viewModel,
                        appViewModel: appViewModel,
                        onDelete: { t in
                            tripToDelete = t
                            showingDeleteAlert = true
                        }
                    )
                }
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
        guard let status = selectedStatus else { return viewModel.trips }
        return viewModel.trips.filter { $0.status == status }
    }
    
    private func loadTrips() {
        guard let companyId = appViewModel.currentCompany?.id else { return }
        viewModel.fetchTrips(for: companyId)
        viewModel.fetchVehicles(for: companyId)
        viewModel.fetchDrivers(for: companyId)
    }

    private func displayName(for status: Trip.TripStatus) -> String {
        switch status {
        case .scheduled: return "Planlandı"
        case .assigned: return "Atandı"
        case .inProgress: return "Devam Ediyor"
        case .completed: return "Tamamlandı"
        case .cancelled: return "İptal Edildi"
        }
    }
}

// Araçlar sayfasına benzer kompakt kart görünümü
struct TripRowCard: View {
    let trip: Trip
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "airplane.departure")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(trip.tripNumber)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                        Text("\(trip.pickupLocation.name) → \(trip.dropoffLocation.name)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(trip.statusColor))
                            .frame(width: 6, height: 6)
                        Text(trip.statusText)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(trip.statusColor))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(trip.statusColor).opacity(0.1))
                    .cornerRadius(12)
                }
                
                HStack(spacing: 16) {
                    CompactDetailItem(title: "Alış", value: DateFormatter.localizedString(from: trip.scheduledPickupTime, dateStyle: .none, timeStyle: .short), icon: "clock")
                    CompactDetailItem(title: "Varış", value: DateFormatter.localizedString(from: trip.scheduledDropoffTime, dateStyle: .none, timeStyle: .short), icon: "clock.arrow.circlepath")
                    CompactDetailItem(title: "Yolcu", value: "\(trip.passengerCount)", icon: "person.2")
                }
                
                if !trip.vehicleId.isEmpty || !trip.driverId.isEmpty {
                    HStack(spacing: 12) {
                        if !trip.vehicleId.isEmpty {
                            CompactWarningBanner(icon: "car.fill", message: "Araç atanmış", color: .green)
                        }
                        if !trip.driverId.isEmpty {
                            CompactWarningBanner(icon: "person.fill", message: "Şoför atanmış", color: .green)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray6), lineWidth: 1)
        )
        .onTapGesture { onTap() }
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

// MARK: - Trip Detail View
struct TripDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showingEditSheet = false
    @State private var showingStatusMenu = false
    
    let trip: Trip
    let viewModel: TripViewModel
    let appViewModel: AppViewModel
    let onDelete: (Trip) -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Image(systemName: "airplane.departure")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                        }
                        
                        VStack(spacing: 4) {
                            Text(trip.tripNumber)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("\(trip.pickupLocation.name) → \(trip.dropoffLocation.name)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(trip.statusColor))
                                .frame(width: 12, height: 12)
                            Text(trip.statusText)
                                .font(.headline)
                                .foregroundColor(Color(trip.statusColor))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color(trip.statusColor).opacity(0.1))
                        .cornerRadius(20)
                    }
                    .padding(.top, 20)
                    
                    // Bilgiler
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Transfer Bilgileri")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 12) {
                            DetailRow(title: "Alış Saati", value: DateFormatter.localizedString(from: trip.scheduledPickupTime, dateStyle: .medium, timeStyle: .short), icon: "clock")
                            DetailRow(title: "Varış Saati", value: DateFormatter.localizedString(from: trip.scheduledDropoffTime, dateStyle: .medium, timeStyle: .short), icon: "clock.arrow.circlepath")
                            DetailRow(title: "Yolcu Sayısı", value: "\(trip.passengerCount) kişi", icon: "person.2.fill")
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    if !trip.vehicleId.isEmpty || !trip.driverId.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Atamalar")
                                .font(.title3)
                                .fontWeight(.bold)
                            HStack(spacing: 12) {
                                if !trip.vehicleId.isEmpty {
                                    WarningDetailBanner(icon: "car.fill", message: "Araç atanmış", color: .green)
                                }
                                if !trip.driverId.isEmpty {
                                    WarningDetailBanner(icon: "person.fill", message: "Şoför atanmış", color: .green)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Actions
                    VStack(spacing: 16) {
                        Text("İşlemler")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 12) {
                            Button(action: { showingEditSheet = true }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "pencil")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                    Text("İşi Düzenle")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                            
                            Menu {
                                ForEach(Trip.TripStatus.allCases, id: \.self) { status in
                                    if status != trip.status {
                                        Button(status.rawValue) {
                                            viewModel.updateTripStatus(trip, status: status)
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                    Text("Durum Değiştir")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                                .background(Color.orange)
                                .cornerRadius(12)
                            }
                            
                            Button(action: { onDelete(trip) }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "trash")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                    Text("İşi Sil")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                                .background(Color.red)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("İş Detayı")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Kapat") { presentationMode.wrappedValue.dismiss() })
            .sheet(isPresented: $showingEditSheet) {
                AddEditTripView(trip: trip, viewModel: viewModel, appViewModel: appViewModel)
            }
        }
    }
}
struct TripAssignmentView_Previews: PreviewProvider {
    static var previews: some View {
        TripAssignmentView()
    }
}

