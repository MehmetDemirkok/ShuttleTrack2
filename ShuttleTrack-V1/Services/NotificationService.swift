import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    func requestAuthorizationIfNeeded(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                    completion?(granted)
                }
            default:
                completion?(settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional)
            }
        }
    }

    func scheduleVehicleExpiryNotifications(for vehicle: Vehicle) {
        guard let vehicleId = vehicle.id else { return }
        
        // Sigorta
        scheduleExpirySet(
            plate: vehicle.plateNumber,
            kind: "sigortası",
            expiryDate: vehicle.insuranceExpiryDate,
            idPrefix: "insurance-\(vehicleId)"
        )
        // Muayene
        scheduleExpirySet(
            plate: vehicle.plateNumber,
            kind: "muayenesi",
            expiryDate: vehicle.inspectionExpiryDate,
            idPrefix: "inspection-\(vehicleId)"
        )
    }

    private func scheduleExpirySet(plate: String, kind: String, expiryDate: Date, idPrefix: String) {
        // Plan: 30 gün kala, 7 gün kala, 1 gün kala (sabah 09:00), ve bitiş günü 09:00
        let calendar = Calendar.current
        let times: [(offsetDays: Int, message: String)] = [
            (30, "\(plate) plakalı aracınızın \(kind) 30 gün içinde bitiyor."),
            (7,  "\(plate) plakalı aracınızın \(kind) 7 gün içinde bitiyor."),
            (1,  "\(plate) plakalı aracınızın \(kind) yarın bitiyor."),
            (0,  "\(plate) plakalı aracınızın \(kind) bugün bitiyor.")
        ]

        for (offset, body) in times {
            if let triggerDate = calendar.date(byAdding: .day, value: -offset, to: expiryDate) {
                // 09:00'da bildirim
                var components = calendar.dateComponents([.year, .month, .day], from: triggerDate)
                components.hour = 9
                components.minute = 0

                // Geçmişteki tarihleri planlama
                if let scheduledDate = calendar.date(from: components), scheduledDate > Date() {
                    let id = "\(idPrefix)-d\(offset)"
                    scheduleLocalNotification(identifier: id, title: "ShuttleTrack", body: body, dateComponents: components)
                } else if offset == 0 {
                    // Bitiş geçmişse ve halen güncelse, anında bir kere gönder
                    let id = "\(idPrefix)-expired"
                    scheduleImmediateNotification(identifier: id, title: "ShuttleTrack", body: "\(plate) plakalı aracınızın \(kind) süresi doldu.")
                }
            }
        }
    }

    private func scheduleLocalNotification(identifier: String, title: String, body: String, dateComponents: DateComponents) {
        // Önce aynı ID'yi temizle, sonra ekle (çiftlenmeyi önlemek için)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    private func scheduleImmediateNotification(identifier: String, title: String, body: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}


