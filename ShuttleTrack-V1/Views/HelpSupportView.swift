import SwiftUI
import MessageUI

struct HelpSupportView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingContactForm = false
    @State private var showingFAQ = false
    @State private var showingTutorial = false
    @State private var showingFeedback = false
    @State private var searchText = ""
    @State private var selectedCategory: HelpCategory = .general
    
    enum HelpCategory: String, CaseIterable {
        case general = "Genel"
        case vehicles = "Araçlar"
        case drivers = "Sürücüler"
        case trips = "İşler"
        case tracking = "Takip"
        case account = "Hesap"
        
        var icon: String {
            switch self {
            case .general: return "questionmark.circle.fill"
            case .vehicles: return "car.fill"
            case .drivers: return "person.fill"
            case .trips: return "list.bullet"
            case .tracking: return "location.fill"
            case .account: return "person.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .general: return .blue
            case .vehicles: return .green
            case .drivers: return .orange
            case .trips: return .purple
            case .tracking: return .red
            case .account: return .teal
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(ShuttleTrackTheme.Gradients.success)
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                        .shadow(color: ShuttleTrackTheme.Shadows.medium, radius: 10, x: 0, y: 5)
                        
                        Text("Yardım & Destek")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Size nasıl yardımcı olabiliriz?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Search Bar
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            
                            TextField("Yardım konusu ara...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding()
                        .background(ShuttleTrackTheme.Colors.surfaceBackground)
                        .cornerRadius(ShuttleTrackTheme.CornerRadius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: ShuttleTrackTheme.CornerRadius.medium)
                                .stroke(ShuttleTrackTheme.Colors.borderColor, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Quick Actions
                    VStack(spacing: 16) {
                        Text("Hızlı Erişim")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            QuickActionCard(
                                title: "Sık Sorulan Sorular",
                                icon: "questionmark.circle.fill",
                                color: .blue
                            ) {
                                showingFAQ = true
                            }
                            
                            QuickActionCard(
                                title: "İletişim",
                                icon: "envelope.fill",
                                color: .green
                            ) {
                                showingContactForm = true
                            }
                            
                            QuickActionCard(
                                title: "Eğitim Videoları",
                                icon: "play.circle.fill",
                                color: .orange
                            ) {
                                showingTutorial = true
                            }
                            
                            QuickActionCard(
                                title: "Geri Bildirim",
                                icon: "bubble.left.fill",
                                color: .purple
                            ) {
                                showingFeedback = true
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Help Categories
                    VStack(spacing: 16) {
                        Text("Yardım Kategorileri")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(HelpCategory.allCases, id: \.self) { category in
                                CategoryCard(
                                    title: category.rawValue,
                                    icon: category.icon,
                                    color: category.color
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Contact Information
                    VStack(spacing: 16) {
                        Text("İletişim Bilgileri")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            ContactInfoRow(
                                title: "E-posta",
                                value: "destek@shuttletrack.com",
                                icon: "envelope.fill",
                                iconColor: .blue
                            ) {
                                // Email action
                            }
                            
                            ContactInfoRow(
                                title: "Telefon",
                                value: "+90 212 555 0123",
                                icon: "phone.fill",
                                iconColor: .green
                            ) {
                                // Phone action
                            }
                            
                            ContactInfoRow(
                                title: "WhatsApp",
                                value: "+90 212 555 0123",
                                icon: "message.fill",
                                iconColor: .green
                            ) {
                                // WhatsApp action
                            }
                            
                            ContactInfoRow(
                                title: "Çalışma Saatleri",
                                value: "Pazartesi - Cuma: 09:00 - 18:00",
                                icon: "clock.fill",
                                iconColor: .orange
                            ) {
                                // Working hours info
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Yardım & Destek")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Kapat") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .sheet(isPresented: $showingContactForm) {
                ContactFormView()
            }
            .sheet(isPresented: $showingFAQ) {
                FAQView()
            }
            .sheet(isPresented: $showingTutorial) {
                TutorialView()
            }
            .sheet(isPresented: $showingFeedback) {
                FeedbackView()
            }
        }
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
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
            .background(ShuttleTrackTheme.Colors.cardBackground)
            .cornerRadius(ShuttleTrackTheme.CornerRadius.large)
            .shadow(color: ShuttleTrackTheme.Shadows.small, radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(ShuttleTrackTheme.Colors.surfaceBackground)
            .cornerRadius(ShuttleTrackTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: ShuttleTrackTheme.CornerRadius.medium)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Contact Info Row
struct ContactInfoRow: View {
    let title: String
    let value: String
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
                    
                    Text(value)
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

// MARK: - Contact Form View
struct ContactFormView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var email = ""
    @State private var subject = ""
    @State private var message = ""
    @State private var selectedCategory = "Genel"
    @State private var showingSuccessAlert = false
    
    private let categories = ["Genel", "Teknik Sorun", "Hesap Sorunu", "Öneri", "Şikayet"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Kişisel Bilgiler")) {
                    TextField("Ad Soyad", text: $name)
                        .textFieldStyle(ShuttleTrackTextFieldStyle())
                    
                    TextField("E-posta", text: $email)
                        .textFieldStyle(ShuttleTrackTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    Picker("Kategori", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("Mesaj")) {
                    TextField("Konu", text: $subject)
                        .textFieldStyle(ShuttleTrackTextFieldStyle())
                    
                    TextField("Mesajınızı buraya yazın...", text: $message)
                        .textFieldStyle(ShuttleTrackTextFieldStyle())
                        .lineLimit(10)
                }
            }
            .navigationTitle("İletişim Formu")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("İptal") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Gönder") {
                    sendMessage()
                }
                .disabled(!isFormValid)
            )
            .alert("Mesaj Gönderildi", isPresented: $showingSuccessAlert) {
                Button("Tamam") {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Mesajınız başarıyla gönderildi. En kısa sürede size dönüş yapacağız.")
            }
        }
    }
    
    private var isFormValid: Bool {
        return !name.isEmpty && !email.isEmpty && !subject.isEmpty && !message.isEmpty
    }
    
    private func sendMessage() {
        // Send message implementation
        showingSuccessAlert = true
    }
}

// MARK: - FAQ View
struct FAQView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    @State private var expandedItems: Set<String> = []
    
    private let faqItems = [
        FAQItem(
            id: "1",
            question: "Nasıl araç ekleyebilirim?",
            answer: "Ana sayfada 'Araç Ekle' butonuna tıklayın veya Araçlar sekmesinden + butonunu kullanın. Araç bilgilerini doldurun ve kaydedin."
        ),
        FAQItem(
            id: "2",
            question: "Sürücü nasıl eklenir?",
            answer: "Sürücüler sekmesinden + butonuna tıklayın. Sürücü bilgilerini ve ehliyet bilgilerini doldurun."
        ),
        FAQItem(
            id: "3",
            question: "İş nasıl oluşturulur?",
            answer: "İşler sekmesinden + butonuna tıklayın. Müşteri bilgileri, alış ve varış noktalarını belirleyin."
        ),
        FAQItem(
            id: "4",
            question: "Araç takibi nasıl yapılır?",
            answer: "Takip sekmesinden aktif araçları görüntüleyebilir ve konumlarını takip edebilirsiniz."
        ),
        FAQItem(
            id: "5",
            question: "Şifremi nasıl değiştirebilirim?",
            answer: "Profil sayfasından 'Profil Düzenle' seçeneğini kullanın ve 'Şifre Değiştir' butonuna tıklayın."
        )
    ]
    
    var filteredItems: [FAQItem] {
        if searchText.isEmpty {
            return faqItems
        } else {
            return faqItems.filter { item in
                item.question.localizedCaseInsensitiveContains(searchText) ||
                item.answer.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("FAQ'da ara...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background(ShuttleTrackTheme.Colors.surfaceBackground)
                .cornerRadius(ShuttleTrackTheme.CornerRadius.medium)
                .padding(.horizontal)
                
                // FAQ List
                List {
                    ForEach(filteredItems) { item in
                        FAQRowView(
                            item: item,
                            isExpanded: expandedItems.contains(item.id)
                        ) {
                            if expandedItems.contains(item.id) {
                                expandedItems.remove(item.id)
                            } else {
                                expandedItems.insert(item.id)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Sık Sorulan Sorular")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Kapat") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct FAQItem: Identifiable {
    let id: String
    let question: String
    let answer: String
}

struct FAQRowView: View {
    let item: FAQItem
    let isExpanded: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: action) {
                HStack {
                    Text(item.question)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Text(item.answer)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
}

// MARK: - Tutorial View
struct TutorialView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Eğitim Videoları")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.top, 20)
                    
                    VStack(spacing: 16) {
                        TutorialVideoCard(
                            title: "Uygulamaya Giriş",
                            description: "Shuttle Track uygulamasını nasıl kullanacağınızı öğrenin",
                            duration: "5:30",
                            icon: "play.circle.fill",
                            color: .blue
                        )
                        
                        TutorialVideoCard(
                            title: "Araç Yönetimi",
                            description: "Araç ekleme, düzenleme ve takip işlemleri",
                            duration: "8:15",
                            icon: "car.fill",
                            color: .green
                        )
                        
                        TutorialVideoCard(
                            title: "Sürücü Yönetimi",
                            description: "Sürücü ekleme ve atama işlemleri",
                            duration: "6:45",
                            icon: "person.fill",
                            color: .orange
                        )
                        
                        TutorialVideoCard(
                            title: "İş Oluşturma",
                            description: "Transfer işi oluşturma ve yönetimi",
                            duration: "7:20",
                            icon: "list.bullet",
                            color: .purple
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Eğitim Videoları")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Kapat") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct TutorialVideoCard: View {
    let title: String
    let description: String
    let duration: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(duration)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Image(systemName: "play.fill")
                    .font(.caption)
                    .foregroundColor(color)
            }
        }
        .padding()
        .background(ShuttleTrackTheme.Colors.cardBackground)
        .cornerRadius(ShuttleTrackTheme.CornerRadius.large)
        .shadow(color: ShuttleTrackTheme.Shadows.small, radius: 8, x: 0, y: 2)
    }
}

// MARK: - Feedback View
struct FeedbackView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var feedbackText = ""
    @State private var rating = 5
    @State private var selectedCategory = "Genel"
    @State private var showingSuccessAlert = false
    
    private let categories = ["Genel", "Öneri", "Hata Bildirimi", "Özellik İsteği", "Kullanıcı Deneyimi"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Geri Bildirim Kategorisi")) {
                    Picker("Kategori", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("Değerlendirme")) {
                    HStack {
                        Text("Uygulama Puanı")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .onTapGesture {
                                        rating = star
                                    }
                            }
                        }
                    }
                }
                
                Section(header: Text("Geri Bildiriminiz")) {
                    TextField("Geri bildiriminizi buraya yazın...", text: $feedbackText)
                        .textFieldStyle(ShuttleTrackTextFieldStyle())
                        .lineLimit(10)
                }
            }
            .navigationTitle("Geri Bildirim")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("İptal") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Gönder") {
                    sendFeedback()
                }
                .disabled(feedbackText.isEmpty)
            )
            .alert("Geri Bildirim Gönderildi", isPresented: $showingSuccessAlert) {
                Button("Tamam") {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Geri bildiriminiz için teşekkürler! Değerlendirmeniz bizim için çok değerli.")
            }
        }
    }
    
    private func sendFeedback() {
        // Send feedback implementation
        showingSuccessAlert = true
    }
}

struct HelpSupportView_Previews: PreviewProvider {
    static var previews: some View {
        HelpSupportView()
    }
}
