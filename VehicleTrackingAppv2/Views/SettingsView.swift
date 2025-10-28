import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var notificationsEnabled = true
    @State private var darkModeEnabled = false
    @State private var autoSyncEnabled = true
    @State private var showingLanguagePicker = false
    @State private var selectedLanguage = "Türkçe"
    @State private var showingAbout = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(ShuttleTrackTheme.Gradients.primary)
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                        .shadow(color: ShuttleTrackTheme.Shadows.medium, radius: 10, x: 0, y: 5)
                        
                        Text("Ayarlar")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Uygulama tercihlerinizi buradan yönetebilirsiniz")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Settings Sections
                    VStack(spacing: 16) {
                        // Genel Ayarlar
                        SettingsSectionView(
                            title: "Genel",
                            icon: "slider.horizontal.3",
                            iconColor: .blue
                        ) {
                            VStack(spacing: 12) {
                                SettingsToggleRow(
                                    title: "Bildirimler",
                                    subtitle: "Push bildirimleri al",
                                    icon: "bell.fill",
                                    iconColor: .orange,
                                    isOn: $notificationsEnabled
                                )
                                
                                SettingsToggleRow(
                                    title: "Karanlık Mod",
                                    subtitle: "Otomatik tema değişimi",
                                    icon: "moon.fill",
                                    iconColor: .purple,
                                    isOn: $darkModeEnabled
                                )
                                
                                SettingsToggleRow(
                                    title: "Otomatik Senkronizasyon",
                                    subtitle: "Verileri otomatik güncelle",
                                    icon: "arrow.clockwise.circle.fill",
                                    iconColor: .green,
                                    isOn: $autoSyncEnabled
                                )
                                
                                SettingsNavigationRow(
                                    title: "Dil",
                                    subtitle: selectedLanguage,
                                    icon: "globe",
                                    iconColor: .blue
                                ) {
                                    showingLanguagePicker = true
                                }
                            }
                        }
                        
                        // Hesap Ayarları
                        SettingsSectionView(
                            title: "Hesap",
                            icon: "person.circle.fill",
                            iconColor: .green
                        ) {
                            VStack(spacing: 12) {
                                SettingsNavigationRow(
                                    title: "Profil Düzenle",
                                    subtitle: "Kişisel bilgilerinizi güncelleyin",
                                    icon: "pencil.circle.fill",
                                    iconColor: .blue
                                ) {
                                    // Profile edit action
                                }
                                
                                SettingsNavigationRow(
                                    title: "Şifre Değiştir",
                                    subtitle: "Hesap güvenliğinizi artırın",
                                    icon: "key.fill",
                                    iconColor: .orange
                                ) {
                                    // Password change action
                                }
                                
                                SettingsNavigationRow(
                                    title: "Hesap Bilgileri",
                                    subtitle: "E-posta ve telefon bilgileri",
                                    icon: "info.circle.fill",
                                    iconColor: .purple
                                ) {
                                    // Account info action
                                }
                            }
                        }
                        
                        // Uygulama Bilgileri
                        SettingsSectionView(
                            title: "Uygulama",
                            icon: "app.fill",
                            iconColor: .purple
                        ) {
                            VStack(spacing: 12) {
                                SettingsNavigationRow(
                                    title: "Hakkında",
                                    subtitle: "Sürüm ve geliştirici bilgileri",
                                    icon: "info.circle.fill",
                                    iconColor: .blue
                                ) {
                                    showingAbout = true
                                }
                                
                                SettingsNavigationRow(
                                    title: "Gizlilik Politikası",
                                    subtitle: "Veri kullanımı ve gizlilik",
                                    icon: "hand.raised.fill",
                                    iconColor: .green
                                ) {
                                    showingPrivacyPolicy = true
                                }
                                
                                SettingsNavigationRow(
                                    title: "Kullanım Şartları",
                                    subtitle: "Hizmet şartları ve koşulları",
                                    icon: "doc.text.fill",
                                    iconColor: .orange
                                ) {
                                    showingTermsOfService = true
                                }
                                
                                SettingsNavigationRow(
                                    title: "Verileri Temizle",
                                    subtitle: "Önbellek ve geçici dosyaları sil",
                                    icon: "trash.fill",
                                    iconColor: .red
                                ) {
                                    clearAppData()
                                }
                            }
                        }
                        
                        // Destek
                        SettingsSectionView(
                            title: "Destek",
                            icon: "questionmark.circle.fill",
                            iconColor: .orange
                        ) {
                            VStack(spacing: 12) {
                                SettingsNavigationRow(
                                    title: "Yardım Merkezi",
                                    subtitle: "Sık sorulan sorular",
                                    icon: "questionmark.circle.fill",
                                    iconColor: .blue
                                ) {
                                    // Help center action
                                }
                                
                                SettingsNavigationRow(
                                    title: "İletişim",
                                    subtitle: "Bizimle iletişime geçin",
                                    icon: "envelope.fill",
                                    iconColor: .green
                                ) {
                                    // Contact action
                                }
                                
                                SettingsNavigationRow(
                                    title: "Geri Bildirim",
                                    subtitle: "Önerilerinizi paylaşın",
                                    icon: "bubble.left.fill",
                                    iconColor: .purple
                                ) {
                                    // Feedback action
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Kapat") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .sheet(isPresented: $showingLanguagePicker) {
                LanguagePickerView(selectedLanguage: $selectedLanguage)
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $showingTermsOfService) {
                TermsOfServiceView()
            }
        }
    }
    
    private func clearAppData() {
        // Clear app data implementation
        print("App data cleared")
    }
}

