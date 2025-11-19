import Foundation
import SwiftUI
import PDFKit
import Combine

class ExportService: ObservableObject {
    @Published var isExporting = false
    @Published var exportProgress: Double = 0.0
    @Published var exportMessage = ""
    
    func exportToExcel(trips: [Trip], vehicles: [Vehicle], drivers: [Driver]) -> URL? {
        isExporting = true
        exportProgress = 0.0
        exportMessage = "Excel dosyası oluşturuluyor..."
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.exportProgress = 0.3
        }
        
        // CSV formatında Excel uyumlu dosya oluştur
        var csvContent = "İş Adı,Alış Noktası,Varış Noktası,Yolcu Adı,Yolcu Sayısı,Alış Tarihi,Alış Saati,Durum,Araç,Şoför,Ücret\n"
        
        for trip in trips {
            let pickupDate = DateFormatter.localizedString(from: trip.scheduledPickupTime, dateStyle: .short, timeStyle: .none)
            let pickupTime = DateFormatter.localizedString(from: trip.scheduledPickupTime, dateStyle: .none, timeStyle: .short)
            
            // Notlardan yolcu adını çıkar
            var passengerName = "-"
            if let notes = trip.notes {
                let lines = notes.components(separatedBy: "\n")
                for line in lines {
                    if line.hasPrefix("Yolcu:") {
                        passengerName = line.replacingOccurrences(of: "Yolcu: ", with: "")
                        break
                    }
                }
            }
            
            let fare = trip.fare != nil ? String(format: "%.2f TL", trip.fare!) : "-"
            
            // Araç bilgisini bul
            let vehicleInfo: String
            if trip.vehicleId.isEmpty {
                vehicleInfo = "Atanmamış"
            } else {
                if let vehicle = vehicles.first(where: { $0.id == trip.vehicleId }) {
                    vehicleInfo = vehicle.displayName  // Örn: "34 ABC 123 - Toyota"
                } else {
                    vehicleInfo = "Bulunamadı"
                }
            }
            
            // Şoför bilgisini bul
            let driverInfo: String
            if trip.driverId.isEmpty {
                driverInfo = "Atanmamış"
            } else {
                if let driver = drivers.first(where: { $0.id == trip.driverId }) {
                    driverInfo = driver.fullName  // Örn: "Ahmet Yılmaz"
                } else {
                    driverInfo = "Bulunamadı"
                }
            }
            
            csvContent += "\"\(trip.tripNumber)\",\"\(trip.pickupLocation.name)\",\"\(trip.dropoffLocation.name)\",\"\(passengerName)\",\"\(trip.passengerCount)\",\"\(pickupDate)\",\"\(pickupTime)\",\"\(trip.statusText)\",\"\(vehicleInfo)\",\"\(driverInfo)\",\"\(fare)\"\n"
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.exportProgress = 0.7
        }
        
