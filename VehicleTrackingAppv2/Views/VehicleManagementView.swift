import SwiftUI

struct VehicleManagementView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = VehicleViewModel()
    @State private var showingAddVehicle = false
    @State private var showingVehicleDetail = false
    @State private var vehicleForDetail: Vehicle?
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        
                        Text("Araçlar yükleniyor...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Bu işlem birkaç saniye sürebilir")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.vehicles.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Henüz araç eklenmemiş")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("İlk aracınızı eklemek için + butonuna tıklayın")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.vehicles) { vehicle in
                            VehicleRowView(
                                vehicle: vehicle,
                                onTap: {
                                    vehicleForDetail = vehicle
                                    showingVehicleDetail = true
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
                        .foregroundColor(Color.red)
                        .font(.caption)
                        .padding()
                }
            }
            .navigationTitle("Araçlar")
            .navigationBarItems(
                trailing: Button(action: {
                    showingAddVehicle = true
                }) {
                    Image(systemName: "plus")
                }
            )
            .onAppear {
                loadVehicles()
            }
            .sheet(isPresented: $showingAddVehicle) {
                AddEditVehicleView(viewModel: viewModel, appViewModel: appViewModel)
            }
            .sheet(isPresented: $showingVehicleDetail) {
                if let vehicle = vehicleForDetail {
                    VehicleDetailView(vehicle: vehicle, viewModel: viewModel, appViewModel: appViewModel)
                }
            }
        }
    }
    
    private func loadVehicles() {
        guard let companyId = appViewModel.currentCompany?.id else { return }
        viewModel.fetchVehicles(for: companyId)
    }
}

struct VehicleRowView: View {
    let vehicle: Vehicle
    let onTap: () -> Void
    
    // Araç ikonu
    private var vehicleIcon: String {
        switch vehicle.vehicleType {
        case .sedan:
            return "car.fill"
        case .suv:
            return "car.fill"
        case .minivan:
            return "car.fill"
        case .bus:
            return "bus.fill"
        case .van:
            return "car.fill"
        case .pickup:
            return "car.fill"
        }
    }
    