// MARK: - Settings Section View
struct SettingsSectionView<Content: View>: View {
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
        .padding(ShuttleTrackTheme.Spacing.md)
        .background(ShuttleTrackTheme.Colors.cardBackground)
        .cornerRadius(ShuttleTrackTheme.CornerRadius.large)
        .shadow(color: ShuttleTrackTheme.Shadows.small, radius: 8, x: 0, y: 2)
    }
}

// MARK: - Settings Row Views
struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: ShuttleTrackTheme.Colors.primaryBlue))
        }
        .padding(.vertical, 8)
    }
}

struct SettingsNavigationRow: View {
    let title: String
    let subtitle: String
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
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Supporting Views
struct LanguagePickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedLanguage: String
    
    private let languages = ["Türkçe", "English", "العربية", "Français", "Deutsch"]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(languages, id: \.self) { language in
                    Button(action: {
                        selectedLanguage = language
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Text(language)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedLanguage == language {
                                Image(systemName: "checkmark")
                                    .foregroundColor(ShuttleTrackTheme.Colors.primaryBlue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Dil Seçimi")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Kapat") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App Icon and Info
                    VStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(ShuttleTrackTheme.Gradients.primary)
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "airplane.departure")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        .shadow(color: ShuttleTrackTheme.Shadows.medium, radius: 10, x: 0, y: 5)
                        
                        Text("Shuttle Track")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Sürüm 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // App Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Hakkında")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Shuttle Track, havayolu transfer hizmetlerini yönetmek için tasarlanmış kapsamlı bir mobil uygulamadır. Araç takibi, sürücü yönetimi, müşteri hizmetleri ve raporlama özellikleri ile transfer operasyonlarınızı kolaylaştırır.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 20)
                    
                    // Developer Info
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Geliştirici")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Mehmet Demirkok")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("iOS Developer")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Hakkında")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Kapat") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Gizlilik Politikası")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Veri Toplama")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Uygulamamız, hizmet kalitesini artırmak ve kullanıcı deneyimini iyileştirmek için sınırlı miktarda kişisel veri toplar. Toplanan veriler arasında e-posta adresi, telefon numarası ve konum bilgileri bulunmaktadır.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Veri Kullanımı")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Toplanan veriler sadece hizmet sunumu, müşteri desteği ve uygulama geliştirme amaçları için kullanılır. Verileriniz üçüncü taraflarla paylaşılmaz ve güvenli sunucularda saklanır.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Veri Güvenliği")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Verilerinizin güvenliği bizim için önemlidir. Endüstri standardı şifreleme yöntemleri kullanarak verilerinizi koruruz ve düzenli güvenlik güncellemeleri yaparız.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Gizlilik Politikası")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Kapat") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct TermsOfServiceView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Kullanım Şartları")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Hizmet Kullanımı")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Bu uygulamayı kullanarak, hizmet şartlarımızı kabul etmiş olursunuz. Uygulamayı yalnızca yasal amaçlar için kullanmalı ve başkalarının haklarını ihlal etmemelisiniz.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Kullanıcı Sorumlulukları")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Kullanıcılar, hesap bilgilerinin doğruluğundan sorumludur. Şifre güvenliğinizi sağlamalı ve hesabınızın yetkisiz kullanımını derhal bildirmelisiniz.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Hizmet Değişiklikleri")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Hizmet şartlarını önceden bildirim yaparak değiştirme hakkımız saklıdır. Değişiklikler yürürlüğe girdikten sonra uygulamayı kullanmaya devam etmeniz, yeni şartları kabul ettiğiniz anlamına gelir.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Kullanım Şartları")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Kapat") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

