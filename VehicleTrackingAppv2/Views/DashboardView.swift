import SwiftUI
import FirebaseAuth
import Foundation

struct DashboardView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var statisticsService = StatisticsService()
    @StateObject private var tripViewModel = TripViewModel()
    @StateObject private var vehicleViewModel = VehicleViewModel()
    @StateObject private var driverViewModel = DriverViewModel()
    @State private var selectedTab = 0
    @State private var showingProfile = false
    @State private var showAdminPanel = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Ana Sayfa
            NavigationView {
                VStack(spacing: 0) {
                    // Modern Header
                    VStack(spacing: 0) {
                        // Top Section with Logo and Title
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Shuttle Track")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text("Hoş geldiniz!")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Text(getUserName())
                                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            // Modern Logo
                            Button(action: {
                                showingProfile = true
                            }) {
                                CompactLogoView(size: 60)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // Company Info with Modern Design
                        if let company = appViewModel.currentCompany {
                            HStack(spacing: 8) {
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                                
                                Text(company.name.uppercased())
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.blue)
                                    .tracking(0.5)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 20)
                        }
                    }
                    .background(Color(.systemBackground))
                    
                    Spacer()
                    
                    // Modern Statistics Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Hızlı İstatistikler")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 20)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ModernStatCard(
                                title: "Toplam Araç", 
                                value: statisticsService.isLoading ? "..." : "\(statisticsService.totalVehicles)", 
                                icon: "car.fill", 
                                color: .blue
                            )
                            ModernStatCard(
                                title: "Aktif Sürücü", 
                                value: statisticsService.isLoading ? "..." : "\(statisticsService.activeDrivers)", 
                                icon: "person.fill", 
                                color: .green
                            )
                            ModernStatCard(
                                title: "Bugünkü İşler", 
                                value: statisticsService.isLoading ? "..." : "\(statisticsService.todaysTrips)", 
                                icon: "list.bullet", 
                                color: .orange
                            )
                            ModernStatCard(
                                title: "Tamamlanan", 
                                value: statisticsService.isLoading ? "..." : "\(statisticsService.completedTrips)", 
                                icon: "checkmark.circle.fill", 
                                color: .purple
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                    
                    // Modern Quick Actions
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Hızlı İşlemler")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 20)
                        
                        HStack(spacing: 16) {
                            ModernQuickActionButton(
                                title: "Araç Ekle",
                                icon: "plus.circle.fill",
                                color: .blue
                            ) {
                                selectedTab = 1
                            }
                            
                            ModernQuickActionButton(
                                title: "Sürücü Ekle",
                                icon: "person.badge.plus",
                                color: .green
                            ) {
                                selectedTab = 2
                            }
                            
                            ModernQuickActionButton(
                                title: "İş Oluştur",
                                icon: "list.bullet",
                                color: .orange
                            ) {
                                selectedTab = 3
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 30)
                }
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Ana Sayfa")
            }
            .tag(0)
            
            // Araç Yönetimi
            VehicleManagementView()
                .tabItem {
                    Image(systemName: "car.fill")
                    Text("Araçlar")
                }
                .tag(1)
            
            // Şoför Yönetimi (sadece admin)
            if appViewModel.currentUserProfile?.userType == .companyAdmin {
                DriverManagementView()
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("Sürücüler")
                    }
                    .tag(2)
            }
            
            // İş Atama (sadece admin)
            if appViewModel.currentUserProfile?.userType == .companyAdmin {
                TripAssignmentView()
                    .tabItem {
                        Image(systemName: "list.bullet")
                        Text("İşler")
                    }
                    .tag(3)
            }
            
            // Takip (herkes)
            TrackingView()
                .tabItem {
                    Image(systemName: "location.fill")
                    Text("Takip")
                }
                .tag(4)
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
        }
        .onAppear {
            loadData()
            if appViewModel.currentUserProfile?.userType == .owner {
                showAdminPanel = true
            }
        }
        .fullScreenCover(isPresented: $showAdminPanel) {
            AdminPanelView()
        }
        .onChange(of: appViewModel.currentCompany?.id) { oldValue, newValue in
            // Şirket bilgisi sonradan geldiğinde istatistikleri ve listeleri yükle
            if let companyId = newValue {
                print("🔁 Company ID değişti: \(companyId) — dashboard verileri yeniden yükleniyor")
                statisticsService.fetchStatistics(for: companyId)
                tripViewModel.fetchTrips(for: companyId)
                vehicleViewModel.fetchVehicles(for: companyId)
                driverViewModel.fetchDrivers(for: companyId)
            }
        }
        .onDisappear {
            statisticsService.stopRealTimeUpdates()
        }
        .alert("İstatistik Hatası", isPresented: .constant(!statisticsService.errorMessage.isEmpty)) {
            Button("Tamam") {
                statisticsService.clearError()
            }
        } message: {
            Text(statisticsService.errorMessage)
        }
    }
    
    // MARK: - Helper Functions
    private func loadData() {
        guard let companyId = appViewModel.currentCompany?.id else {
            print("❌ Dashboard: Company ID bulunamadı")
            return
        }
        
        print("🏠 Dashboard yüklendi - Company ID: \(companyId)")
        
        // Tüm verileri paralel olarak yükle (her ViewModel kendi thread yönetimini yapıyor)
        statisticsService.fetchStatistics(for: companyId)
        tripViewModel.fetchTrips(for: companyId)
        vehicleViewModel.fetchVehicles(for: companyId)
        driverViewModel.fetchDrivers(for: companyId)
    }
    
    private func getUserName() -> String {
        // Önce Firebase user'dan displayName al
        if let user = appViewModel.currentUser, let displayName = user.displayName, !displayName.isEmpty {
            return displayName
        }
        
        // Sonra currentUserProfile'den al
        if let profile = appViewModel.currentUserProfile, !profile.fullName.isEmpty {
            return profile.fullName
        }
        
        return "Kullanıcı"
    }
    
    private func getUserInitials() -> String {
        let name = getUserName()
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1)) + String(components[1].prefix(1))
        } else {
            return String(name.prefix(2))
        }
    }
}


// MARK: - Modern Stat Card
struct ModernStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Modern Quick Action Button
struct ModernQuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Legacy Components (kept for compatibility)
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
