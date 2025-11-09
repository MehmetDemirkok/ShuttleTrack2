import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseFirestoreSwift
import UserNotifications

@MainActor
class NotificationViewModel: ObservableObject {
    @Published var notifications: [DriverNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let db = Firestore.firestore()
    private let notificationService = NotificationService.shared
    private var notificationsListener: ListenerRegistration?
    
    func fetchNotifications(for driverId: String, companyId: String) {
        // Önceki listener'ı temizle
        notificationsListener?.remove()
        isLoading = true
        errorMessage = ""
        
        notificationsListener = db.collection("driverNotifications")
            .whereField("driverId", isEqualTo: driverId)
            .whereField("companyId", isEqualTo: companyId)
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    self.isLoading = false
                    
                    if let error = error {
                        let localizedError = ErrorHandler.shared.getLocalizedErrorMessage(error)
                        self.errorMessage = localizedError
                        print("❌ Notification fetch error: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let snapshot = snapshot else {
                        self.notifications = []
                        self.updateUnreadCount()
                        return
                    }
                    
                    let notifications = snapshot.documents.compactMap { document in
                        try? document.data(as: DriverNotification.self)
                    }
                    
                    self.notifications = notifications
                    self.updateUnreadCount()
                    
                    // Yeni bildirimler için push notification gönder
                    self.handleNewNotifications(notifications)
                    
                    print("📬 Fetched \(notifications.count) notifications, \(self.unreadCount) unread")
                }
            }
    }
    
    private func updateUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead }.count
    }
    
    private func handleNewNotifications(_ notifications: [DriverNotification]) {
        // Son 1 dakika içinde oluşturulan bildirimleri kontrol et
        let oneMinuteAgo = Date().addingTimeInterval(-60)
        let newNotifications = notifications.filter { notification in
            notification.createdAt > oneMinuteAgo && !notification.isRead
        }
        
        for notification in newNotifications {
            // Push notification gönder
            notificationService.sendPushNotification(
                title: notification.title,
                body: notification.message,
                identifier: notification.id ?? UUID().uuidString
            )
        }
    }
    
    func markAsRead(_ notification: DriverNotification) {
        guard let notificationId = notification.id else { return }
        
        db.collection("driverNotifications").document(notificationId).updateData([
            "isRead": true,
            "readAt": Date()
        ]) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error marking notification as read: \(error.localizedDescription)")
                } else {
                    // Local'de güncelle
                    if let index = self?.notifications.firstIndex(where: { $0.id == notificationId }) {
                        self?.notifications[index].isRead = true
                        self?.notifications[index].readAt = Date()
                        self?.updateUnreadCount()
                        print("✅ Notification marked as read: \(notificationId)")
                    }
                }
            }
        }
    }
    
    func markAllAsRead(for driverId: String, companyId: String) {
        let unreadNotifications = notifications.filter { !$0.isRead }
        
        guard !unreadNotifications.isEmpty else { return }
        
        let batch = db.batch()
        for notification in unreadNotifications {
            guard let notificationId = notification.id else { continue }
            let ref = db.collection("driverNotifications").document(notificationId)
            batch.updateData([
                "isRead": true,
                "readAt": Date()
            ], forDocument: ref)
        }
        
        batch.commit { [weak self] error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error marking all notifications as read: \(error.localizedDescription)")
                } else {
                    // Local'de güncelle
                    for index in self.notifications.indices {
                        self.notifications[index].isRead = true
                        self.notifications[index].readAt = Date()
                    }
                    self.updateUnreadCount()
                    print("✅ All notifications marked as read")
                }
            }
        }
    }
    
    func deleteNotification(_ notification: DriverNotification) {
        guard let notificationId = notification.id else { return }
        
        db.collection("driverNotifications").document(notificationId).delete { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error deleting notification: \(error.localizedDescription)")
                } else {
                    self?.notifications.removeAll { $0.id == notificationId }
                    self?.updateUnreadCount()
                    print("✅ Notification deleted: \(notificationId)")
                }
            }
        }
    }
    
    deinit {
        notificationsListener?.remove()
        print("✅ NotificationViewModel temizlendi")
    }
}

