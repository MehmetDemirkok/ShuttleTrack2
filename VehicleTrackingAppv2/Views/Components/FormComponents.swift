import SwiftUI

// MARK: - Form Section Header
struct FormSectionHeader: View {
    let title: String
    let icon: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(iconColor)
            
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 12)
    }
}

// MARK: - Form Input Field
struct FormInputField: View {
    let title: String
    let placeholder: String
    let icon: String
    let iconColor: Color
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let isMultiline: Bool
    
    init(title: String, placeholder: String, icon: String, iconColor: Color, text: Binding<String>, keyboardType: UIKeyboardType = .default, isMultiline: Bool = false) {
        self.title = title
        self.placeholder = placeholder
        self.icon = icon
        self.iconColor = iconColor
        self._text = text
        self.keyboardType = keyboardType
        self.isMultiline = isMultiline
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: 20, height: 20)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ShuttleTrackTheme.Colors.secondaryText)
            }
            
            if isMultiline {
                TextEditor(text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                    .padding(12)
                    .background(ShuttleTrackTheme.Colors.inputBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ShuttleTrackTheme.Colors.borderColor, lineWidth: 1)
                    )
                    .frame(minHeight: 80)
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .padding(12)
                    .background(ShuttleTrackTheme.Colors.inputBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ShuttleTrackTheme.Colors.borderColor, lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}

// MARK: - Form Date Time Field
struct FormDateTimeField: View {
    let title: String
    let icon: String
    let iconColor: Color
    @Binding var date: Date
    @Binding var time: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: 20, height: 20)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ShuttleTrackTheme.Colors.secondaryText)
            }
            
            HStack(spacing: 12) {
                // Date Picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tarih")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ShuttleTrackTheme.Colors.tertiaryText)
                    
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
                
                // Time Picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Saat")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ShuttleTrackTheme.Colors.tertiaryText)
                    
                    DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
            }
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
}

// MARK: - Form Counter Field
struct FormCounterField: View {
    let title: String
    let icon: String
    let iconColor: Color
    @Binding var value: Int
    let minValue: Int
    let maxValue: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: 20, height: 20)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ShuttleTrackTheme.Colors.secondaryText)
            }
            
            HStack {
                Button(action: {
                    if value > minValue {
                        value -= 1
                    }
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                        .frame(width: 32, height: 32)
                        .background(ShuttleTrackTheme.Colors.inputBackground)
                        .cornerRadius(8)
                }
                .disabled(value <= minValue)
                
                Spacer()
                
                Text("\(value)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                    .frame(minWidth: 40)
                
                Spacer()
                
                Button(action: {
                    if value < maxValue {
                        value += 1
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                        .frame(width: 32, height: 32)
                        .background(ShuttleTrackTheme.Colors.inputBackground)
                        .cornerRadius(8)
                }
                .disabled(value >= maxValue)
            }
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
}

// MARK: - Form Picker Field
struct FormPickerField: View {
    let title: String
    let icon: String
    let iconColor: Color
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: 20, height: 20)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ShuttleTrackTheme.Colors.secondaryText)
            }
            
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) {
                        selection = option
                    }
                }
            } label: {
                HStack {
                    Text(selection.isEmpty ? "Seçiniz" : selection)
                        .font(.system(size: 16))
                        .foregroundColor(selection.isEmpty ? ShuttleTrackTheme.Colors.tertiaryText : ShuttleTrackTheme.Colors.primaryText)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ShuttleTrackTheme.Colors.secondaryText)
                }
                .padding(12)
                .background(ShuttleTrackTheme.Colors.inputBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ShuttleTrackTheme.Colors.borderColor, lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}

// MARK: - Form Year Picker Field
struct FormYearPickerField: View {
    let title: String
    let icon: String
    let iconColor: Color
    @Binding var selectedYear: Int
    let minYear: Int
    let maxYear: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: 20, height: 20)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ShuttleTrackTheme.Colors.secondaryText)
            }
            
            Menu {
                ForEach(Array(stride(from: maxYear, through: minYear, by: -1)), id: \.self) { year in
                    Button(action: {
                        selectedYear = year
                    }) {
                        Text(String(year))
                    }
                }
            } label: {
                HStack {
                    Text(String(selectedYear))
                        .font(.system(size: 16))
                        .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ShuttleTrackTheme.Colors.secondaryText)
                }
                .padding(12)
                .background(ShuttleTrackTheme.Colors.inputBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ShuttleTrackTheme.Colors.borderColor, lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}

// MARK: - Form Toggle Field
struct FormToggleField: View {
    let title: String
    let icon: String
    let iconColor: Color
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: 20, height: 20)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: ShuttleTrackTheme.Colors.success))
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}

// MARK: - Form Card Container
struct FormCard: View {
    let content: AnyView
    
    init<Content: View>(@ViewBuilder content: () -> Content) {
        self.content = AnyView(content())
    }
    
    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(ShuttleTrackTheme.Colors.formBackground)
        .cornerRadius(16)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let text: String
    let color: Color
    let icon: String?
    
    init(text: String, color: Color, icon: String? = nil) {
        self.text = text
        self.color = color
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color)
        .cornerRadius(12)
    }
}

// MARK: - Document Status Card
struct DocumentStatusCard: View {
    let title: String
    let status: String
    let statusColor: Color
    let icon: String
    let detailText: String?
    
    init(title: String, status: String, statusColor: Color, icon: String, detailText: String? = nil) {
        self.title = title
        self.status = status
        self.statusColor = statusColor
        self.icon = icon
        self.detailText = detailText
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(.white)
                        .frame(width: 8, height: 8)
                    
                    Text(status)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let detailText = detailText {
                Text(detailText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .background(statusColor)
        .cornerRadius(12)
    }
}
