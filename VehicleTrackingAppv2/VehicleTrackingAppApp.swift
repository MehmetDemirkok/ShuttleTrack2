//
//  VehicleTrackingAppApp.swift
//  VehicleTrackingApp
//
//  Created by Mehmet Demirkök on 24.10.2025.
//

import SwiftUI
import FirebaseCore
import UIKit

@main
struct ShuttleTrackApp: App {
    @StateObject private var appViewModel = AppViewModel()
    
    // UIApplicationDelegateAdaptor ekleyerek Firebase uyarısını çözüyoruz
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            if appViewModel.isAuthenticated {
                Group {
                    if let profile = appViewModel.currentUserProfile {
                        switch profile.userType {
                        case .companyAdmin:
                            DashboardView()
                                .environmentObject(appViewModel)
                        case .driver:
                            DriverDashboardView()
                                .environmentObject(appViewModel)
                        }
                    } else {
                        // Profil yüklenirken basit loading ekranı
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Profil yükleniyor...")
                        }
                        .environmentObject(appViewModel)
                    }
                }
            } else {
                LoginView()
                    .environmentObject(appViewModel)
            }
        }
    }
}

// Firebase için AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
