import SwiftUI

struct ShuttleTrackTheme {
    // MARK: - Color Scheme Support
    @Environment(\.colorScheme) static var colorScheme
    
    // MARK: - Colors
    struct Colors {
        // Primary Colors (consistent across themes)
        static let primaryBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
        static let primaryPurple = Color(red: 0.6, green: 0.4, blue: 1.0)
        static let primaryGreen = Color(red: 0.2, green: 0.8, blue: 0.4)
        static let primaryOrange = Color(red: 1.0, green: 0.6, blue: 0.2)
        
        // Secondary Colors
        static let secondaryBlue = Color(red: 0.4, green: 0.8, blue: 1.0)
        static let secondaryPurple = Color(red: 0.8, green: 0.6, blue: 1.0)
        static let secondaryGreen = Color(red: 0.4, green: 0.9, blue: 0.6)
        static let secondaryOrange = Color(red: 1.0, green: 0.8, blue: 0.4)
        
        // Status Colors (consistent across themes)
        static let success = Color(red: 0.2, green: 0.8, blue: 0.4)
        static let warning = Color(red: 1.0, green: 0.6, blue: 0.2)
        static let error = Color(red: 1.0, green: 0.3, blue: 0.3)
        static let info = Color(red: 0.2, green: 0.6, blue: 1.0)
        
        // Dynamic Background Colors
        static var background: Color {
            Color(.systemBackground)
        }
        
        static var cardBackground: Color {
            Color(.secondarySystemBackground)
        }
        
        static var surfaceBackground: Color {
            Color(.tertiarySystemBackground)
        }
        
        static var primaryText: Color {
            Color(.label)
        }
        
        static var secondaryText: Color {
            Color(.secondaryLabel)
        }
        
        static var tertiaryText: Color {
            Color(.tertiaryLabel)
        }
        
        // Form specific colors
        static var formBackground: Color {
            Color(.secondarySystemBackground)
        }
        
        static var inputBackground: Color {
            Color(.tertiarySystemBackground)
        }
        
        static var borderColor: Color {
            Color(.separator)
        }
        
        // Icon colors (semantic colors for different contexts)
        static let pickupIcon = Color(red: 0.2, green: 0.8, blue: 0.4) // Green for pickup
        static let dropoffIcon = Color(red: 1.0, green: 0.6, blue: 0.2) // Orange for dropoff
        static let timeIcon = Color(red: 0.2, green: 0.6, blue: 1.0) // Blue for time
        static let priceIcon = Color(red: 0.0, green: 0.7, blue: 0.7) // Teal for price
        static let personIcon = Color(red: 0.2, green: 0.6, blue: 1.0) // Blue for person
        static let vehicleIcon = Color(red: 0.2, green: 0.6, blue: 1.0) // Blue for vehicle
        static let documentIcon = Color(red: 0.6, green: 0.4, blue: 1.0) // Purple for documents
        static let calendarIcon = Color(red: 0.2, green: 0.6, blue: 1.0) // Blue for calendar
        static let phoneIcon = Color(red: 0.2, green: 0.6, blue: 1.0) // Blue for phone
        static let buildingIcon = Color(red: 1.0, green: 0.6, blue: 0.2) // Orange for building
        static let envelopeIcon = Color(red: 0.2, green: 0.8, blue: 0.4) // Green for email
    }
    
    // MARK: - Gradients
    struct Gradients {
        static let primary = LinearGradient(
            gradient: Gradient(colors: [Colors.primaryBlue, Colors.primaryPurple]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let secondary = LinearGradient(
            gradient: Gradient(colors: [Colors.secondaryBlue, Colors.secondaryPurple]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let success = LinearGradient(
            gradient: Gradient(colors: [Colors.success, Colors.secondaryGreen]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let warning = LinearGradient(
            gradient: Gradient(colors: [Colors.warning, Colors.secondaryOrange]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let card = LinearGradient(
            gradient: Gradient(colors: [Colors.cardBackground, Colors.surfaceBackground]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let small = Color.black.opacity(0.05)
        static let medium = Color.black.opacity(0.1)
        static let large = Color.black.opacity(0.15)
        static let colored = Color.blue.opacity(0.2)
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
}

// MARK: - Custom Button Styles
struct ShuttleTrackButtonStyle: ButtonStyle {
    let variant: ButtonVariant
    let size: ButtonSize
    
    enum ButtonVariant {
        case primary
        case secondary
        case success
        case warning
        case outline
    }
    
    enum ButtonSize {
        case small
        case medium
        case large
    }
    
    init(variant: ButtonVariant = .primary, size: ButtonSize = .medium) {
        self.variant = variant
        self.size = size
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(buttonFont)
            .foregroundColor(buttonForegroundColor)
            .padding(buttonPadding)
            .frame(maxWidth: .infinity)
            .background(buttonBackground)
            .cornerRadius(ShuttleTrackTheme.CornerRadius.medium)
            .shadow(color: ShuttleTrackTheme.Shadows.small, radius: 4, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private var buttonFont: Font {
        switch size {
        case .small: return .system(size: 14, weight: .medium)
        case .medium: return .system(size: 16, weight: .semibold)
        case .large: return .system(size: 18, weight: .bold)
        }
    }
    
    private var buttonPadding: EdgeInsets {
        switch size {
        case .small: return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        case .medium: return EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        case .large: return EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
        }
    }
    
    private var buttonForegroundColor: Color {
        switch variant {
        case .primary, .success, .warning: return .white
        case .secondary: return ShuttleTrackTheme.Colors.primaryBlue
        case .outline: return ShuttleTrackTheme.Colors.primaryBlue
        }
    }
    
    @ViewBuilder
    private var buttonBackground: some View {
        switch variant {
        case .primary:
            ShuttleTrackTheme.Gradients.primary
        case .secondary:
            ShuttleTrackTheme.Colors.surfaceBackground
        case .success:
            ShuttleTrackTheme.Gradients.success
        case .warning:
            ShuttleTrackTheme.Gradients.warning
        case .outline:
            Color.clear
                .overlay(
                    RoundedRectangle(cornerRadius: ShuttleTrackTheme.CornerRadius.medium)
                        .stroke(ShuttleTrackTheme.Colors.primaryBlue, lineWidth: 2)
                )
        }
    }
}

// MARK: - Custom Card Style
struct ShuttleTrackCard: View {
    let content: AnyView
    
    init<Content: View>(@ViewBuilder content: () -> Content) {
        self.content = AnyView(content())
    }
    
    var body: some View {
        content
            .padding(ShuttleTrackTheme.Spacing.md)
            .background(ShuttleTrackTheme.Gradients.card)
            .cornerRadius(ShuttleTrackTheme.CornerRadius.large)
            .shadow(color: ShuttleTrackTheme.Shadows.medium, radius: 8, x: 0, y: 4)
    }
}

// MARK: - Custom Text Styles
extension Text {
    func shuttleTrackTitle() -> some View {
        self
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundColor(.primary)
    }
    
    func shuttleTrackSubtitle() -> some View {
        self
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .foregroundColor(.primary)
    }
    
    func shuttleTrackBody() -> some View {
        self
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundColor(.primary)
    }
    
    func shuttleTrackCaption() -> some View {
        self
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundColor(.secondary)
    }
}

// MARK: - Custom TextField Style
struct ShuttleTrackTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(ShuttleTrackTheme.Spacing.md)
            .background(ShuttleTrackTheme.Colors.surfaceBackground)
            .cornerRadius(ShuttleTrackTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: ShuttleTrackTheme.CornerRadius.medium)
                    .stroke(ShuttleTrackTheme.Colors.primaryBlue.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Modern Stat Card (Shared Component)
struct ModernStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(ShuttleTrackTheme.Colors.primaryText)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ShuttleTrackTheme.Colors.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: color.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}
