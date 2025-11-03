import SwiftUI
import FirebaseAuth
import Combine

struct ProfileView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var profileViewModel = ProfileViewModel()
    @StateObject private var statisticsService = StatisticsService()
    @State private var showingLogoutAlert = false
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    @State private var showingHelpSupport = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 120, height: 120)
                            
                            Text(getUserInitials())
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        
                        // User Info
                        VStack(spacing: 8) {
                            Text(getUserDisplayName())
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text(getUserEmail())
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if let profile = profileViewModel.userProfile {
                                Text(profile.userType.displayName)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(12)
                            } else if profileViewModel.isLoading {
                                Text("Profil yükleniyor...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Profil oluşturuluyor...")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            
                            if let company = appViewModel.currentCompany {
                                Text(company.name)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.green.opacity(0.1))
                                    .foregroundColor(.green)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.top, 20)
                    
                    // Profile Sections
                    VStack(spacing: 16) {
                        // Account Information
                        ProfileSectionView(
                            title: "Hesap Bilgileri",
                            icon: "person.circle.fill",
                            iconColor: .blue
                        ) {
                            VStack(spacing: 12) {
                                ProfileInfoRow(
                                    icon: "envelope.fill",
                                    title: "E-posta",
                                    value: getUserEmail(),
                                    iconColor: .green
                                )
                                
                                ProfileInfoRow(
                                    icon: "building.2.fill",
                                    title: "Şirket",
                                    value: getCompanyName(),
                                    iconColor: .orange
                                )
                                
                                ProfileInfoRow(
                                    icon: "calendar.badge.clock",
                                    title: "Üyelik Tarihi",
                                    value: getJoinDate(),
                                    iconColor: .purple
                                )
                            }
                        }
                        
                        // Statistics
                        ProfileSectionView(
                            title: "İstatistikler",
                            icon: "chart.bar.fill",
                            iconColor: .green
                        ) {
                            HStack(spacing: 20) {
                                StatCard(
                                    title: "Toplam Araç",
                                    value: statisticsService.isLoading ? "..." : "\(statisticsService.totalVehicles)",
                                    icon: "car.fill",
                                    color: .blue
                                )
                                
                                StatCard(
                                    title: "Aktif Şoför",
                                    value: statisticsService.isLoading ? "..." : "\(statisticsService.activeDrivers)",
                                    icon: "person.fill",
                                    color: .green
                                )
                                
                                StatCard(
                                    title: "Bu Ay İş",
                                    value: statisticsService.isLoading ? "..." : "\(statisticsService.todaysTrips)",
                                    icon: "list.bullet",
                                    color: .orange
                                )
                            }
                        }
                        
                        // Quick Actions
                        ProfileSectionView(
                            title: "Hızlı İşlemler",
                            icon: "bolt.fill",
                            iconColor: .yellow
                        ) {
                            VStack(spacing: 12) {
                                ProfileActionButton(
                                    title: "Profil Düzenle",
                                    icon: "pencil.circle.fill",
                                    iconColor: .blue
                                ) {
                                    showingEditProfile = true
                                }
                                
                                ProfileActionButton(
                                    title: "Ayarlar",
                                    icon: "gearshape.fill",
                                    iconColor: .gray
                                ) {
                                    showingSettings = true
                                }
                                
                                ProfileActionButton(
                                    title: "Yardım & Destek",
                                    icon: "questionmark.circle.fill",
                                    iconColor: .green
                                ) {
                                    showingHelpSupport = true
                                }
                            }
                        }
                        
                        // Logout Section
                        VStack(spacing: 16) {
                            Button(action: {
                                showingLogoutAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    
                                    Text("Çıkış Yap")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.red, .pink]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                        .padding(.top, 20)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.large)
            .alert("Çıkış Yap", isPresented: $showingLogoutAlert) {
                Button("İptal", role: .cancel) { }
                Button("Çıkış Yap", role: .destructive) {
                    appViewModel.signOut()
                }
            } message: {
                Text("Hesabınızdan çıkmak istediğinizden emin misiniz?")
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingHelpSupport) {
                HelpSupportView()
            }
            .onAppear {
                if let companyId = appViewModel.currentCompany?.id {
                    statisticsService.startRealTimeUpdates(for: companyId)
                }
                
                // Load user profile
                profileViewModel.loadUserProfile()
                
                // Firebase Auth displayName'i güncelle
                updateFirebaseDisplayName()
            }
            .onDisappear {
                statisticsService.stopRealTimeUpdates()
            }
            .overlay(
                Group {
                    if profileViewModel.isLoading {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Yükleniyor...")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.top, 8)
                        }
                    }
                }
            )
            .alert("Hata", isPresented: .constant(!profileViewModel.errorMessage.isEmpty)) {
                Button("Tamam") {
                    profileViewModel.clearMessages()
                }
            } message: {
                Text(profileViewModel.errorMessage)
            }
            .alert("Başarılı", isPresented: .constant(!profileViewModel.successMessage.isEmpty)) {
                Button("Tamam") {
                    profileViewModel.clearMessages()
                }
            } message: {
                Text(profileViewModel.successMessage)
            }
        }
    }
    
    // MARK: - Helper Functions
    private func getUserDisplayName() -> String {
        if let profile = profileViewModel.userProfile {
            return profile.fullName.isEmpty ? "Ad Soyad Girin" : profile.fullName
        } else if let user = appViewModel.currentUser {
            return user.displayName?.isEmpty == false ? user.displayName! : "Ad Soyad Girin"
        }
        return "Ad Soyad Girin"
    }
    
    private func getUserEmail() -> String {
        if let profile = profileViewModel.userProfile {
            return profile.email
        }
        return appViewModel.currentUser?.email ?? "E-posta bulunamadı"
    }
    
    private func getUserInitials() -> String {
        let name = getUserDisplayName()
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1)) + String(components[1].prefix(1))
        } else {
            return String(name.prefix(2))
        }
    }
    
    private func getCompanyName() -> String {
        if let company = appViewModel.currentCompany {
            return company.name
        } else if let profile = profileViewModel.userProfile, profile.userType == .companyAdmin {
            return "Şirket bilgisi yükleniyor..."
        } else {
            return "Şirket bilgisi yok"
        }
    }
    
    private func getJoinDate() -> String {
        if let user = appViewModel.currentUser {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.locale = Locale(identifier: "tr_TR")
            return formatter.string(from: user.metadata.creationDate ?? Date())
        }
        return "Bilinmiyor"
    }
    
    private func updateFirebaseDisplayName() {
        guard let user = Auth.auth().currentUser,
              let profile = profileViewModel.userProfile,
              !profile.fullName.isEmpty,
              user.displayName != profile.fullName else { return }
        
        Task {
            do {
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = profile.fullName
                try await changeRequest.commitChanges()
            } catch {
                print("Firebase displayName güncellenirken hata: \(error)")
            }
        }
    }
}

