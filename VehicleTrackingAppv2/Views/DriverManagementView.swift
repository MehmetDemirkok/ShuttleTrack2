import SwiftUI

struct DriverManagementView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = DriverViewModel()
    @State private var showingAddDriver = false
    @State private var showingDriverDetail = false
    @State private var driverForDetail: Driver?
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        
                        Text("Sürücüler yükleniyor...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Bu işlem birkaç saniye sürebilir")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.drivers.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Henüz sürücü eklenmemiş")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("İlk sürücünüzü eklemek için + butonuna tıklayın")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.drivers) { driver in
                            DriverRowView(
                                driver: driver,
                                onTap: {
                                    driverForDetail = driver
                                    showingDriverDetail = true
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
            .background(ShuttleTrackTheme.Colors.background)
            .navigationTitle("Sürücüler")
            .navigationBarItems(
                trailing: Button(action: {
                    showingAddDriver = true
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                }
            )
            .onAppear {
                loadDrivers()
            }
            .sheet(isPresented: $showingAddDriver) {
                AddEditDriverView(viewModel: viewModel, appViewModel: appViewModel)
            }
            .sheet(isPresented: $showingDriverDetail) {
                if let driver = driverForDetail {
                    DriverDetailView(driver: driver, viewModel: viewModel, appViewModel: appViewModel)
                }
            }
        }
    }
    
    private func loadDrivers() {
        guard let companyId = appViewModel.currentCompany?.id else { return }
        viewModel.fetchDrivers(for: companyId)
    }
}

struct DriverRowView: View {
    let driver: Driver
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Ana kart içeriği - Küçültülmüş
            VStack(alignment: .leading, spacing: 12) {
                // Header - Sürücü adı ve durum
                HStack(alignment: .top) {
                    // Sürücü ikonu - Küçültülmüş
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "person.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(driver.fullName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(driver.phoneNumber)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Durum badge'i - Küçültülmüş
                    HStack(spacing: 4) {
                        Circle()
                            .fill(driver.isActive ? Color.green : Color.red)
                            .frame(width: 6, height: 6)
                        
                        Text(driver.statusText)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(driver.isActive ? Color.green : Color.red)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((driver.isActive ? Color.green : Color.red).opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Araç atama durumu
                if driver.assignedVehicleId != nil {
                    HStack(spacing: 6) {
                        Image(systemName: "car.fill")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        
                        Text("Araç Atanmış")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "car")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        
                        Text("Araç Atanmamış")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
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

// MARK: - Driver Detail View

struct DriverDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    let driver: Driver
    let viewModel: DriverViewModel
    let appViewModel: AppViewModel
    
    init(driver: Driver, viewModel: DriverViewModel = DriverViewModel(), appViewModel: AppViewModel = AppViewModel()) {
        self.driver = driver
        self.viewModel = viewModel
        self.appViewModel = appViewModel
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(spacing: 16) {
                        // Sürücü ikonu ve adı
                        VStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.blue.opacity(0.15))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(spacing: 4) {
                                Text(driver.fullName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text(driver.phoneNumber)
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Durum badge'i
                        HStack(spacing: 8) {
                            Circle()
                                .fill(driver.isActive ? Color.green : Color.red)
                                .frame(width: 12, height: 12)
                            
                            Text(driver.statusText)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(driver.isActive ? Color.green : Color.red)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background((driver.isActive ? Color.green : Color.red).opacity(0.1))
                        .cornerRadius(20)
                    }
                    .padding(.top, 20)
                    
                    // Sürücü Bilgileri
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Sürücü Bilgileri")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            DriverDetailRow(title: "Ad", value: driver.firstName, icon: "person.fill")
                            DriverDetailRow(title: "Soyad", value: driver.lastName, icon: "person.fill")
                            DriverDetailRow(title: "Telefon", value: driver.phoneNumber, icon: "phone.fill")
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Araç Atama Durumu
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Araç Durumu")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        if driver.assignedVehicleId != nil {
                            HStack(spacing: 12) {
                                Image(systemName: "car.fill")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Araç Atanmış")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                    
                                    Text("Bu sürücüye bir araç atanmış durumda")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        } else {
                            HStack(spacing: 12) {
                                Image(systemName: "car")
                                    .font(.title3)
                                    .foregroundColor(.orange)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Araç Atanmamış")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.orange)
                                    
                                    Text("Bu sürücüye henüz araç atanmamış")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    
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
                                    
                                    Text("Sürücüyü Düzenle")
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
                                viewModel.toggleDriverStatus(driver)
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: driver.isActive ? "pause.circle" : "play.circle")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                    
                                    Text(driver.isActive ? "Sürücüyü Pasifleştir" : "Sürücüyü Aktifleştir")
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
                                .background(driver.isActive ? Color.orange : Color.green)
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
                                    
                                    Text("Sürücüyü Sil")
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
            .navigationTitle("Sürücü Detayları")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Kapat") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .sheet(isPresented: $showingEditSheet) {
                AddEditDriverView(
                    driver: driver,
                    viewModel: viewModel,
                    appViewModel: appViewModel
                )
            }
            .alert("Sürücüyü Sil", isPresented: $showingDeleteAlert) {
                Button("İptal", role: .cancel) { }
                Button("Sil", role: .destructive) {
                    viewModel.deleteDriver(driver)
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Bu sürücüyü silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.")
            }
        }
    }
}

// MARK: - Detail Helper Views

struct DriverDetailRow: View {
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

struct DriverManagementView_Previews: PreviewProvider {
    static var previews: some View {
        DriverManagementView()
    }
}
