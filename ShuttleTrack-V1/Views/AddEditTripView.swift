import SwiftUI

struct AddEditTripView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: TripViewModel
    @StateObject private var appViewModel: AppViewModel
    
    // Temel Bilgiler
    @State private var tripNumber = ""
    @State private var passengerCount = 1
    struct PassengerEntry: Identifiable, Equatable {
        let id = UUID()
        var name: String = ""
        var phone: String = ""
    }
    @State private var passengers: [PassengerEntry] = [PassengerEntry()]
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
                var parsedPassengers: [PassengerEntry] = []
                
                for line in lines {
                    if line.hasPrefix("Yolcu:") {
                        let name = line.replacingOccurrences(of: "Yolcu: ", with: "")
                        parsedPassengers.append(PassengerEntry(name: name, phone: ""))
                    } else if line.hasPrefix("Tel:") || line.hasPrefix("Telefon:") {
                        let phone = line.replacingOccurrences(of: "Tel: ", with: "")
                            .replacingOccurrences(of: "Telefon: ", with: "")
                        if parsedPassengers.isEmpty {
                            parsedPassengers.append(PassengerEntry(name: "", phone: phone))
                        } else {
                            parsedPassengers[parsedPassengers.count - 1].phone = phone
                        }
                    } else if line.hasPrefix("Uçuş:") || line.hasPrefix("Uçuş No:") {
                        let flight = line.replacingOccurrences(of: "Uçuş: ", with: "")
                            .replacingOccurrences(of: "Uçuş No: ", with: "")
                        _flightNumber = State(initialValue: flight)
                    } else if !line.isEmpty {
                        cleanNotes.append(line)
                    }
                }
                
                _notes = State(initialValue: cleanNotes.joined(separator: "\n"))
                if !parsedPassengers.isEmpty {
                    _passengers = State(initialValue: parsedPassengers)
                }
            } else {
                _notes = State(initialValue: "")
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                // Transfer Bilgileri
                    FormCard {
                        FormSectionHeader(title: "Transfer Bilgileri", icon: "airplane", iconColor: ShuttleTrackTheme.Colors.info)
                        
                        // Transfer No - Sadece görüntüleme
                    if !tripNumber.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                            Image(systemName: "number")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(ShuttleTrackTheme.Colors.info)
                                        .frame(width: 20, height: 20)
                                    
                            Text("Transfer No")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(ShuttleTrackTheme.Colors.secondaryText)
                                }
                                
                            Text(tripNumber)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                                    .padding(12)
                                    .background(ShuttleTrackTheme.Colors.inputBackground)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(ShuttleTrackTheme.Colors.borderColor, lineWidth: 1)
                                    )
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                        }
                        
                        FormInputField(
                            title: "Uçuş No (Opsiyonel)",
                            placeholder: "Uçuş No",
                            icon: "airplane.departure",
                            iconColor: ShuttleTrackTheme.Colors.info,
                            text: $flightNumber
                        )
                        
                        FormCounterField(
                            title: "Yolcu Sayısı",
                            icon: "person.2",
                            iconColor: ShuttleTrackTheme.Colors.info,
                            value: $passengerCount,
                            minValue: 1,
                            maxValue: 20
                        )
                }
                
                // Yolcu Bilgileri
                    FormCard {
                        FormSectionHeader(title: "Yolcu Bilgileri", icon: "person.fill", iconColor: ShuttleTrackTheme.Colors.personIcon)
                        
                        ForEach(Array(passengers.enumerated()), id: \.element.id) { index, _ in
                            FormInputField(
                                title: passengers.count > 1 ? "Yolcu Adı #\(index + 1) (Opsiyonel)" : "Yolcu Adı (Opsiyonel)",
                                placeholder: "Yolcu Adı",
                                icon: "person.text.rectangle",
                                iconColor: ShuttleTrackTheme.Colors.personIcon,
                                text: Binding(
                                    get: { passengers[index].name },
                                    set: { passengers[index].name = $0 }
                                )
                            )
                            
                            FormInputField(
                                title: passengers.count > 1 ? "Telefon #\(index + 1) (Opsiyonel)" : "Telefon (Opsiyonel)",
                                placeholder: "Telefon",
                                icon: "phone.fill",
                                iconColor: ShuttleTrackTheme.Colors.phoneIcon,
                                text: Binding(
                                    get: { passengers[index].phone },
                                    set: { passengers[index].phone = $0 }
                                ),
                                keyboardType: .phonePad
                            )
                        }
                    }
                    
                    // Alış Noktası
                    FormCard {
                        FormSectionHeader(title: "Alış Noktası", icon: "location.circle.fill", iconColor: ShuttleTrackTheme.Colors.pickupIcon)
                        
                        FormInputField(
                            title: "Lokasyon (ör: Havalimanı)",
                            placeholder: "Lokasyon",
                            icon: "mappin.circle.fill",
                            iconColor: ShuttleTrackTheme.Colors.pickupIcon,
                            text: $pickupLocationName
                        )
                        
                        FormInputField(
                            title: "Alış adresini buraya yazın",
                            placeholder: "(ör: Antalya Havalimanı, Dış Hatlar Terminali, Kapı 3)",
                            icon: "map.fill",
                            iconColor: ShuttleTrackTheme.Colors.pickupIcon,
                            text: $pickupAddress,
                            isMultiline: true
                        )
                    }
                    
                    // Bırakış Noktası
                    FormCard {
                        FormSectionHeader(title: "Bırakış Noktası", icon: "location.fill", iconColor: ShuttleTrackTheme.Colors.dropoffIcon)
                        
                        FormInputField(
                            title: "Lokasyon (ör: Otel)",
                            placeholder: "Lokasyon",
                            icon: "mappin.circle.fill",
                            iconColor: ShuttleTrackTheme.Colors.dropoffIcon,
                            text: $dropoffLocationName
                        )
                        
                        FormInputField(
                            title: "Bırakış adresini buraya yazın",
                            placeholder: "(ör: Lara Beach Hotel, Güzeloba Mah. Lara Cad. No:12)",
                            icon: "map.fill",
                            iconColor: ShuttleTrackTheme.Colors.dropoffIcon,
                            text: $dropoffAddress,
                            isMultiline: true
                        )
                    }
                    
                    // Tarih ve Saat
                    FormCard {
                        FormSectionHeader(title: "Tarih ve Saat", icon: "clock.fill", iconColor: ShuttleTrackTheme.Colors.timeIcon)
                        
                        FormDateTimeField(
                            title: "Alış Zamanı",
                            icon: "calendar.badge.clock",
                            iconColor: ShuttleTrackTheme.Colors.timeIcon,
                            date: $scheduledPickupTime,
                            time: $scheduledPickupTime
                        )
                        
                        FormDateTimeField(
                            title: "Bırakış Zamanı",
                            icon: "calendar.badge.checkmark",
                            iconColor: ShuttleTrackTheme.Colors.timeIcon,
                            date: $scheduledDropoffTime,
                            time: $scheduledDropoffTime
                        )
                    }
                    
                    // Ücret ve Notlar
                    FormCard {
                        FormSectionHeader(title: "Ücret ve Notlar", icon: "banknote", iconColor: ShuttleTrackTheme.Colors.priceIcon)
                        
                        FormInputField(
                            title: "Ücret (TL)",
                            placeholder: "Ücret",
                            icon: "turkishlirasign.circle.fill",
                            iconColor: ShuttleTrackTheme.Colors.priceIcon,
                            text: $fare,
                            keyboardType: .decimalPad
                        )
                        
                        FormInputField(
                            title: "Notlar (Opsiyonel)",
                            placeholder: "(ör: VIP araç talep edildi, Bebek koltuğu gerekli, vb.)",
                            icon: "note.text",
                            iconColor: ShuttleTrackTheme.Colors.documentIcon,
                            text: $notes,
                            isMultiline: true
                        )
                }
                
                // Atama (Sadece düzenleme modunda)
                if isEditing {
                        FormCard {
                            FormSectionHeader(title: "Atama", icon: "person.crop.circle.badge.checkmark", iconColor: ShuttleTrackTheme.Colors.info)
                            
                            FormPickerField(
                                title: "Araç",
                                icon: "car.fill",
                                iconColor: ShuttleTrackTheme.Colors.vehicleIcon,
                                selection: Binding(
                                    get: { selectedVehicleId ?? "" },
                                    set: { selectedVehicleId = $0.isEmpty ? nil : $0 }
                                ),
                                options: [""] + viewModel.vehicles.map { $0.displayName }
                            )
                            
                            FormPickerField(
                                title: "Sürücü",
                                icon: "person.fill",
                                iconColor: ShuttleTrackTheme.Colors.personIcon,
                                selection: Binding(
                                    get: { selectedDriverId ?? "" },
                                    set: { selectedDriverId = $0.isEmpty ? nil : $0 }
                                ),
                                options: [""] + viewModel.drivers.map { $0.fullName }
                            )
                        }
                        
                        FormCard {
                            FormSectionHeader(title: "Durum", icon: "flag.fill", iconColor: ShuttleTrackTheme.Colors.info)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Transfer Durumu")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(ShuttleTrackTheme.Colors.secondaryText)
                                    .padding(.horizontal, 20)
                                
                                Picker("Transfer Durumu", selection: $status) {
                                    ForEach(Trip.TripStatus.allCases, id: \.self) { status in
                                        Text(status.displayText).tag(status)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding(.horizontal, 20)
                            }
                            .padding(.bottom, 16)
                        }
                    }
                    
                    // Hata Mesajı
                    if !errorMessage.isEmpty {
                        VStack {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(ShuttleTrackTheme.Colors.error)
                                Text(errorMessage)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(ShuttleTrackTheme.Colors.error)
                            }
                            .padding()
                            .background(ShuttleTrackTheme.Colors.error.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                    
                    // Bottom padding
                    Spacer(minLength: 100)
                }
            }
            .background(ShuttleTrackTheme.Colors.background)
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
                    .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
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
                    .font(.headline)
                    .foregroundColor(isFormValid ? ShuttleTrackTheme.Colors.primaryBlue : ShuttleTrackTheme.Colors.tertiaryText)
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
                // Yolcu sayısı ile passengers senkronize başlat
                syncPassengersWithCount()
            }
            .onChange(of: passengerCount) { _ in
                syncPassengersWithCount()
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
            notes: nil
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
        // Yolcu taşıma formu
        newTrip.category = .passenger
        
        // Opsiyonel alanları ekle
        if !notes.isEmpty {
            var combinedNotes = notes
            let passengerLines = passengers
                .filter { !$0.name.isEmpty || !$0.phone.isEmpty }
                .map { entry in
                    var parts: [String] = []
                    if !entry.name.isEmpty { parts.append("Yolcu: \(entry.name)") }
                    if !entry.phone.isEmpty { parts.append("Telefon: \(entry.phone)") }
                    return parts.joined(separator: "\n")
                }
                .joined(separator: "\n")
            if !passengerLines.isEmpty {
                combinedNotes = passengerLines + (combinedNotes.isEmpty ? "" : "\n") + combinedNotes
            }
            if !flightNumber.isEmpty {
                combinedNotes += "\nUçuş No: \(flightNumber)"
            }
            newTrip.notes = combinedNotes
        } else {
            var notesParts: [String] = []
            for entry in passengers where !entry.name.isEmpty || !entry.phone.isEmpty {
                if !entry.name.isEmpty { notesParts.append("Yolcu: \(entry.name)") }
                if !entry.phone.isEmpty { notesParts.append("Tel: \(entry.phone)") }
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

    private func syncPassengersWithCount() {
        if passengerCount < 1 { passengerCount = 1 }
        if passengers.count < passengerCount {
            let toAdd = passengerCount - passengers.count
            passengers.append(contentsOf: Array(repeating: PassengerEntry(), count: toAdd))
        } else if passengers.count > passengerCount {
            passengers.removeLast(passengers.count - passengerCount)
        }
    }
}
