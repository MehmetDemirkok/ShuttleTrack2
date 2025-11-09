# ShuttleTrack - Öncelikli İyileştirmeler Listesi

## 🔴 KRİTİK (Hemen Yapılmalı)

✅ **Tüm kritik sorunlar çözüldü!**

- ✅ @MainActor eksiklikleri düzeltildi
- ✅ @DocumentID tutarsızlıkları düzeltildi
- ✅ Listener cleanup eksiklikleri düzeltildi

---

## 🟡 ÖNEMLİ (Yakın Zamanda Yapılmalı)

### 1. Error Handling İyileştirmeleri
**Sorun**: Bazı hata mesajları kullanıcı dostu değil, retry mekanizması yok.

**İyileştirmeler**:
- Tüm error mesajlarını Türkçe'ye çevir
- Network hatalarında retry butonu ekle
- Offline durum kontrolü ekle

**Öncelik**: 🟡 ORTA - Kullanıcı deneyimi

---

### 2. Offline Support Eksikliği
**Sorun**: Uygulama offline durumda çalışmıyor.

**İyileştirmeler**:
- Firebase offline persistence etkinleştir
- Offline durumda kullanıcıya bilgi ver
- Offline'da yapılan değişiklikleri sync et

**Öncelik**: 🟡 ORTA - Kullanıcı deneyimi

---

## 🟢 İYİLEŞTİRME (Zaman Buldukça)

### 1. Constants Dosyası Eksikliği
**Sorun**: Magic numbers ve string'ler kod içinde dağınık.

**İyileştirmeler**:
- `Constants.swift` dosyası oluştur
- Limit değerleri (50, 100 vb.) constants'a taşı
- Collection name'leri constants'a taşı

**Öncelik**: 🟢 DÜŞÜK - Kod organizasyonu

---

### 2. Base ViewModel Pattern
**Sorun**: ViewModel'lerde duplicate kod var.

**İyileştirmeler**:
- `BaseViewModel` oluştur
- Ortak CRUD operasyonlarını base'e taşı
- Error handling'i base'e taşı

**Öncelik**: 🟢 DÜŞÜK - Kod tekrarını azaltır

---

### 3. Unit Test Eksikliği
**Sorun**: Hiç test yok.

**İyileştirmeler**:
- ViewModel'ler için unit test'ler yaz
- Model'ler için test'ler yaz
- Service'ler için test'ler yaz

**Öncelik**: 🟢 DÜŞÜK - Kod kalitesi ve güvenilirlik

---

### 4. Performance Optimizations
**Sorun**: Bazı performans iyileştirmeleri yapılabilir.

**İyileştirmeler**:
- Firestore index'leri ekle (performans için)
- Pagination ekle (büyük listeler için)
- Image caching iyileştir

**Öncelik**: 🟢 DÜŞÜK - Performans

---

## 📋 YAPILACAKLAR ÖZET

### Hemen Yapılacaklar (Bu Hafta)
✅ **Tüm kritik sorunlar tamamlandı!**

### Yakın Zamanda (Bu Ay)
1. ⏳ Error handling iyileştir
2. ⏳ Offline support ekle

### Gelecekte (Zaman Buldukça)
1. ⏳ Constants dosyası oluştur
2. ⏳ Base ViewModel pattern ekle
3. ⏳ Unit test'ler yaz
4. ⏳ Performance optimizations

---

## 🎯 Öncelik Matrisi

| Öncelik | Sorun | Etki | Zorluk | Süre |
|---------|-------|------|--------|------|
| 🟡 Orta | Error Handling | UX | Orta | 2 saat |
| 🟡 Orta | Offline Support | UX | Zor | 1 gün |
| 🟢 Düşük | Constants | Organizasyon | Kolay | 1 saat |
| 🟢 Düşük | Base ViewModel | Kod tekrarı | Orta | 4 saat |
| 🟢 Düşük | Unit Tests | Kalite | Zor | 1 hafta |
| 🟢 Düşük | Performance | Performans | Orta | 1 gün |

---

## 📝 Notlar

- ✅ **Kritik sorunlar** tamamlandı - Production'a çıkmaya hazır!
- **Önemli sorunlar** yakın zamanda ele alınmalı
- **İyileştirmeler** zaman buldukça yapılabilir

