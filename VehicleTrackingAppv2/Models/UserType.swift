import Foundation

enum UserType: String, CaseIterable, Codable, Identifiable {
    case companyAdmin = "company_admin"
    case driver = "driver"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .companyAdmin:
            return "Şirket Yetkilisi"
        case .driver:
            return "Sürücü"
        }
    }
    
    var description: String {
        switch self {
        case .companyAdmin:
            return "Şirket yönetimi ve operasyon yetkisi"
        case .driver:
            return "Araç kullanımı ve seyahat yönetimi"
        }
    }
    
    var icon: String {
        switch self {
        case .companyAdmin:
            return "building.2.fill"
        case .driver:
            return "person.fill"
        }
    }
}

