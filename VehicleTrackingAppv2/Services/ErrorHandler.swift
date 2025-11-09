import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Error handling ve Türkçe mesaj dönüşümü için servis
@MainActor
class ErrorHandler {
    static let shared = ErrorHandler()
    
    private init() {}
    
    /// Firebase ve sistem hatalarını Türkçe kullanıcı dostu mesajlara çevirir
    func getLocalizedErrorMessage(_ error: Error) -> String {
        let nsError = error as NSError
        
        // Firebase Auth hataları
        if nsError.domain == "FIRAuthErrorDomain" {
            return getAuthErrorMessage(nsError.code)
        }
        
        // Firebase Firestore hataları
        if nsError.domain == "FIRFirestoreErrorDomain" {
            return getFirestoreErrorMessage(nsError)
        }
        
        // Network hataları
        if nsError.domain == NSURLErrorDomain {
            return getNetworkErrorMessage(nsError)
        }
        
        // Bilinmeyen hatalar için genel mesaj
        let errorDescription = error.localizedDescription.lowercased()
        
        if errorDescription.contains("permission") || errorDescription.contains("permissions") {
            return "Bu işlem için yetkiniz bulunmamaktadır. Lütfen yöneticinizle iletişime geçin."
        }
        
        if errorDescription.contains("network") || errorDescription.contains("internet") || errorDescription.contains("connection") {
            return "İnternet bağlantınızı kontrol edin ve tekrar deneyin."
        }
        
        if errorDescription.contains("timeout") || errorDescription.contains("timed out") {
            return "İşlem zaman aşımına uğradı. Lütfen tekrar deneyin."
        }
        
        if errorDescription.contains("not found") || errorDescription.contains("bulunamadı") {
            return "Aranan kayıt bulunamadı."
        }
        
        if errorDescription.contains("already exists") || errorDescription.contains("zaten var") {
            return "Bu kayıt zaten mevcut."
        }
        
        // Varsayılan mesaj
        return "Bir hata oluştu. Lütfen tekrar deneyin."
    }
    
    /// Firebase Auth hata mesajlarını Türkçe'ye çevirir
    private func getAuthErrorMessage(_ errorCode: Int) -> String {
        // Firebase Auth error code'ları
        // AuthErrorCode.Code enum değerleri integer olarak kullanılır
        if let authErrorCode = AuthErrorCode.Code(rawValue: errorCode) {
            switch authErrorCode {
            case .networkError:
                return "İnternet bağlantınızı kontrol edin ve tekrar deneyin."
            case .userNotFound:
                return "Kullanıcı bulunamadı."
            case .userDisabled:
                return "Bu hesap devre dışı bırakılmıştır."
            case .wrongPassword:
                return "Hatalı şifre. Lütfen tekrar deneyin."
            case .emailAlreadyInUse:
                return "Bu e-posta adresi zaten kullanılıyor."
            case .weakPassword:
                return "Şifre çok zayıf. Lütfen daha güçlü bir şifre seçin."
            case .invalidEmail:
                return "Geçersiz e-posta adresi."
            case .tooManyRequests:
                return "Çok fazla deneme yapıldı. Lütfen bir süre sonra tekrar deneyin."
            case .operationNotAllowed:
                return "Bu işlem şu anda izin verilmiyor."
            default:
                return "Giriş işlemi sırasında bir hata oluştu. Lütfen tekrar deneyin."
            }
        }
        
        // Eğer code eşleşmezse genel mesaj döndür
        return "Giriş işlemi sırasında bir hata oluştu. Lütfen tekrar deneyin."
    }
    
    /// Firestore hata mesajlarını Türkçe'ye çevirir
    private func getFirestoreErrorMessage(_ error: NSError) -> String {
        let code = error.code
        
        switch code {
        case 1: // cancelled
            return "İşlem iptal edildi."
        case 3: // invalid-argument
            return "Geçersiz veri gönderildi. Lütfen bilgilerinizi kontrol edin."
        case 4: // deadline-exceeded
            return "İşlem zaman aşımına uğradı. Lütfen tekrar deneyin."
        case 7: // not-found
            return "Aranan kayıt bulunamadı."
        case 8: // already-exists
            return "Bu kayıt zaten mevcut."
        case 9: // permission-denied
            return "Bu işlem için yetkiniz bulunmamaktadır."
        case 10: // resource-exhausted
            return "Sistem kaynakları tükenmiş. Lütfen daha sonra tekrar deneyin."
        case 11: // failed-precondition
            return "İşlem ön koşulları sağlanamadı."
        case 13: // internal
            return "Sistem hatası oluştu. Lütfen daha sonra tekrar deneyin."
        case 14: // unavailable
            return "Servis şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin."
        case 16: // unauthenticated
            return "Oturumunuz sona ermiş. Lütfen tekrar giriş yapın."
        default:
            return "Veritabanı işlemi sırasında bir hata oluştu. Lütfen tekrar deneyin."
        }
    }
    
    /// Network hata mesajlarını Türkçe'ye çevirir
    private func getNetworkErrorMessage(_ error: NSError) -> String {
        switch error.code {
        case NSURLErrorNotConnectedToInternet:
            return "İnternet bağlantınız yok. Lütfen bağlantınızı kontrol edin."
        case NSURLErrorTimedOut:
            return "Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin."
        case NSURLErrorCannotFindHost:
            return "Sunucu bulunamadı. Lütfen daha sonra tekrar deneyin."
        case NSURLErrorCannotConnectToHost:
            return "Sunucuya bağlanılamıyor. Lütfen daha sonra tekrar deneyin."
        case NSURLErrorNetworkConnectionLost:
            return "İnternet bağlantısı kesildi. Lütfen tekrar deneyin."
        case NSURLErrorDNSLookupFailed:
            return "DNS hatası. Lütfen daha sonra tekrar deneyin."
        default:
            return "Ağ bağlantısı hatası. Lütfen internet bağlantınızı kontrol edin."
        }
    }
}

