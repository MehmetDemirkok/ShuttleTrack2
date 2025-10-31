import SwiftUI

struct AddEditCargoView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: TripViewModel
    @StateObject private var appViewModel: AppViewModel
    
    // Yük Bilgileri
    @State private var shipmentNumber = ""
    @State private var cargoDescription = ""
    @State private var cargoWeight = ""
    @State private var senderName = ""
    @State private var receiverName = ""
    
    // Lokasyon
    @State private var pickupLocationName = ""
    @State private var pickupAddress = ""
    @State private var dropoffLocationName = ""
    @State private var dropoffAddress = ""
    
    // Zaman
    @State private var scheduledPickupTime = Date()
    @State private var scheduledDropoffTime = Date()
    
    // Atama (opsiyonel)
    @State private var selectedVehicleId: String?
    @State private var selectedDriverId: String?
    
    // UI
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    init(viewModel: TripViewModel, appViewModel: AppViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._appViewModel = StateObject(wrappedValue: appViewModel)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    FormCard {
                        FormSectionHeader(title: "Yük Bilgileri", icon: "shippingbox.fill", iconColor: ShuttleTrackTheme.Colors.warning)
                        FormInputField(
                            title: "Sevkiyat No (Opsiyonel)",
                            placeholder: "Sevkiyat No",
                            icon: "number",
                            iconColor: ShuttleTrackTheme.Colors.warning,
                            text: $shipmentNumber
                        )
                        FormInputField(
                            title: "Yük Açıklaması",
                            placeholder: "(ör: 12 koli elektronik eşya)",
                            icon: "text.justify.left",
                            iconColor: ShuttleTrackTheme.Colors.warning,
                            text: $cargoDescription,
                            isMultiline: true
                        )
                        FormInputField(
                            title: "Ağırlık (kg)",
                            placeholder: "0",
                            icon: "scalemass",
                            iconColor: ShuttleTrackTheme.Colors.warning,
                            text: $cargoWeight,
                            keyboardType: .decimalPad
                        )
                        FormInputField(
                            title: "Gönderici",
                            placeholder: "Gönderici Adı",
                            icon: "person.crop.circle",
                            iconColor: ShuttleTrackTheme.Colors.personIcon,
                            text: $senderName
                        )
                        FormInputField(
                            title: "Alıcı",
                            placeholder: "Alıcı Adı",
                            icon: "person.crop.circle.fill",
                            iconColor: ShuttleTrackTheme.Colors.personIcon,
                            text: $receiverName
                        )
                    }
                    
                    FormCard {
                        FormSectionHeader(title: "Alış Noktası", icon: "location.circle.fill", iconColor: ShuttleTrackTheme.Colors.pickupIcon)
                        FormInputField(
                            title: "Lokasyon",
                            placeholder: "(ör: Depo)",
                            icon: "mappin.circle.fill",
                            iconColor: ShuttleTrackTheme.Colors.pickupIcon,
                            text: $pickupLocationName
                        )
                        FormInputField(
                            title: "Adres",
                            placeholder: "Adres",
                            icon: "map.fill",
                            iconColor: ShuttleTrackTheme.Colors.pickupIcon,
                            text: $pickupAddress,
                            isMultiline: true
                        )
                    }
                    
                    FormCard {
                        FormSectionHeader(title: "Bırakış Noktası", icon: "location.fill", iconColor: ShuttleTrackTheme.Colors.dropoffIcon)
                        FormInputField(
                            title: "Lokasyon",
                            placeholder: "(ör: Mağaza)",
                            icon: "mappin.circle.fill",
                            iconColor: ShuttleTrackTheme.Colors.dropoffIcon,
                            text: $dropoffLocationName
                        )
                        FormInputField(
                            title: "Adres",
                            placeholder: "Adres",
                            icon: "map.fill",
                            iconColor: ShuttleTrackTheme.Colors.dropoffIcon,
                            text: $dropoffAddress,
                            isMultiline: true
                        )
                    }
                    
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
                    
                    if !errorMessage.isEmpty {
                        VStack {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(ShuttleTrackTheme.Colors.error)
                                Text(errorMessage).foregroundColor(ShuttleTrackTheme.Colors.error)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                    Spacer(minLength: 100)
                }
            }
            .background(ShuttleTrackTheme.Colors.background)
            .navigationTitle("Yeni Yük")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: { presentationMode.wrappedValue.dismiss() }) { HStack { Image(systemName: "xmark"); Text("İptal") } },
                trailing: Button(action: { Task { await saveCargo() } }) { HStack { Image(systemName: "checkmark"); Text("Kaydet") } }
            )
        }
    }
    
    private var isFormValid: Bool {
        !cargoDescription.isEmpty && !pickupLocationName.isEmpty && !pickupAddress.isEmpty && !dropoffLocationName.isEmpty && !dropoffAddress.isEmpty
    }
    
    private func saveCargo() async {
        guard isFormValid else { return }
        isLoading = true
        errorMessage = ""
        guard let companyId = appViewModel.currentCompany?.id else {
            errorMessage = "Şirket bilgisi bulunamadı"
            isLoading = false
            return
        }
        
        let pickup = TripLocation(name: pickupLocationName, address: pickupAddress, latitude: 0, longitude: 0, notes: nil)
        let dropoff = TripLocation(name: dropoffLocationName, address: dropoffAddress, latitude: 0, longitude: 0, notes: nil)
        
        var newTrip = Trip(
            companyId: companyId,
            vehicleId: selectedVehicleId ?? "",
            driverId: selectedDriverId ?? "",
            tripNumber: shipmentNumber.isEmpty ? UUID().uuidString : shipmentNumber,
            pickupLocation: pickup,
            dropoffLocation: dropoff,
            scheduledPickupTime: scheduledPickupTime,
            scheduledDropoffTime: scheduledDropoffTime,
            passengerCount: 0
        )
        newTrip.category = .cargo
        
        var cargoNotes: [String] = []
        cargoNotes.append("Yük: \(cargoDescription)")
        if let weight = Double(cargoWeight.replacingOccurrences(of: ",", with: ".")) {
            cargoNotes.append(String(format: "Ağırlık: %.2f kg", weight))
        }
        if !senderName.isEmpty { cargoNotes.append("Gönderici: \(senderName)") }
        if !receiverName.isEmpty { cargoNotes.append("Alıcı: \(receiverName)") }
        newTrip.notes = cargoNotes.joined(separator: "\n")
        
        viewModel.addTrip(newTrip)
        try? await Task.sleep(nanoseconds: 300_000_000)
        isLoading = false
        if viewModel.errorMessage.isEmpty { presentationMode.wrappedValue.dismiss() } else { errorMessage = viewModel.errorMessage }
    }
}