    // Araç ikon rengi
    private var vehicleIconColor: Color {
        switch vehicle.vehicleType {
        case .sedan:
            return .blue
        case .suv:
            return Color.green
        case .minivan:
            return .orange
        case .bus:
            return .purple
        case .van:
            return Color.red
        case .pickup:
            return .brown
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Ana kart içeriği - Küçültülmüş
            VStack(alignment: .leading, spacing: 12) {
                // Header - Araç adı ve durum
                HStack(alignment: .top) {
                    // Araç ikonu - Küçültülmüş
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(vehicleIconColor.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: vehicleIcon)
                            .font(.title3)
                            .foregroundColor(vehicleIconColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(vehicle.displayName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(vehicle.plateNumber)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Durum badge'i - Küçültülmüş
                    HStack(spacing: 4) {
                        Circle()
                            .fill(vehicle.isActive ? Color.green : Color.red)
                            .frame(width: 6, height: 6)
                        
                        Text(vehicle.statusText)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(vehicle.isActive ? Color.green : Color.red)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((vehicle.isActive ? Color.green : Color.red).opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Araç detayları grid - Küçültülmüş
                HStack(spacing: 16) {
                    CompactDetailItem(title: "Yıl", value: "\(vehicle.year)", icon: "calendar")
                    CompactDetailItem(title: "Kapasite", value: "\(vehicle.capacity)", icon: "person.2")
                    CompactDetailItem(title: "Renk", value: vehicle.color, icon: "paintbrush")
                }
                
                // Sigorta ve Muayene bilgileri - Küçültülmüş
                HStack(spacing: 12) {
                    CompactDocumentStatusWithDays(
                        title: "Sigorta",
                        days: vehicle.daysUntilInsuranceExpiry,
                        statusColor: vehicle.insuranceStatusColor,
                        icon: "doc.text"
                    )
                    
                    CompactDocumentStatusWithDays(
                        title: "Muayene",
                        days: vehicle.daysUntilInspectionExpiry,
                        statusColor: vehicle.inspectionStatusColor,
                        icon: "checkmark.seal"
                    )
                }
                
                // Uyarı mesajları - Küçültülmüş
                if vehicle.daysUntilInsuranceExpiry < 0 || vehicle.daysUntilInspectionExpiry < 0 {
                    CompactWarningBanner(
                        icon: "exclamationmark.triangle.fill",
                        message: "Süresi dolmuş belgeler var!",
                        color: Color.red
                    )
                } else if vehicle.daysUntilInsuranceExpiry <= 30 || vehicle.daysUntilInspectionExpiry <= 30 {
                    CompactWarningBanner(
                        icon: "clock.fill",
                        message: "Yakında süresi dolacak belgeler var!",
                        color: .orange
                    )
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
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Compact Helper Views

struct CompactDetailItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CompactDocumentStatus: View {
    let title: String
    let status: String
    let statusColor: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 4) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 4, height: 4)
                
                Text(status)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(statusColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CompactDocumentStatusWithDays: View {
    let title: String
    let days: Int
    let statusColor: Color
    let icon: String
    
    private var displayText: String {
        if days < 0 {
            return "Dolmuş"
        } else if days == 0 {
            return "Bugün"
        } else if days == 1 {
            return "1 gün"
        } else {
            return "\(days) gün"
        }
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            // Başlık
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            
            // Gün sayısı - Büyük ve belirgin
            HStack(spacing: 5) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)
                
                Text(displayText)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(statusColor)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(statusColor.opacity(0.15))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
    }
}

struct CompactWarningBanner: View {
    let icon: String
    let message: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            
            Text(message)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
}

struct CompactActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color)
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Original Helper Views

struct DetailItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DocumentStatus: View {
    let title: String
    let status: String
    let statusColor: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)
                
                Text(status)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(statusColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct WarningBanner: View {
    let icon: String
    let message: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(message)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(color)
            .cornerRadius(10)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Vehicle Detail View

struct VehicleDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    let vehicle: Vehicle
    let viewModel: VehicleViewModel
    let appViewModel: AppViewModel
    
    init(vehicle: Vehicle, viewModel: VehicleViewModel = VehicleViewModel(), appViewModel: AppViewModel = AppViewModel()) {
        self.vehicle = vehicle
        self.viewModel = viewModel
        self.appViewModel = appViewModel
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Header Section
                    VStack(spacing: 16) {
                        // Araç ikonu ve adı
                        VStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(vehicleIconColor.opacity(0.15))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: vehicleIcon)
                                    .font(.system(size: 40))
                                    .foregroundColor(vehicleIconColor)
                            }
                            
                            VStack(spacing: 4) {
                                Text(vehicle.displayName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text(vehicle.plateNumber)
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Durum badge'i
                        HStack(spacing: 8) {
                            Circle()
                                .fill(vehicle.isActive ? Color.green : Color.red)
                                .frame(width: 12, height: 12)
                            
                            Text(vehicle.statusText)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(vehicle.isActive ? Color.green : Color.red)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background((vehicle.isActive ? Color.green : Color.red).opacity(0.1))
                        .cornerRadius(20)
                    }
                    .padding(.top, 20)
                    
                    // Araç Bilgileri
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Araç Bilgileri")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            DetailRow(title: "Marka", value: vehicle.brand, icon: "car.fill")
                            DetailRow(title: "Model", value: vehicle.model, icon: "car.fill")
                            DetailRow(title: "Yıl", value: "\(vehicle.year)", icon: "calendar")
                            DetailRow(title: "Kapasite", value: "\(vehicle.capacity) kişi", icon: "person.2.fill")
                            DetailRow(title: "Renk", value: vehicle.color, icon: "paintbrush.fill")
                            DetailRow(title: "Araç Tipi", value: vehicle.vehicleType.displayName, icon: "car.2.fill")
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Belge Durumları
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Belge Durumları")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            DocumentDetailRow(
                                title: "Sigorta",
                                status: vehicle.insuranceStatus,
                                expiryDate: vehicle.insuranceExpiryDate,
                                statusColor: vehicle.insuranceStatusColor,
                                icon: "doc.text.fill"
                            )
                            
                            DocumentDetailRow(
                                title: "Muayene",
                                status: vehicle.inspectionStatus,
                                expiryDate: vehicle.inspectionExpiryDate,
                                statusColor: vehicle.inspectionStatusColor,
                                icon: "checkmark.seal.fill"
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Uyarılar
                    if vehicle.daysUntilInsuranceExpiry < 0 || vehicle.daysUntilInspectionExpiry < 0 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Uyarılar")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                            
                            WarningDetailBanner(
                                icon: "exclamationmark.triangle.fill",
                                message: "Süresi dolmuş belgeler var!",
                                color: Color.red
                            )
                        }
                        .padding(.horizontal, 20)
                    } else if vehicle.daysUntilInsuranceExpiry <= 30 || vehicle.daysUntilInspectionExpiry <= 30 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Uyarılar")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            
                            WarningDetailBanner(
                                icon: "clock.fill",
                                message: "Yakında süresi dolacak belgeler var!",
                                color: .orange
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Aksiyon Butonları
                    VStack(spacing: 16) {
                        Text("İşlemler")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            // Düzenle Butonu
                            Button(action: {
                                showingEditSheet = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "pencil")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                    
                                    Text("Aracı Düzenle")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                            
                            // Durum Değiştir Butonu
                            Button(action: {
                                viewModel.toggleVehicleStatus(vehicle)
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: vehicle.isActive ? "pause.circle" : "play.circle")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                    
                                    Text(vehicle.isActive ? "Aracı Pasifleştir" : "Aracı Aktifleştir")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                                .background(vehicle.isActive ? Color.orange : Color.green)
                                .cornerRadius(12)
                            }
                            
                            // Sil Butonu
                            Button(action: {
                                showingDeleteAlert = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "trash")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                    
                                    Text("Aracı Sil")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
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
            .navigationTitle("Araç Detayları")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Kapat") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .sheet(isPresented: $showingEditSheet) {
                AddEditVehicleView(
                    vehicle: vehicle,
                    viewModel: viewModel,
                    appViewModel: appViewModel
                )
            }
            .alert("Aracı Sil", isPresented: $showingDeleteAlert) {
                Button("İptal", role: .cancel) { }
                Button("Sil", role: .destructive) {
                    viewModel.deleteVehicle(vehicle)
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Bu aracı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.")
            }
        }
    }
    
    // Araç ikonu
    private var vehicleIcon: String {
        switch vehicle.vehicleType {
        case .sedan:
            return "car.fill"
        case .suv:
            return "car.fill"
        case .minivan:
            return "car.fill"
        case .bus:
            return "bus.fill"
        case .van:
            return "car.fill"
        case .pickup:
            return "car.fill"
        }
    }
    
    // Araç ikon rengi
    private var vehicleIconColor: Color {
        switch vehicle.vehicleType {
        case .sedan:
            return .blue
        case .suv:
            return Color.green
        case .minivan:
            return .orange
        case .bus:
            return .purple
        case .van:
            return Color.red
        case .pickup:
            return .brown
        }
    }
}

// MARK: - Detail Helper Views

struct DetailRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DocumentDetailRow: View {
    let title: String
    let status: String
    let expiryDate: Date
    let statusColor: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(statusColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    
                    Text(status)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(statusColor)
                }
                
                Text("Bitiş: \(expiryDate, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(statusColor.opacity(0.1))
        .cornerRadius(12)
    }
}

struct WarningDetailBanner: View {
    let icon: String
    let message: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(message)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(color)
            
            Spacer()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.locale = Locale(identifier: "tr_TR")
    return formatter
}()

struct VehicleManagementView_Previews: PreviewProvider {
    static var previews: some View {
        VehicleManagementView()
    }
}
