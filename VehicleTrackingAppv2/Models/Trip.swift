import Foundation
import FirebaseFirestore
import CoreLocation
import FirebaseFirestoreSwift
import SwiftUI

struct Trip: Identifiable, Codable, @unchecked Sendable {
    @DocumentID var id: String?
    var companyId: String
    var vehicleId: String
    var driverId: String
    var tripNumber: String
    var pickupLocation: TripLocation
    var dropoffLocation: TripLocation
    var scheduledPickupTime: Date
    var scheduledDropoffTime: Date
    var actualPickupTime: Date?
    var actualDropoffTime: Date?
    var status: TripStatus
    var passengerCount: Int
    var notes: String?
    var fare: Double?
    var createdAt: Date
    var updatedAt: Date
    
    enum TripStatus: String, CaseIterable, Codable {
        case scheduled = "scheduled"
        case assigned = "assigned"
        case inProgress = "in_progress"
        case completed = "completed"
        case cancelled = "cancelled"
    }
    
    // Türkçe kısaltmalar için computed property
    var statusShortText: String {
        switch status {
        case .scheduled:
            return "Planlandı"
        case .assigned:
            return "Atandı"
        case .inProgress:
            return "Devam"
        case .completed:
            return "Tamam"
        case .cancelled:
            return "İptal"
        }
    }
    
    init(companyId: String, vehicleId: String, driverId: String, tripNumber: String, pickupLocation: TripLocation, dropoffLocation: TripLocation, scheduledPickupTime: Date, scheduledDropoffTime: Date, passengerCount: Int) {
        self.id = UUID().uuidString // Otomatik ID oluştur
        self.companyId = companyId
        self.vehicleId = vehicleId
        self.driverId = driverId
        self.tripNumber = tripNumber
        self.pickupLocation = pickupLocation
        self.dropoffLocation = dropoffLocation
        self.scheduledPickupTime = scheduledPickupTime
        self.scheduledDropoffTime = scheduledDropoffTime
        self.status = .scheduled
        self.passengerCount = passengerCount
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var statusText: String {
        switch status {
        case .scheduled:
            return "Planlandı"
        case .assigned:
            return "Atandı"
        case .inProgress:
            return "Devam Ediyor"
        case .completed:
            return "Tamamlandı"
        case .cancelled:
            return "İptal Edildi"
        }
    }
    
    var statusColor: Color {
        switch status {
        case .scheduled:
            return .orange
        case .assigned:
            return .blue
        case .inProgress:
            return .green
        case .completed:
            return .gray
        case .cancelled:
            return .red
        }
    }
    
    var displayName: String {
        return "\(tripNumber) - \(pickupLocation.name) → \(dropoffLocation.name)"
    }
    
    var isOverdue: Bool {
        return scheduledPickupTime < Date() && status != .completed
    }
    
    var isUpcoming: Bool {
        let now = Date()
        let oneHourFromNow = now.addingTimeInterval(3600)
        return scheduledPickupTime > now && scheduledPickupTime < oneHourFromNow && status == .scheduled
    }
    
    var timeRemaining: String {
        let now = Date()
        let timeInterval = scheduledPickupTime.timeIntervalSince(now)
        
        if timeInterval < 0 {
            return "Geçmiş"
        } else if timeInterval < 3600 { // 1 saat
            let minutes = Int(timeInterval / 60)
            return "\(minutes) dakika"
        } else {
            let hours = Int(timeInterval / 3600)
            return "\(hours) saat"
        }
    }
}

struct TripLocation: Codable, @unchecked Sendable {
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var notes: String?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
