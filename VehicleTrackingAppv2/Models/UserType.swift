import Foundation

enum UserType: String, CaseIterable, Codable, Identifiable {
    case companyAdmin = "company_admin"
    case driver = "driver"
    case owner = "owner"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .companyAdmin:
            return "Şirket Yetkilisi"
        case .driver:
            return "Sürücü"
        case .owner:
            return "Sistem Yöneticisi"
        }
    }
    
    var description: String {
        switch self {
        case .companyAdmin:
            return "Şirket yönetimi ve operasyon yetkisi"
        case .driver:
            return "Araç kullanımı ve seyahat yönetimi"
        case .owner:
            return "Tüm sistemi yönetme yetkisi"
        }
    }
    
    var icon: String {
        switch self {
        case .companyAdmin:
            return "building.2.fill"
        case .driver:
            return "person.fill"
        case .owner:
            return "shield.lefthalf.filled"
        }
    }
}