// MARK: - Supporting Views
struct ProfileSectionView<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content
    
    init(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            content
        }
        .padding()
        .background(ShuttleTrackTheme.Colors.background)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct ProfileInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let iconColor: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ProfileActionButton: View {
    let title: String
    let icon: String
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
                    .frame(width: 24)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var profileViewModel = ProfileViewModel()
    
    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var selectedUserType: UserType = .companyAdmin
    @State private var showingPasswordChange = false
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Kişisel Bilgiler")) {
                    TextField("Ad Soyad", text: $fullName)
                        .textFieldStyle(ShuttleTrackTextFieldStyle())
                    
                    TextField("E-posta", text: $email)
                        .textFieldStyle(ShuttleTrackTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disabled(true) // Email can't be changed easily
                    
                    TextField("Telefon", text: $phone)
                        .textFieldStyle(ShuttleTrackTextFieldStyle())
                        .keyboardType(.phonePad)
                    
                    // Sürücü panelinde kullanıcı tipi değiştirilemez
                    if appViewModel.currentUserProfile?.userType != .driver {
                        Picker("Kullanıcı Tipi", selection: $selectedUserType) {
                            ForEach(UserType.allCases, id: \.self) { userType in
                                Text(userType.displayName).tag(userType)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                Section(header: Text("Şirket Bilgileri")) {
                    if let company = appViewModel.currentCompany {
                        HStack {
                            Text("Şirket Adı")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(company.name)
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            Text("Şirket E-posta")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(company.email)
                                .foregroundColor(.primary)
                        }
                    } else {
                        HStack {
                            Text("Şirket Bilgileri")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Yükleniyor...")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Güvenlik")) {
                    Button("Şifre Değiştir") {
                        showingPasswordChange = true
                    }
                    .foregroundColor(.blue)
                }
                
                if !profileViewModel.errorMessage.isEmpty {
                    Section {
                        Text(profileViewModel.errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                if !profileViewModel.successMessage.isEmpty {
                    Section {
                        Text(profileViewModel.successMessage)
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Profil Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("İptal") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Kaydet") {
                    saveProfile()
                }
                .disabled(profileViewModel.isLoading)
            )
            .onAppear {
                loadCurrentProfile()
            }
            .onReceive(profileViewModel.$userProfile) { profile in
                // ProfileViewModel'den veri geldiğinde form alanlarını güncelle
                if let profile = profile {
                    fullName = profile.fullName
                    email = profile.email
                    phone = profile.phone ?? ""
                    selectedUserType = profile.userType
                }
            }
            .sheet(isPresented: $showingPasswordChange) {
                PasswordChangeView(
                    currentPassword: $currentPassword,
                    newPassword: $newPassword,
                    confirmPassword: $confirmPassword,
                    profileViewModel: profileViewModel
                )
            }
        }
    }
    
    private func loadCurrentProfile() {
        // Önce ProfileViewModel'den veri yüklemeyi dene
        if let profile = profileViewModel.userProfile {
            fullName = profile.fullName
            email = profile.email
            phone = profile.phone ?? ""
            selectedUserType = profile.userType
        } else {
            // ProfileViewModel'de veri yoksa Firebase Auth'dan yükle
            if let user = appViewModel.currentUser {
                fullName = user.displayName ?? ""
                email = user.email ?? ""
                phone = ""
                selectedUserType = .companyAdmin // Default user type
            }
            
            // ProfileViewModel'den veri yüklemeyi tekrar dene
            profileViewModel.loadUserProfile()
        }
    }
    
    private func saveProfile() {
        let finalUserType: UserType = (appViewModel.currentUserProfile?.userType == .driver) ? .driver : selectedUserType
        profileViewModel.updateProfile(
            fullName: fullName,
            phone: phone.isEmpty ? nil : phone,
            userType: finalUserType
        )
        
        // Close the view after a short delay to show success message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if profileViewModel.successMessage.isEmpty == false {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

struct PasswordChangeView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var currentPassword: String
    @Binding var newPassword: String
    @Binding var confirmPassword: String
    @ObservedObject var profileViewModel: ProfileViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Mevcut Şifre")) {
                    SecureField("Mevcut Şifre", text: $currentPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section(header: Text("Yeni Şifre")) {
                    SecureField("Yeni Şifre", text: $newPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    SecureField("Şifre Tekrar", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                if !profileViewModel.errorMessage.isEmpty {
                    Section {
                        Text(profileViewModel.errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                if !profileViewModel.successMessage.isEmpty {
                    Section {
                        Text(profileViewModel.successMessage)
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Şifre Değiştir")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("İptal") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Kaydet") {
                    changePassword()
                }
                .disabled(profileViewModel.isLoading || !isPasswordValid)
            )
        }
    }
    
    private var isPasswordValid: Bool {
        return !currentPassword.isEmpty &&
               !newPassword.isEmpty &&
               newPassword == confirmPassword &&
               newPassword.count >= 6
    }
    
    private func changePassword() {
        profileViewModel.updatePassword(
            currentPassword: currentPassword,
            newPassword: newPassword
        )
        
        // Close the view after a short delay to show success message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if profileViewModel.successMessage.isEmpty == false {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
