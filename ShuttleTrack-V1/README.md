# Araç Takip Sistemi - Havalimanı Transfer Yönetimi

Bu uygulama, havalimanı transferi yapan turizm acentelerinin araçlarını takip etmesi, şoförlere iş ataması yapması ve organizasyonu yönetmesi için geliştirilmiş bir iOS uygulamasıdır.

## 🚀 Özellikler

### 📱 Ana Özellikler
- **Şirket Yönetimi**: Her turizm acentesi kendi hesabını oluşturabilir
- **Araç Takibi**: Araçların gerçek zamanlı konum takibi
- **Şoför Yönetimi**: Şoför bilgileri ve ehliyet takibi
- **İş Atama Sistemi**: Transfer işlerinin planlanması ve atanması
- **Dashboard**: Genel durum ve istatistikler

### 🔧 Teknik Özellikler
- **SwiftUI** ile modern iOS arayüzü
- **Firebase** backend servisleri
- **Firestore** veritabanı
- **Google Maps** entegrasyonu
- **Core Location** konum servisleri
- **Real-time** veri senkronizasyonu

## 📋 Gereksinimler

- iOS 15.0+
- Xcode 14.0+
- Swift 5.9+
- Firebase projesi
- Google Maps API anahtarı

## 🛠️ Kurulum

### 1. Firebase Kurulumu
1. [Firebase Console](https://console.firebase.google.com/)'da yeni proje oluşturun
2. iOS uygulaması ekleyin
3. `GoogleService-Info.plist` dosyasını indirin ve projeye ekleyin
4. Authentication, Firestore ve Storage servislerini etkinleştirin

### 2. Google Maps Kurulumu
1. [Google Cloud Console](https://console.cloud.google.com/)'da Maps API'yi etkinleştirin
2. API anahtarını alın ve `GoogleService-Info.plist` dosyasına ekleyin

### 3. Proje Kurulumu
1. Xcode'da yeni iOS projesi oluşturun
2. Bu dosyaları projenize kopyalayın
3. Swift Package Manager ile bağımlılıkları ekleyin:
   - Firebase iOS SDK
   - Google Maps iOS Utils

## 📁 Proje Yapısı

```
VehicleTrackingApp/
├── Models/
│   ├── Company.swift          # Şirket modeli
│   ├── Vehicle.swift          # Araç modeli
│   ├── Driver.swift           # Şoför modeli
│   └── Trip.swift             # Transfer işi modeli
├── Views/
│   ├── LoginView.swift        # Giriş ekranı
│   ├── SignUpView.swift       # Kayıt ekranı
│   ├── DashboardView.swift    # Ana dashboard
│   ├── VehicleManagementView.swift  # Araç yönetimi
│   ├── DriverManagementView.swift  # Şoför yönetimi
│   ├── TripAssignmentView.swift     # İş atama
│   └── TrackingView.swift     # Araç takibi
├── Services/
│   ├── FirebaseService.swift  # Firebase servisleri
│   └── LocationService.swift  # Konum servisleri
├── ViewModels/
│   ├── AppViewModel.swift     # Ana uygulama view model
│   ├── VehicleViewModel.swift # Araç view model
│   ├── DriverViewModel.swift  # Şoför view model
│   └── TripViewModel.swift    # İş view model
├── App.swift                  # Ana uygulama dosyası
├── Package.swift             # Swift Package Manager
└── GoogleService-Info.plist  # Firebase yapılandırması
```

## 🎯 Kullanım Senaryoları

### Şirket Kaydı
1. Uygulamayı açın
2. "Kayıt Ol" butonuna tıklayın
3. Şirket bilgilerinizi girin
4. Hesabınızı oluşturun

### Araç Ekleme
1. "Araçlar" sekmesine gidin
2. "+" butonuna tıklayın
3. Araç bilgilerini girin
4. Kaydedin

### Şoför Ekleme
1. "Şoförler" sekmesine gidin
2. "+" butonuna tıklayın
3. Şoför bilgilerini girin
4. Kaydedin

### İş Oluşturma
1. "İşler" sekmesine gidin
2. "+" butonuna tıklayın
3. Transfer detaylarını girin
4. Şoför ve araç atayın

### Araç Takibi
1. "Takip" sekmesine gidin
2. Araçları haritada görün
3. Gerçek zamanlı konum takibi yapın

## 🔐 Güvenlik

- Firebase Authentication ile güvenli giriş
- Her şirket sadece kendi verilerine erişebilir
- Şifreli veri iletimi
- Konum izinleri kullanıcı kontrolünde

## 📊 Veri Modeli

### Şirket (Company)
- Şirket bilgileri
- Lisans numarası
- İletişim bilgileri

### Araç (Vehicle)
- Plaka numarası
- Marka, model, yıl
- Kapasite ve tip
- Gerçek zamanlı konum

### Şoför (Driver)
- Kişisel bilgiler
- Ehliyet bilgileri
- Müsaitlik durumu
- Değerlendirme

### Transfer İşi (Trip)
- Kalkış ve varış noktaları
- Zaman planlaması
- Yolcu sayısı
- Durum takibi

## 🚀 Gelecek Özellikler

- [ ] Push notification sistemi
- [ ] Raporlama ve analitik
- [ ] Çoklu dil desteği
- [ ] Offline çalışma modu
- [ ] Gelişmiş harita özellikleri
- [ ] Müşteri uygulaması entegrasyonu

## 📞 Destek

Herhangi bir sorunuz veya öneriniz için lütfen iletişime geçin.

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır.