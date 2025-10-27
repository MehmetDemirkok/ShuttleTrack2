import SwiftUI

struct AddEditTripView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: TripViewModel
    @StateObject private var appViewModel: AppViewModel
    
    // Temel Bilgiler
    @State private var tripNumber = ""
    @State private var passengerCount = 1
    @State private var passengerName = ""
    @State private var passengerPhone = ""
    @State private var flightNumber = ""
    @State private var notes = ""
    @State private var fare: String = ""
    
    // Lokasyon Bilgileri
    @State private var pickupLocationName = ""
    @State private var pickupAddress = ""
    @State private var dropoffLocationName = ""
    @State private var dropoffAddress = ""
    
    // Zaman Bilgileri
    @State private var scheduledPickupTime = Date()
    @State private var scheduledDropoffTime = Date()
    
    // Atama Bilgileri
    @State private var selectedVehicleId: String?
    @State private var selectedDriverId: String?
    @State private var status: Trip.TripStatus = .scheduled
    
    // UI State
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    let trip: Trip?
    let isEditing: Bool
    
    init(trip: Trip? = nil, viewModel: TripViewModel, appViewModel: AppViewModel) {
        self.trip = trip
        self.isEditing = trip != nil
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._appViewModel = StateObject(wrappedValue: appViewModel)
        
        if let trip = trip {
            _tripNumber = State(initialValue: trip.tripNumber)
            _pickupLocationName = State(initialValue: trip.pickupLocation.name)
            _pickupAddress = State(initialValue: trip.pickupLocation.address)
            _dropoffLocationName = State(initialValue: trip.dropoffLocation.name)
            _dropoffAddress = State(initialValue: trip.dropoffLocation.address)
            _scheduledPickupTime = State(initialValue: trip.scheduledPickupTime)
            _scheduledDropoffTime = State(initialValue: trip.scheduledDropoffTime)
            _passengerCount = State(initialValue: trip.passengerCount)
            _fare = State(initialValue: trip.fare != nil ? String(format: "%.2f", trip.fare!) : "")
            _status = State(initialValue: trip.status)
            _selectedVehicleId = State(initialValue: trip.vehicleId.isEmpty ? nil : trip.vehicleId)
            _selectedDriverId = State(initialValue: trip.driverId.isEmpty ? nil : trip.driverId)
            
            // Notlardan yolcu bilgilerini ve uçuş numarasını çıkar
            if let notes = trip.notes {
                let lines = notes.components(separatedBy: "\n")
                var cleanNotes: [String] = []
                
                for line in lines {
                    if line.hasPrefix("Yolcu:") {
                        let name = line.replacingOccurrences(of: "Yolcu: ", with: "")
                        _passengerName = State(initialValue: name)
                    } else if line.hasPrefix("Tel:") || line.hasPrefix("Telefon:") {
                        let phone = line.replacingOccurrences(of: "Tel: ", with: "")
                            .replacingOccurrences(of: "Telefon: ", with: "")
                        _passengerPhone = State(initialValue: phone)
                    } else if line.hasPrefix("Uçuş:") || line.hasPrefix("Uçuş No:") {
                        let flight = line.replacingOccurrences(of: "Uçuş: ", with: "")
                            .replacingOccurrences(of: "Uçuş No: ", with: "")
                        _flightNumber = State(initialValue: flight)
                    } else if !line.isEmpty {
                        cleanNotes.append(line)
                    }
                }
                
                _notes = State(initialValue: cleanNotes.joined(separator: "\n"))
            } else {
                _notes = State(initialValue: "")
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Transfer Bilgileri
                Section(header: sectionHeader(title: "Transfer Bilgileri", icon: "airplane")) {
                    // Transfer No - Sadece görüntüleme (otomatik oluşturulacak)
                    if !tripNumber.isEmpty {
                        HStack {
                            Image(systemName: "number")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("Transfer No")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(tripNumber)
                                .foregroundColor(.primary)
                                .fontWeight(.semibold)
                        }
                    } else {
                        HStack {
                            Image(systemName: "number")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("Transfer No")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Otomatik oluşturulacak")
                                .foregroundColor(.orange)
                                .font(.caption)
                                .italic()
                        }
                    }
                    
                    HStack {
                        Image(systemName: "airplane.departure")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        TextField("Uçuş No (Opsiyonel)", text: $flightNumber)
                    }
                    
                    HStack {
                        Image(systemName: "person.2")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Stepper("Yolcu Sayısı: \(passengerCount)", value: $passengerCount, in: 1...20)
                    }
                }
                
                // Yolcu Bilgileri
                Section(header: sectionHeader(title: "Yolcu Bilgileri", icon: "person.fill")) {
                    HStack {
                        Image(systemName: "person.text.rectangle")
                            .foregroundColor(.purple)
                            .frame(width: 24)
                        TextField("Yolcu Adı (Opsiyonel)", text: $passengerName)
                    }
                    
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.purple)
                            .frame(width: 24)
                        TextField("Telefon (Opsiyonel)", text: $passengerPhone)
                            .keyboardType(.phonePad)
                    }
                }
                
                // Alış Noktası
                Section(header: sectionHeader(title: "Alış Noktası", icon: "location.circle.fill")) {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        TextField("Lokasyon (ör: Havalimanı)", text: $pickupLocationName)
                    }
                    
                    HStack(alignment: .top) {
                        Image(systemName: "map.fill")
                            .foregroundColor(.green)
                            .frame(width: 24)
                            .padding(.top, 8)
                        
                        ZStack(alignment: .topLeading) {
                            if pickupAddress.isEmpty {
                                Text("Alış adresini buraya yazın\n(ör: Antalya Havalimanı, Dış Hatlar Terminali, Kapı 3)")
                                    .foregroundColor(.gray.opacity(0.6))
                                    .font(.body)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 8)
                            }
                            
                            TextEditor(text: $pickupAddress)
                                .frame(minHeight: 60)
                                .opacity(pickupAddress.isEmpty ? 0.5 : 1)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .padding(.vertical, 4)
                }
                
                // Bırakış Noktası
                Section(header: sectionHeader(title: "Bırakış Noktası", icon: "location.fill")) {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        TextField("Lokasyon (ör: Otel)", text: $dropoffLocationName)
                    }
                    
                    HStack(alignment: .top) {
                        Image(systemName: "map.fill")
                            .foregroundColor(.orange)
                            .frame(width: 24)
                            .padding(.top, 8)
                        
                        ZStack(alignment: .topLeading) {
                            if dropoffAddress.isEmpty {
                                Text("Bırakış adresini buraya yazın\n(ör: Lara Beach Hotel, Güzeloba Mah. Lara Cad. No:12)")
                                    .foregroundColor(.gray.opacity(0.6))
                                    .font(.body)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 8)
                            }
                            
                            TextEditor(text: $dropoffAddress)
                                .frame(minHeight: 60)
                                .opacity(dropoffAddress.isEmpty ? 0.5 : 1)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .padding(.vertical, 4)
                }
                
                // Tarih ve Saat
                Section(header: sectionHeader(title: "Tarih ve Saat", icon: "clock.fill")) {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        DatePicker("Alış Zamanı", selection: $scheduledPickupTime)
                    }
                    
                    HStack {
                        Image(systemName: "calendar.badge.checkmark")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        DatePicker("Bırakış Zamanı", selection: $scheduledDropoffTime)
                    }
                }
                
                // Ücret ve Notlar
                Section(header: sectionHeader(title: "Ücret ve Notlar", icon: "banknote")) {
                    HStack {
                        Image(systemName: "turkishlirasign.circle.fill")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        TextField("Ücret (TL)", text: $fare)
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack(alignment: .top) {
                        Image(systemName: "note.text")
                            .foregroundColor(.gray)
                            .frame(width: 24)
                            .padding(.top, 8)
                        
                        ZStack(alignment: .topLeading) {
                            if notes.isEmpty {
                                Text("Notlar (Opsiyonel)\n(ör: VIP araç talep edildi, Bebek koltuğu gerekli, vb.)")
                                    .foregroundColor(.gray.opacity(0.6))
                                    .font(.body)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 8)
                            }
                            
                            TextEditor(text: $notes)
                                .frame(minHeight: 80)
                                .opacity(notes.isEmpty ? 0.5 : 1)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .padding(.vertical, 4)
                }
                
                // Atama (Sadece düzenleme modunda)
                if isEditing {
                    Section(header: sectionHeader(title: "Atama", icon: "person.crop.circle.badge.checkmark")) {
                        Picker(selection: $selectedVehicleId) {
                            Text("Araç Seçiniz").tag(nil as String?)
                            ForEach(viewModel.vehicles, id: \.id) { vehicle in
                                HStack {
                                    Image(systemName: "car.fill")
                                    Text(vehicle.displayName)
                                }
                                .tag(vehicle.id as String?)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "car.fill")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                Text("Araç")
                            }
                        }
                        
                        Picker(selection: $selectedDriverId) {
                            Text("Sürücü Seçiniz").tag(nil as String?)
                            ForEach(viewModel.drivers, id: \.id) { driver in
                                HStack {
                                    Image(systemName: "person.fill")
                                    Text(driver.fullName)
                                }
                                .tag(driver.id as String?)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.purple)
                                    .frame(width: 24)
                                Text("Sürücü")
                            }
                        }
                    }
                    
                    Section(header: sectionHeader(title: "Durum", icon: "flag.fill")) {
                        Picker("Transfer Durumu", selection: $status) {
                            ForEach(Trip.TripStatus.allCases, id: \.self) { status in
                                Text(statusText(for: status)).tag(status)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                
                // Hata Mesajı
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(isEditing ? "Transfer Düzenle" : "Yeni Transfer")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark")
                        Text("İptal")
                    }
                },
                trailing: Button(action: {
                    Task {
                        await saveTrip()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                        Text("Kaydet")
                    }
                    .fontWeight(.semibold)
                }
                .disabled(!isFormValid || isLoading)
            )
            .overlay(
                Group {
                    if isLoading {
                        ZStack {
                            Color.black.opacity(0.3)
                                .ignoresSafeArea()
                            
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                
                                Text("Kaydediliyor...")
                                    .foregroundColor(.white)
                                    .font(.headline)
                            }
                            .padding(30)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(16)
                        }
                    }
                }
            )
            .onAppear {
                // Yeni transfer için otomatik numara oluştur
                if !isEditing, tripNumber.isEmpty {
                    generateTripNumber()
                }
            }
        }
    }
    
    private func generateTripNumber() {
        guard let companyId = appViewModel.currentCompany?.id else {
            print("❌ Company ID bulunamadı")
            return
        }
        
        viewModel.generateTripNumber(for: companyId) { [self] generatedNumber in
            DispatchQueue.main.async {
                self.tripNumber = generatedNumber
                print("✅ Transfer numarası oluşturuldu: \(generatedNumber)")
            }
        }
    }
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
            Text(title)
                .font(.headline)
        }
        .foregroundColor(.primary)
    }
    
    private func statusText(for status: Trip.TripStatus) -> String {
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
    
    private var isFormValid: Bool {
        // Transfer no otomatik oluşturulacağı için kontrol etmiyoruz
        !pickupLocationName.isEmpty &&
        !pickupAddress.isEmpty &&
        !dropoffLocationName.isEmpty &&
        !dropoffAddress.isEmpty
    }
    
    private func saveTrip() async {
        isLoading = true
        errorMessage = ""
        
        guard let companyId = appViewModel.currentCompany?.id else {
            errorMessage = "Şirket bilgisi bulunamadı"
            isLoading = false
            return
        }
        
        // Transfer numarası boşsa otomatik oluştur
        if tripNumber.isEmpty && !isEditing {
            await withCheckedContinuation { continuation in
                viewModel.generateTripNumber(for: companyId) { [self] generatedNumber in
                    DispatchQueue.main.async {
                        self.tripNumber = generatedNumber
                        continuation.resume()
                    }
                }
            }
        }
        
        // Basit koordinat oluştur (gerçek uygulamada geocoding kullanılabilir)
        let pickupLocation = TripLocation(
            name: pickupLocationName,
            address: pickupAddress,
            latitude: 0.0,
            longitude: 0.0,
            notes: flightNumber.isEmpty ? nil : "Uçuş No: \(flightNumber)"
        )
        
        let dropoffLocation = TripLocation(
            name: dropoffLocationName,
            address: dropoffAddress,
            latitude: 0.0,
            longitude: 0.0,
            notes: passengerName.isEmpty ? nil : "Yolcu: \(passengerName), Tel: \(passengerPhone)"
        )
        
        var newTrip = Trip(
            companyId: companyId,
            vehicleId: selectedVehicleId ?? "",
            driverId: selectedDriverId ?? "",
            tripNumber: tripNumber,
            pickupLocation: pickupLocation,
            dropoffLocation: dropoffLocation,
            scheduledPickupTime: scheduledPickupTime,
            scheduledDropoffTime: scheduledDropoffTime,
            passengerCount: passengerCount
        )
        
        // Opsiyonel alanları ekle
        if !notes.isEmpty {
            var combinedNotes = notes
            if !passengerName.isEmpty {
                combinedNotes = "Yolcu: \(passengerName)\n" + combinedNotes
            }
            if !passengerPhone.isEmpty {
                combinedNotes += "\nTelefon: \(passengerPhone)"
            }
            if !flightNumber.isEmpty {
                combinedNotes += "\nUçuş No: \(flightNumber)"
            }
            newTrip.notes = combinedNotes
        } else {
            var notesParts: [String] = []
            if !passengerName.isEmpty {
                notesParts.append("Yolcu: \(passengerName)")
            }
            if !passengerPhone.isEmpty {
                notesParts.append("Tel: \(passengerPhone)")
            }
            if !flightNumber.isEmpty {
                notesParts.append("Uçuş: \(flightNumber)")
            }
            if !notesParts.isEmpty {
                newTrip.notes = notesParts.joined(separator: "\n")
            }
        }
        
        if let fareValue = Double(fare.replacingOccurrences(of: ",", with: ".")) {
            newTrip.fare = fareValue
        }
        
        if isEditing {
            newTrip.id = trip?.id
            newTrip.status = status
            newTrip.updatedAt = Date()
            viewModel.updateTrip(newTrip)
        } else {
            viewModel.addTrip(newTrip)
        }
        
        // Kısa bir gecikme ekle
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 saniye
        
        isLoading = false
        
        if viewModel.errorMessage.isEmpty {
            presentationMode.wrappedValue.dismiss()
        } else {
            errorMessage = viewModel.errorMessage
        }
    }
}
