import Foundation
import CoreLocation
import SwiftUI

enum VehicleType: String, CaseIterable, Codable {
    case automobile = "Otomobil"
    case minibus = "Minibüs"
    case midibus = "Midibus"
    case bus = "Otobüs"
    case truck = "Kamyon"
    case minivan = "Minivan"
    case van = "Van"
    case pickup = "Pickup"
    
    var displayName: String {
        return self.rawValue
    }
}

struct Vehicle: Identifiable, Codable {
    let id: String
    var plateNumber: String
    var model: String
    var brand: String
    var year: Int
    var capacity: Int
    var vehicleType: VehicleType
    var color: String
    var insuranceExpiryDate: Date
    var inspectionExpiryDate: Date
    var isActive: Bool
    var currentLocation: VehicleLocation?
    var companyId: String
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String = UUID().uuidString, 
         plateNumber: String, 
         model: String, 
         brand: String, 
         year: Int, 
         capacity: Int,
         vehicleType: VehicleType,
         color: String, 
         insuranceExpiryDate: Date,
         inspectionExpiryDate: Date,
         isActive: Bool = true,
         companyId: String) {
        self.id = id
        self.plateNumber = plateNumber
        self.model = model
        self.brand = brand
        self.year = year
        self.capacity = capacity
        self.vehicleType = vehicleType
        self.color = color
        self.insuranceExpiryDate = insuranceExpiryDate
        self.inspectionExpiryDate = inspectionExpiryDate
        self.isActive = isActive
        self.currentLocation = nil
        self.companyId = companyId
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var displayName: String {
        return "\(brand) \(model) - \(plateNumber)"
    }
    
    var statusText: String {
        return isActive ? "Aktif" : "Pasif"
    }
    
    var statusColor: Color {
        return isActive ? .green : .red
    }
    
    // Sigorta bitiş tarihine kalan gün sayısı
    var daysUntilInsuranceExpiry: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let expiryDate = calendar.startOfDay(for: insuranceExpiryDate)
        let days = calendar.dateComponents([.day], from: today, to: expiryDate).day ?? 0
        return days
    }
    
    // Muayene bitiş tarihine kalan gün sayısı
    var daysUntilInspectionExpiry: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let expiryDate = calendar.startOfDay(for: inspectionExpiryDate)
        let days = calendar.dateComponents([.day], from: today, to: expiryDate).day ?? 0
        return days
    }
    
    // Sigorta durumu
    var insuranceStatus: String {
        let days = daysUntilInsuranceExpiry
        if days < 0 {
            return "Süresi Dolmuş"
        } else if days <= 30 {
            return "\(days) gün kaldı"
        } else {
            return "Geçerli"
        }
    }
    
    // Muayene durumu
    var inspectionStatus: String {
        let days = daysUntilInspectionExpiry
        if days < 0 {
            return "Süresi Dolmuş"
        } else if days <= 30 {
            return "\(days) gün kaldı"
        } else {
            return "Geçerli"
        }
    }
    
    // Sigorta durum rengi
    var insuranceStatusColor: Color {
        let days = daysUntilInsuranceExpiry
        if days < 0 {
            return .red
        } else if days <= 30 {
            return .orange
        } else {
            return .green
        }
    }
    
    // Muayene durum rengi
    var inspectionStatusColor: Color {
        let days = daysUntilInspectionExpiry
        if days < 0 {
            return .red
        } else if days <= 30 {
            return .orange
        } else {
            return .green
        }
    }
}

struct VehicleLocation: Codable {
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let address: String?
    
    init(latitude: Double, longitude: Double, address: String? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = Date()
        self.address = address
    }
}
