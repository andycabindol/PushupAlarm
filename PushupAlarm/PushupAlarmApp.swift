import SwiftUI
import UserNotifications

@main
struct PushupAlarmApp: App {
    @StateObject private var alarmManager = AlarmManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        requestNotificationPermissions()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(alarmManager)
                .onAppear {
                    alarmManager.checkForActiveAlarm()
                }
        }
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
}
