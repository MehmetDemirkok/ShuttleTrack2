import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct DriverNotification: Identifiable, Codable {
    @DocumentID var id: String?
    var driverId: String
    var companyId: String
    var type: NotificationType
    var title: String
    var message: String
    var isRead: Bool
    var relatedTripId: String? // İş bildirimi için
    var relatedVehicleId: String? // Araç bildirimi için
    var createdAt: Date
    var readAt: Date?
    
    init(id: String? = nil,
         driverId: String,
         companyId: String,
         type: NotificationType,
         title: String,
         message: String,
         relatedTripId: String? = nil,
         relatedVehicleId: String? = nil) {
        self.id = id
        self.driverId = driverId
        self.companyId = companyId
        self.type = type
        self.title = title
        self.message = message
        self.isRead = false
        self.relatedTripId = relatedTripId
        self.relatedVehicleId = relatedVehicleId
        self.createdAt = Date()
        self.readAt = nil
    }
    
    enum NotificationType: String, Codable {
        case tripAssigned = "trip_assigned" // İş atandı
        case tripUpdated = "trip_updated" // İş güncellendi
        case vehicleAssigned = "vehicle_assigned" // Araç atandı
        case vehicleUpdated = "vehicle_updated" // Araç güncellendi
        case companyMessage = "company_message" // Şirket mesajı
        case systemAlert = "system_alert" // Sistem uyarısı
        
        var icon: String {
            switch self {
            case .tripAssigned, .tripUpdated:
                return "list.bullet.clipboard.fill"
            case .vehicleAssigned, .vehicleUpdated:
                return "car.fill"
            case .companyMessage:
                return "message.fill"
            case .systemAlert:
                return "exclamationmark.triangle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .tripAssigned, .tripUpdated:
                return .blue
            case .vehicleAssigned, .vehicleUpdated:
                return .green
            case .companyMessage:
                return .orange
            case .systemAlert:
                return .red
            }
        }
    }
    
    var icon: String {
        return type.icon
    }
    
    var color: Color {
        return type.color
    }
}

