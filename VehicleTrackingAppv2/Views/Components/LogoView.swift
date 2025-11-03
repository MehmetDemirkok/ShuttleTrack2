import SwiftUI
import FirebaseAuth

struct LogoView: View {
    let size: CGFloat
    let showText: Bool
    
    init(size: CGFloat = 100, showText: Bool = true) {
        self.size = size
        self.showText = showText
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Logo Icon
            ZStack {
                // Background Circle
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.2, green: 0.6, blue: 1.0),  // Bright Blue
                                Color(red: 0.4, green: 0.8, blue: 1.0),  // Light Blue
                                Color(red: 0.6, green: 0.4, blue: 1.0)   // Purple
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                
                // Shuttle Icon
                VStack(spacing: 2) {
                    // Top part of shuttle
                    HStack(spacing: 1) {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 8, height: 12)
                            .cornerRadius(1)
                        
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 12, height: 16)
                            .cornerRadius(2)
                        
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 8, height: 12)
                            .cornerRadius(1)
                    }
                    
                    // Bottom part of shuttle
                    HStack(spacing: 1) {
                        Rectangle()
                            .fill(Color.white.opacity(0.8))
                            .frame(width: 6, height: 8)
                            .cornerRadius(1)
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.8))
                            .frame(width: 10, height: 12)
                            .cornerRadius(1)
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.8))
                            .frame(width: 6, height: 8)
                            .cornerRadius(1)
                    }
                }
                .scaleEffect(0.6)
            }
            
            // App Name
            if showText {
                VStack(spacing: 2) {
                    Text("Shuttle Track")
                        .font(.system(size: size * 0.2, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Araç Yönetim Sistemleri")
                        .font(.system(size: size * 0.12, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct CompactLogoView: View {
    let size: CGFloat
    
    init(size: CGFloat = 40) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Modern gradient background
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.2, green: 0.6, blue: 1.0),  // Bright Blue
                            Color(red: 0.4, green: 0.8, blue: 1.0),  // Light Blue
                            Color(red: 0.6, green: 0.4, blue: 1.0)   // Purple
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
            
            // User initials or shuttle icon
            if let initials = getUserInitials(), !initials.isEmpty {
                Text(initials)
                    .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            } else {
                // Modern shuttle icon (fallback)
                VStack(spacing: 1) {
                    HStack(spacing: 0.5) {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 4, height: 6)
                            .cornerRadius(0.5)
                        
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 6, height: 8)
                            .cornerRadius(1)
                        
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 4, height: 6)
                            .cornerRadius(0.5)
                    }
                    
                    HStack(spacing: 0.5) {
                        Rectangle()
                            .fill(Color.white.opacity(0.8))
                            .frame(width: 3, height: 4)
                            .cornerRadius(0.5)
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.8))
                            .frame(width: 5, height: 6)
                            .cornerRadius(0.5)
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.8))
                            .frame(width: 3, height: 4)
                            .cornerRadius(0.5)
                    }
                }
                .scaleEffect(0.4)
            }
        }
    }
    
    private func getUserInitials() -> String? {
        // Firebase user'dan displayName al
        if let user = Auth.auth().currentUser, let displayName = user.displayName, !displayName.isEmpty {
            let components = displayName.components(separatedBy: " ")
            if components.count >= 2 {
                return String(components[0].prefix(1)) + String(components[1].prefix(1))
            } else {
                return String(displayName.prefix(2))
            }
        }
        
        // Default initials
        return "MD" // Mehmet Demirkök için
    }
}

struct LogoView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            LogoView(size: 120)
            CompactLogoView(size: 50)
        }
        .padding()
    }
}
