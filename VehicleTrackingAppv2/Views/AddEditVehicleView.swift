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
    @State private var vehicleType = VehicleType.sedan
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
            Form {
                Section(header: Text("Araç Bilgileri")) {
                    TextField("Plaka", text: $plateNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Marka", text: $brand)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Model", text: $model)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Stepper("Yıl: \(formattedYear)", value: $year, in: 1990...Calendar.current.component(.year, from: Date()))
                    
                    Stepper("Kapasite: \(capacity) kişi", value: $capacity, in: 1...50)
                    
                    Picker("Araç Tipi", selection: $vehicleType) {
                        ForEach(VehicleType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    TextField("Renk", text: $color)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section(header: Text("Sigorta ve Muayene")) {
                    VStack(alignment: .leading, spacing: 8) {
                        DatePicker("Sigorta Bitiş Tarihi", 
                                  selection: $insuranceExpiryDate, 
                                  displayedComponents: .date)
                        
                        // Sigorta kalan gün sayısı
                        HStack {
                            Text("Sigorta Durumu:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            let insuranceDays = daysUntilExpiry(insuranceExpiryDate)
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(insuranceDays < 0 ? Color.red : (insuranceDays <= 30 ? Color.orange : Color.green))
                                    .frame(width: 6, height: 6)
                                
                                Text(insuranceDays < 0 ? "Süresi Dolmuş" : (insuranceDays <= 30 ? "\(insuranceDays) gün kaldı" : "Geçerli"))
                                    .font(.caption)
                                    .foregroundColor(insuranceDays < 0 ? .red : (insuranceDays <= 30 ? .orange : .green))
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        DatePicker("Muayene Bitiş Tarihi", 
                                  selection: $inspectionExpiryDate, 
                                  displayedComponents: .date)
                        
                        // Muayene kalan gün sayısı
                        HStack {
                            Text("Muayene Durumu:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            let inspectionDays = daysUntilExpiry(inspectionExpiryDate)
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(inspectionDays < 0 ? Color.red : (inspectionDays <= 30 ? Color.orange : Color.green))
                                    .frame(width: 6, height: 6)
                                
                                Text(inspectionDays < 0 ? "Süresi Dolmuş" : (inspectionDays <= 30 ? "\(inspectionDays) gün kaldı" : "Geçerli"))
                                    .font(.caption)
                                    .foregroundColor(inspectionDays < 0 ? .red : (inspectionDays <= 30 ? .orange : .green))
                            }
                        }
                    }
                }
                
                Section(header: Text("Durum")) {
                    Toggle("Aktif", isOn: $isActive)
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(isEditing ? "Araç Düzenle" : "Yeni Araç")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("İptal") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Kaydet") {
                    saveVehicle()
                }
                .disabled(isLoading || plateNumber.isEmpty || brand.isEmpty || model.isEmpty)
            )
        }
    }
    
    // Yıl değerini formatla
    private var formattedYear: String {
        return "\(year)"
    }
    
    // Kalan gün sayısını hesapla
    private func daysUntilExpiry(_ date: Date) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let expiryDate = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: today, to: expiryDate).day ?? 0
        return days
    }
    
    private func saveVehicle() {
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            if viewModel.errorMessage.isEmpty {
                presentationMode.wrappedValue.dismiss()
            } else {
                errorMessage = viewModel.errorMessage
            }
        }
    }
}

struct AddEditVehicleView_Previews: PreviewProvider {
    static var previews: some View {
        AddEditVehicleView(
            viewModel: VehicleViewModel(),
            appViewModel: AppViewModel()
        )
    }
}