        // Dosyayı kaydet
        let fileName = "isler_\(DateFormatter.fileNameFormatter.string(from: Date())).csv"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.exportProgress = 1.0
                self.exportMessage = "Excel dosyası başarıyla oluşturuldu!"
                self.isExporting = false
            }
            
            return fileURL
        } catch {
            DispatchQueue.main.async {
                self.exportMessage = "Excel dosyası oluşturulurken hata: \(error.localizedDescription)"
                self.isExporting = false
            }
            return nil
        }
    }
    
    func exportToPDF(trips: [Trip], vehicles: [Vehicle], drivers: [Driver]) -> URL? {
        isExporting = true
        exportProgress = 0.0
        exportMessage = "PDF dosyası oluşturuluyor..."
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.exportProgress = 0.3
        }
        
        // PDF oluştur
        let pdfMetaData = [
            kCGPDFContextCreator: "ShuttleTrack",
            kCGPDFContextAuthor: "ShuttleTrack App",
            kCGPDFContextTitle: "İşler Raporu"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.exportProgress = 0.5
        }
        
        let data = renderer.pdfData { context in
            // İlk sayfa
            context.beginPage()
            
            // Başlık
            let title = "İşler Raporu"
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ]
            
            let titleSize = title.size(withAttributes: titleAttributes)
            let titleRect = CGRect(x: (pageWidth - titleSize.width) / 2, y: 50, width: titleSize.width, height: titleSize.height)
            title.draw(in: titleRect, withAttributes: titleAttributes)
            
            // Tarih
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.locale = Locale(identifier: "tr_TR")
            let currentDate = dateFormatter.string(from: Date())
            
            let dateFont = UIFont.systemFont(ofSize: 14)
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: dateFont,
                .foregroundColor: UIColor.gray
            ]
            
            let dateSize = currentDate.size(withAttributes: dateAttributes)
            let dateRect = CGRect(x: (pageWidth - dateSize.width) / 2, y: 80, width: dateSize.width, height: dateSize.height)
            currentDate.draw(in: dateRect, withAttributes: dateAttributes)
            
            // İşler listesi
            var yPosition: CGFloat = 120
            let lineHeight: CGFloat = 20
            let leftMargin: CGFloat = 50
            let rightMargin: CGFloat = 50
            let contentWidth = pageWidth - leftMargin - rightMargin
            
            for (index, trip) in trips.enumerated() {
                // Yeni sayfa gerekli mi kontrol et
                if yPosition > pageHeight - 100 {
                    context.beginPage()
                    yPosition = 50
                }
                
                // İş başlığı
                let tripText = "\(index + 1). \(trip.tripNumber)"
                let tripFont = UIFont.boldSystemFont(ofSize: 14)
                let tripAttributes: [NSAttributedString.Key: Any] = [
                    .font: tripFont,
                    .foregroundColor: UIColor.black
                ]
                
                let tripSize = tripText.size(withAttributes: tripAttributes)
                let tripRect = CGRect(x: leftMargin, y: yPosition, width: contentWidth, height: tripSize.height)
                tripText.draw(in: tripRect, withAttributes: tripAttributes)
                
                yPosition += lineHeight
                
                // Rota bilgisi
                let routeText = "   Rota: \(trip.pickupLocation.name) → \(trip.dropoffLocation.name)"
                let routeFont = UIFont.systemFont(ofSize: 12)
                let routeAttributes: [NSAttributedString.Key: Any] = [
                    .font: routeFont,
                    .foregroundColor: UIColor.darkGray
                ]
                
                let routeRect = CGRect(x: leftMargin, y: yPosition, width: contentWidth, height: lineHeight)
                routeText.draw(in: routeRect, withAttributes: routeAttributes)
                
                yPosition += lineHeight
                
                // Yolcu bilgisi
                var passengerName = ""
                if let notes = trip.notes {
                    let lines = notes.components(separatedBy: "\n")
                    for line in lines {
                        if line.hasPrefix("Yolcu:") {
                            passengerName = line.replacingOccurrences(of: "Yolcu: ", with: "")
                            break
                        }
                    }
                }
                
                let passengerText = passengerName.isEmpty 
                    ? "   Yolcu: \(trip.passengerCount) kişi" 
                    : "   Yolcu: \(passengerName) (\(trip.passengerCount) kişi)"
                let passengerRect = CGRect(x: leftMargin, y: yPosition, width: contentWidth, height: lineHeight)
                passengerText.draw(in: passengerRect, withAttributes: routeAttributes)
                
                yPosition += lineHeight
                
                // Tarih ve durum
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .short
                dateFormatter.locale = Locale(identifier: "tr_TR")
                let pickupDateTime = dateFormatter.string(from: trip.scheduledPickupTime)
                
                let detailText = "   Tarih: \(pickupDateTime) - Durum: \(trip.statusText)"
                let detailRect = CGRect(x: leftMargin, y: yPosition, width: contentWidth, height: lineHeight)
                detailText.draw(in: detailRect, withAttributes: routeAttributes)
                
                yPosition += lineHeight
                
                // Araç bilgisi
                let vehicleInfo: String
                if trip.vehicleId.isEmpty {
                    vehicleInfo = "Atanmamış"
                } else {
                    if let vehicle = vehicles.first(where: { $0.id == trip.vehicleId }) {
                        vehicleInfo = vehicle.displayName
                    } else {
                        vehicleInfo = "Bulunamadı"
                    }
                }
                let vehicleText = "   Araç: \(vehicleInfo)"
                let vehicleRect = CGRect(x: leftMargin, y: yPosition, width: contentWidth, height: lineHeight)
                vehicleText.draw(in: vehicleRect, withAttributes: routeAttributes)
                yPosition += lineHeight
                
                // Şoför bilgisi
                let driverInfo: String
                if trip.driverId.isEmpty {
                    driverInfo = "Atanmamış"
                } else {
                    if let driver = drivers.first(where: { $0.id == trip.driverId }) {
                        driverInfo = driver.fullName
                    } else {
                        driverInfo = "Bulunamadı"
                    }
                }
                let driverText = "   Şoför: \(driverInfo)"
                let driverRect = CGRect(x: leftMargin, y: yPosition, width: contentWidth, height: lineHeight)
                driverText.draw(in: driverRect, withAttributes: routeAttributes)
                yPosition += lineHeight
                
                // Ücret bilgisi (varsa)
                if let fare = trip.fare {
                    let fareText = "   Ücret: \(String(format: "%.2f TL", fare))"
                    let fareRect = CGRect(x: leftMargin, y: yPosition, width: contentWidth, height: lineHeight)
                    fareText.draw(in: fareRect, withAttributes: routeAttributes)
                    yPosition += lineHeight
                }
                
                yPosition += 15
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.exportProgress = 0.8
        }
        
        // Dosyayı kaydet
        let fileName = "isler_\(DateFormatter.fileNameFormatter.string(from: Date())).pdf"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.exportProgress = 1.0
                self.exportMessage = "PDF dosyası başarıyla oluşturuldu!"
                self.isExporting = false
            }
            
            return fileURL
        } catch {
            DispatchQueue.main.async {
                self.exportMessage = "PDF dosyası oluşturulurken hata: \(error.localizedDescription)"
                self.isExporting = false
            }
            return nil
        }
    }
}

extension DateFormatter {
    static let fileNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}
