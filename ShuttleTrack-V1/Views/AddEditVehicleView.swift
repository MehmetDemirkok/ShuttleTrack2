import SwiftUI

struct AddEditVehicleView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: VehicleViewModel
    @StateObject private var appViewModel: AppViewModel
    
    @State private var plateNumber = ""
    @State private var model = ""
    @State private var brand = ""
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var capacity = 4
    @State private var vehicleType = VehicleType.automobile
    @State private var color = ""
    @State private var insuranceExpiryDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var inspectionExpiryDate = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    @State private var isActive = true
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    let vehicle: Vehicle?
    let isEditing: Bool
    
    init(vehicle: Vehicle? = nil, viewModel: VehicleViewModel, appViewModel: AppViewModel) {
        self.vehicle = vehicle
        self.isEditing = vehicle != nil
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._appViewModel = StateObject(wrappedValue: appViewModel)
        
        if let vehicle = vehicle {
            _plateNumber = State(initialValue: vehicle.plateNumber)
            _model = State(initialValue: vehicle.model)
            _brand = State(initialValue: vehicle.brand)
            _year = State(initialValue: vehicle.year)
            _capacity = State(initialValue: vehicle.capacity)
            _vehicleType = State(initialValue: vehicle.vehicleType)
            _color = State(initialValue: vehicle.color)
            _insuranceExpiryDate = State(initialValue: vehicle.insuranceExpiryDate)
            _inspectionExpiryDate = State(initialValue: vehicle.inspectionExpiryDate)
            _isActive = State(initialValue: vehicle.isActive)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Araç Bilgileri
                    FormCard {
                        FormSectionHeader(title: "Araç Bilgileri", icon: "car.fill", iconColor: ShuttleTrackTheme.Colors.vehicleIcon)
                        
                        FormInputField(
                            title: "Plaka",
                            placeholder: "Plaka",
                            icon: "number",
                            iconColor: ShuttleTrackTheme.Colors.vehicleIcon,
                            text: $plateNumber
                        )
                        
                        FormInputField(
                            title: "Marka",
                            placeholder: "Marka",
                            icon: "car.fill",
                            iconColor: ShuttleTrackTheme.Colors.vehicleIcon,
                            text: $brand
                        )
                        
                        FormInputField(
                            title: "Model",
                            placeholder: "Model",
                            icon: "car.fill",
                            iconColor: ShuttleTrackTheme.Colors.vehicleIcon,
                            text: $model
                        )
                        
                        FormYearPickerField(
                            title: "Yıl",
                            icon: "calendar",
                            iconColor: ShuttleTrackTheme.Colors.calendarIcon,
                            selectedYear: $year,
                            minYear: 1990,
                            maxYear: Calendar.current.component(.year, from: Date())
                        )
                        
                        FormCounterField(
                            title: "Kapasite",
                            icon: "person.2",
                            iconColor: ShuttleTrackTheme.Colors.personIcon,
                            value: $capacity,
                            minValue: 1,
                            maxValue: 50
                        )
                        
                        FormPickerField(
                            title: "Araç Tipi",
                            icon: "car.fill",
                            iconColor: ShuttleTrackTheme.Colors.vehicleIcon,
                            selection: Binding(
                                get: { vehicleType.displayName },
                                set: { newValue in
                                    if let newType = VehicleType.allCases.first(where: { $0.displayName == newValue }) {
                                        vehicleType = newType
                                    }
                                }
                            ),
                            options: VehicleType.allCases.map { $0.displayName }
                        )
                        
                        FormInputField(
                            title: "Renk",
                            placeholder: "Renk",
                            icon: "paintbrush.fill",
                            iconColor: ShuttleTrackTheme.Colors.vehicleIcon,
                            text: $color
                        )
                    }
                    
                    // Sigorta ve Muayene
                    FormCard {
                        FormSectionHeader(title: "Sigorta ve Muayene", icon: "doc.text.fill", iconColor: ShuttleTrackTheme.Colors.documentIcon)
                        
                        // Sigorta Bitiş Tarihi
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(ShuttleTrackTheme.Colors.calendarIcon)
                                    .frame(width: 20, height: 20)
                                
                                Text("Sigorta Bitiş Tarihi")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(ShuttleTrackTheme.Colors.secondaryText)
                            }
                            
                            DatePicker("", selection: $insuranceExpiryDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .padding(12)
                                .background(ShuttleTrackTheme.Colors.inputBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(ShuttleTrackTheme.Colors.borderColor, lineWidth: 1)
                                )
                            
                            // Sigorta Durumu
                            HStack {
                                Text("Sigorta Durumu:")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(ShuttleTrackTheme.Colors.tertiaryText)
                                
                                Spacer()
                                
                                let insuranceDays = daysUntilExpiry(insuranceExpiryDate)
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(insuranceDays < 0 ? ShuttleTrackTheme.Colors.error : (insuranceDays <= 30 ? ShuttleTrackTheme.Colors.warning : ShuttleTrackTheme.Colors.success))
                                        .frame(width: 8, height: 8)
                                
                                Text(insuranceDays < 0 ? "Süresi Dolmuş" : (insuranceDays <= 30 ? "\(insuranceDays) gün kaldı" : "Geçerli"))
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(insuranceDays < 0 ? ShuttleTrackTheme.Colors.error : (insuranceDays <= 30 ? ShuttleTrackTheme.Colors.warning : ShuttleTrackTheme.Colors.success))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        
                        // Muayene Bitiş Tarihi
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(ShuttleTrackTheme.Colors.calendarIcon)
                                    .frame(width: 20, height: 20)
                                
                                Text("Muayene Bitiş Tarihi")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(ShuttleTrackTheme.Colors.secondaryText)
                            }
                            
                            DatePicker("", selection: $inspectionExpiryDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .padding(12)
                                .background(ShuttleTrackTheme.Colors.inputBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(ShuttleTrackTheme.Colors.borderColor, lineWidth: 1)
                                )
                            
                            // Muayene Durumu
                            HStack {
                                Text("Muayene Durumu:")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(ShuttleTrackTheme.Colors.tertiaryText)
                                
                                Spacer()
                                
                                let inspectionDays = daysUntilExpiry(inspectionExpiryDate)
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(inspectionDays < 0 ? ShuttleTrackTheme.Colors.error : (inspectionDays <= 30 ? ShuttleTrackTheme.Colors.warning : ShuttleTrackTheme.Colors.success))
                                        .frame(width: 8, height: 8)
                                
                                Text(inspectionDays < 0 ? "Süresi Dolmuş" : (inspectionDays <= 30 ? "\(inspectionDays) gün kaldı" : "Geçerli"))
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(inspectionDays < 0 ? ShuttleTrackTheme.Colors.error : (inspectionDays <= 30 ? ShuttleTrackTheme.Colors.warning : ShuttleTrackTheme.Colors.success))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }
                    
                    // Durum
                    FormCard {
                        FormSectionHeader(title: "Durum", icon: "power", iconColor: ShuttleTrackTheme.Colors.info)
                        
                        FormToggleField(
                            title: "Aktif",
                            icon: "power",
                            iconColor: ShuttleTrackTheme.Colors.info,
                            isOn: $isActive
                        )
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
            .navigationTitle(isEditing ? "Araç Düzenle" : "Yeni Araç")
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
                        await saveVehicle()
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
        }
    }
    
    // Kalan gün sayısını hesapla
    private func daysUntilExpiry(_ date: Date) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let expiryDate = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: today, to: expiryDate).day ?? 0
        return days
    }
    
    private var isFormValid: Bool {
        !plateNumber.isEmpty && !brand.isEmpty && !model.isEmpty
    }
    
    private func saveVehicle() async {
        isLoading = true
        errorMessage = ""
        
        guard let companyId = appViewModel.currentCompany?.id else {
            errorMessage = "Şirket bilgisi bulunamadı"
            isLoading = false
            return
        }
        
        let newVehicle = Vehicle(
            id: vehicle?.id ?? UUID().uuidString,
            plateNumber: plateNumber,
            model: model,
            brand: brand,
            year: year,
            capacity: capacity,
            vehicleType: vehicleType,
            color: color,
            insuranceExpiryDate: insuranceExpiryDate,
            inspectionExpiryDate: inspectionExpiryDate,
            isActive: isActive,
            companyId: companyId
        )
        
        if isEditing {
            viewModel.updateVehicle(newVehicle)
        } else {
            viewModel.addVehicle(newVehicle)
        }
        
        // Simulate save completion
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 saniye
        
            isLoading = false
        
            if viewModel.errorMessage.isEmpty {
                presentationMode.wrappedValue.dismiss()
            } else {
                errorMessage = viewModel.errorMessage
        }
    }
}

// Preview removed - ViewModel requires @MainActor context