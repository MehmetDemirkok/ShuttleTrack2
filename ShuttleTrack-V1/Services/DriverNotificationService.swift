import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

/// Sürücülere bildirim gönderme servisi (Admin tarafından kullanılır)
@MainActor
class DriverNotificationService {
    static let shared = DriverNotificationService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    /// Sürücüye iş atandığında bildirim gönder
    func sendTripAssignedNotification(to driverId: String, companyId: String, trip: Trip) async {
        let notification = DriverNotification(
            driverId: driverId,
            companyId: companyId,
            type: .tripAssigned,
            title: "Yeni İş Atandı",
            message: "\(trip.tripNumber) numaralı iş size atandı. Alış: \(trip.pickupLocation.name)",
            relatedTripId: trip.id
        )
        
        await createNotification(notification)
    }
    
    /// Sürücüye araç atandığında bildirim gönder
    func sendVehicleAssignedNotification(to driverId: String, companyId: String, vehicle: Vehicle) async {
        let notification = DriverNotification(
            driverId: driverId,
            companyId: companyId,
            type: .vehicleAssigned,
            title: "Araç Atandı",
            message: "\(vehicle.displayName) plakalı araç size atandı.",
            relatedVehicleId: vehicle.id
        )
        
        await createNotification(notification)
    }
    
    /// Şirket mesajı gönder
    func sendCompanyMessage(to driverId: String, companyId: String, title: String, message: String) async {
        let notification = DriverNotification(
            driverId: driverId,
            companyId: companyId,
            type: .companyMessage,
            title: title,
            message: message
        )
        
        await createNotification(notification)
    }
    
    /// Tüm aktif sürücülere toplu mesaj gönder
    func sendBulkMessage(to driverIds: [String], companyId: String, title: String, message: String) {
        let batch = db.batch()
        
        for driverId in driverIds {
            let notification = DriverNotification(
                driverId: driverId,
                companyId: companyId,
                type: .companyMessage,
                title: title,
                message: message
            )
            
            let ref = db.collection("driverNotifications").document()
            do {
                try batch.setData(from: notification, forDocument: ref)
            } catch {
                print("❌ Error adding notification to batch: \(error.localizedDescription)")
            }
        }
        
        batch.commit { error in
            if let error = error {
                print("❌ Error sending bulk notifications: \(error.localizedDescription)")
            } else {
                print("✅ Bulk notifications sent to \(driverIds.count) drivers")
            }
        }
    }
    
    /// Bildirim oluştur
    private func createNotification(_ notification: DriverNotification) async {
        do {
            _ = try await db.collection("driverNotifications").addDocument(from: notification)
            print("✅ Notification created: \(notification.title)")
        } catch {
            print("❌ Error creating notification: \(error.localizedDescription)")
        }
    }
}

