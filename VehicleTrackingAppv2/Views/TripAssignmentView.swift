import SwiftUI

struct TripAssignmentView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = TripViewModel()
    @StateObject private var exportService = ExportService()
    @State private var showingAddTrip = false
    @State private var showingAddCargo = false
    @State private var showingTripDetail = false
    @State private var tripForDetail: Trip?
    @State private var showingDeleteAlert = false
    @State private var tripToDelete: Trip?
    @State private var selectedStatus: Trip.TripStatus? = nil
    @State private var showingExportOptions = false
    @State private var exportedFileURL: URL?
    @State private var showingShareSheet = false
    @State private var selectedProject: ProjectType? = nil
    
    enum ProjectType {
        case passenger
        case cargo
        
        var title: String {
            switch self {
            case .passenger: return "Yolcu Taşıma Yönetimi"
            case .cargo: return "Yük Yönetimi"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Proje tipi seçimi
                if selectedProject == nil {
                    VStack(spacing: 24) {
                        Text("İş Yönetimi")
                            .font(.system(size: 28, weight: .bold))
                            .padding(.top, 12)
                        Text("Lütfen bir yönetim türü seçin")
                            .foregroundColor(.secondary)
                        HStack(spacing: 16) {
                            SelectionCard(title: "Yolcu Yönetimi", icon: "person.3.fill", color: .blue) {
                                selectedProject = .passenger
                            }
                            SelectionCard(title: "Yük Yönetimi", icon: "shippingbox.fill", color: .orange) {
                                selectedProject = .cargo
                            }
                        }
                        .padding(.horizontal, 20)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                // Filtre (Yalnızca yatay butonlar)
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
                                title: displayName(for: status),
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
                        .padding(.top, 8)
                    }
                    .listStyle(PlainListStyle())
                }
                }
                
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
            }
            .navigationTitle(selectedProject?.title ?? "İş Yönetimi")
            .navigationBarItems(
                leading:
                    Group {
                        if selectedProject != nil {
                            HStack(spacing: 16) {
                                Button(action: { selectedProject = nil }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "chevron.left")
                                        Text("Projeler")
                                    }
                                }
                                Button(action: {
                                    showingExportOptions = true
                                }) {
                                    Image(systemName: "square.and.arrow.up")
                                }
                            }
                        } else {
                            EmptyView()
                        }
                    },
                trailing:
                    Group {
                        if selectedProject != nil {
                            Button(action: {
                                if selectedProject == .cargo {
                                    showingAddCargo = true
                                } else if selectedProject == .passenger {
                                    showingAddTrip = true
                                }
                            }) {
                                Image(systemName: "plus")
                            }
                        } else {
                            EmptyView()
                        }
                    }
            )
            .onAppear {
                loadTrips()
            }
            .onChange(of: appViewModel.currentCompany?.id) { oldValue, newValue in
                if let companyId = newValue {
                    viewModel.fetchTrips(for: companyId)
                    viewModel.fetchVehicles(for: companyId)
                    viewModel.fetchDrivers(for: companyId)
                }
            }
            .sheet(isPresented: $showingAddTrip) {
                AddEditTripView(viewModel: viewModel, appViewModel: appViewModel)
            }
            .sheet(isPresented: $showingAddCargo) {
                AddEditCargoView(viewModel: viewModel, appViewModel: appViewModel)
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
                    .onAppear {
                        // Detay sayfası açıldığında gerekli verileri yükle
                        loadDetailData()
                    }
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
        let byStatus: [Trip] = {
            guard let status = selectedStatus else { return viewModel.trips }
            return viewModel.trips.filter { $0.status == status }
        }()
        // Kategori filtreleme
        switch selectedProject {
        case .passenger:
            return byStatus.filter { $0.category == nil || $0.category == .passenger }
        case .cargo:
            return byStatus.filter { $0.category == .cargo }
        case .none:
            return byStatus
        }
    }
    
    private func loadTrips() {
        guard let companyId = appViewModel.currentCompany?.id else { return }
        viewModel.fetchTrips(for: companyId)
        viewModel.fetchVehicles(for: companyId)
        viewModel.fetchDrivers(for: companyId)
    }
    
    private func loadDetailData() {
        guard let companyId = appViewModel.currentCompany?.id else { return }
        // Detay sayfası için gerekli tüm verileri yükle
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
                            .fill(ShuttleTrackTheme.Colors.primaryBlue.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: "airplane.departure")
                            .font(.title3)
                            .foregroundColor(ShuttleTrackTheme.Colors.primaryBlue)
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
                            .fill(trip.statusColor)
                            .frame(width: 6, height: 6)
                        Text(trip.statusText)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(trip.statusColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(trip.statusColor.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Bilgi rozetleri
                HStack(spacing: 8) {
                    if trip.isUpcoming {
                        CapsuleTag(title: "Yakında", icon: "clock", color: ShuttleTrackTheme.Colors.info)
                    }
                    if trip.isOverdue {
                        CapsuleTag(title: "Gecikmiş", icon: "exclamationmark.triangle.fill", color: .red)
                    }
                    if trip.notes != nil {
                        CapsuleTag(title: "Not var", icon: "note.text", color: ShuttleTrackTheme.Colors.secondaryBlue)
                    }
                }
                
                HStack(spacing: 16) {
                    CompactDetailItem(title: "Alış", value: DateFormatter.localizedString(from: trip.scheduledPickupTime, dateStyle: .none, timeStyle: .short), icon: "clock")
                    CompactDetailItem(title: "Varış", value: DateFormatter.localizedString(from: trip.scheduledDropoffTime, dateStyle: .none, timeStyle: .short), icon: "clock.arrow.circlepath")
                    CompactDetailItem(title: "Yolcu", value: "\(trip.passengerCount)", icon: "person.2")
                    if let fare = trip.fare {
                        CompactDetailItem(title: "Ücret", value: formatCurrency(fare), icon: "turkishlirasign")
                    }
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
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: NSNumber(value: amount)) ?? String(format: "₺%.0f", amount)
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
    @ObservedObject var viewModel: TripViewModel
    let appViewModel: AppViewModel
    let onDelete: (Trip) -> Void
    
    var body: some View {
        NavigationView {
            if viewModel.isLoading && (viewModel.vehicles.isEmpty || viewModel.drivers.isEmpty) {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    Text("Detaylar yükleniyor...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
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
                                .fill(trip.statusColor)
                                .frame(width: 12, height: 12)
                            Text(trip.statusText)
                                .font(.headline)
                                .foregroundColor(trip.statusColor)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(trip.statusColor.opacity(0.1))
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
                            if let fare = trip.fare {
                                DetailRow(title: "Ücret", value: formatCurrency(fare), icon: "turkishlirasign")
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Atamalar
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Atamalar")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 12) {
                            if let vehicle = findVehicle(by: trip.vehicleId) {
                                DetailRow(title: "Araç", value: vehicle.displayName, icon: "car.fill")
                            } else {
                                DetailRow(title: "Araç", value: trip.vehicleId.isEmpty ? "Atanmamış" : "Bulunamadı", icon: "car")
                            }
                            if let driver = findDriver(by: trip.driverId) {
                                DetailRow(title: "Şoför", value: driver.fullName, icon: "person.fill")
                                DetailRow(title: "Telefon", value: driver.phoneNumber, icon: "phone.fill")
                            } else {
                                DetailRow(title: "Şoför", value: trip.driverId.isEmpty ? "Atanmamış" : "Bulunamadı", icon: "person")
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Ek Bilgiler
                    if let notes = trip.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notlar")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text(notes)
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Zaman Bilgileri
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Zaman Bilgileri")
                            .font(.title3)
                            .fontWeight(.bold)
                        VStack(spacing: 12) {
                            DetailRow(title: "Oluşturulma", value: DateFormatter.localizedString(from: trip.createdAt, dateStyle: .medium, timeStyle: .short), icon: "calendar.badge.plus")
                            DetailRow(title: "Güncellenme", value: DateFormatter.localizedString(from: trip.updatedAt, dateStyle: .medium, timeStyle: .short), icon: "calendar.badge.clock")
                        }
                    }
                    .padding(.horizontal, 20)
                    
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
            }
        }
        .navigationTitle("İş Detayı")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button("Kapat") { presentationMode.wrappedValue.dismiss() })
        .sheet(isPresented: $showingEditSheet) {
            AddEditTripView(trip: trip, viewModel: viewModel, appViewModel: appViewModel)
        }
    }
    
    // MARK: - Helpers
    private func findVehicle(by id: String) -> Vehicle? {
        guard !id.isEmpty else { return nil }
        return viewModel.vehicles.first { $0.id == id }
    }
    
    private func findDriver(by id: String) -> Driver? {
        guard !id.isEmpty else { return nil }
        return viewModel.drivers.first { $0.id == id }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: NSNumber(value: amount)) ?? String(format: "₺%.0f", amount)
    }
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

// MARK: - Capsule Tag
struct CapsuleTag: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(title)
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .cornerRadius(999)
    }
}

// MARK: - Selection Card (Yolcu / Yük)
struct SelectionCard: View {
    let title: String
    let icon: String
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(color.opacity(0.12))
                        .frame(width: 80, height: 80)
                    Image(systemName: icon)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(color)
                }
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

