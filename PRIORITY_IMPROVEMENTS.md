# ShuttleTrack - Öncelikli İyileştirmeler Listesi

## 🔴 KRİTİK (Hemen Yapılmalı)

### 1. @MainActor Eksiklikleri - UI Thread Sorunları
**Sorun**: ViewModel'lerde @MainActor eksik, bu UI güncellemelerinde race condition'lara yol açabilir.

**Etkilenen Dosyalar**:
- `AppViewModel.swift` - ❌ @MainActor yok
- `VehicleViewModel.swift` - ❌ @MainActor yok  
- `DriverViewModel.swift` - ❌ @MainActor yok
- `TripViewModel.swift` - ❌ @MainActor yok
- `ProfileViewModel.swift` - ❌ @MainActor yok

**Çözüm**: Tüm ViewModel'lere `@MainActor` ekle
```swift
@MainActor
class AppViewModel: ObservableObject {
    // ...
}
```

**Öncelik**: 🔴 YÜKSEK - Production'da crash'lere yol açabilir

---

### 2. @DocumentID Tutarsızlıkları - Firestore Entegrasyonu
**Sorun**: Vehicle ve Driver modellerinde @DocumentID yok, bu Firestore document ID'lerinin otomatik yönetimini engelliyor.

**Etkilenen Dosyalar**:
- `Vehicle.swift` - `let id: String` ❌
- `Driver.swift` - `let id: String` ❌

**Çözüm**: @DocumentID kullan
```swift
struct Vehicle: Identifiable, Codable {
    @DocumentID var id: String?
    // ...
}
```

**Öncelik**: 🔴 YÜKSEK - Firestore işlemlerinde sorunlara yol açabilir

---

### 3. Listener Cleanup Eksiklikleri - Memory Leak Riski
**Sorun**: Bazı ViewModel'lerde Firestore listener'ları temizlenmiyor.

**Etkilenen Dosyalar**:
- `VehicleViewModel.swift` - Listener cleanup yok ❌
- `TripViewModel.swift` - Listener cleanup yok ❌
- `AppViewModel.swift` - Auth listener cleanup yok ❌

**Çözüm**: Her ViewModel'de `deinit` ekle
```swift
deinit {
    listener?.remove()
    cancellables.removeAll()
}
```

**Öncelik**: 🔴 YÜKSEK - Memory leak'lere yol açabilir

---

## 🟡 ÖNEMLİ (Yakın Zamanda Yapılmalı)

### 4. Kullanılmayan Dosyalar - Kod Temizliği
**Sorun**: Kullanılmayan dosyalar projede duruyor.

**Etkilenen Dosyalar**:
- `ContentView.swift` - Kullanılmıyor ❌
- `App.swift` - Yorum satırı, kullanılmıyor ❌

**Çözüm**: Bu dosyaları sil

**Öncelik**: 🟡 ORTA - Kod kalitesi ve karışıklık

---

### 5. Error Handling İyileştirmeleri
**Sorun**: Bazı hata mesajları kullanıcı dostu değil, retry mekanizması yok.

**İyileştirmeler**:
- Tüm error mesajlarını Türkçe'ye çevir
- Network hatalarında retry butonu ekle
- Offline durum kontrolü ekle

**Öncelik**: 🟡 ORTA - Kullanıcı deneyimi

---

### 6. Offline Support Eksikliği
**Sorun**: Uygulama offline durumda çalışmıyor.

**İyileştirmeler**:
- Firebase offline persistence etkinleştir
- Offline durumda kullanıcıya bilgi ver
- Offline'da yapılan değişiklikleri sync et

**Öncelik**: 🟡 ORTA - Kullanıcı deneyimi

---

## 🟢 İYİLEŞTİRME (Zaman Buldukça)

### 7. Constants Dosyası Eksikliği
**Sorun**: Magic numbers ve string'ler kod içinde dağınık.

**İyileştirmeler**:
- `Constants.swift` dosyası oluştur
- Limit değerleri (50, 100 vb.) constants'a taşı
- Collection name'leri constants'a taşı

**Öncelik**: 🟢 DÜŞÜK - Kod organizasyonu

---

### 8. Base ViewModel Pattern
**Sorun**: ViewModel'lerde duplicate kod var.

**İyileştirmeler**:
- `BaseViewModel` oluştur
- Ortak CRUD operasyonlarını base'e taşı
- Error handling'i base'e taşı

**Öncelik**: 🟢 DÜŞÜK - Kod tekrarını azaltır

---

### 9. Unit Test Eksikliği
**Sorun**: Hiç test yok.

**İyileştirmeler**:
- ViewModel'ler için unit test'ler yaz
- Model'ler için test'ler yaz
- Service'ler için test'ler yaz

**Öncelik**: 🟢 DÜŞÜK - Kod kalitesi ve güvenilirlik

---

### 10. Performance Optimizations
**Sorun**: Bazı performans iyileştirmeleri yapılabilir.

**İyileştirmeler**:
- Firestore index'leri ekle (performans için)
- Pagination ekle (büyük listeler için)
- Image caching iyileştir

**Öncelik**: 🟢 DÜŞÜK - Performans

---

## 📋 YAPILACAKLAR ÖZET

### Hemen Yapılacaklar (Bu Hafta)
1. ✅ Tüm ViewModel'lere @MainActor ekle
2. ✅ Vehicle ve Driver modellerine @DocumentID ekle
3. ✅ Tüm ViewModel'lerde listener cleanup ekle
4. ✅ Kullanılmayan dosyaları sil

### Yakın Zamanda (Bu Ay)
5. ⏳ Error handling iyileştir
6. ⏳ Offline support ekle

### Gelecekte (Zaman Buldukça)
7. ⏳ Constants dosyası oluştur
8. ⏳ Base ViewModel pattern ekle
9. ⏳ Unit test'ler yaz
10. ⏳ Performance optimizations

---

## 🎯 Öncelik Matrisi

| Öncelik | Sorun | Etki | Zorluk | Süre |
|---------|-------|------|--------|------|
| 🔴 Yüksek | @MainActor | Crash riski | Kolay | 30 dk |
| 🔴 Yüksek | @DocumentID | Firestore sorunları | Kolay | 20 dk |
| 🔴 Yüksek | Listener Cleanup | Memory leak | Kolay | 30 dk |
| 🟡 Orta | Kullanılmayan Dosyalar | Kod kalitesi | Çok Kolay | 5 dk |
| 🟡 Orta | Error Handling | UX | Orta | 2 saat |
| 🟡 Orta | Offline Support | UX | Zor | 1 gün |
| 🟢 Düşük | Constants | Organizasyon | Kolay | 1 saat |
| 🟢 Düşük | Base ViewModel | Kod tekrarı | Orta | 4 saat |
| 🟢 Düşük | Unit Tests | Kalite | Zor | 1 hafta |
| 🟢 Düşük | Performance | Performans | Orta | 1 gün |

---

## 📝 Notlar

- **Kritik sorunlar** production'a çıkmadan önce mutlaka çözülmeli
- **Önemli sorunlar** yakın zamanda ele alınmalı
- **İyileştirmeler** zaman buldukça yapılabilir

