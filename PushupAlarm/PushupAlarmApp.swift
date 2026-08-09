import SwiftUI
import UserNotifications

@main
struct PushupAlarmApp: App {
    @StateObject private var alarmManager = AlarmManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var showOnboarding = false
    
    init() {
        requestNotificationPermissions()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if showOnboarding {
                    OnboardingView(isPresented: $showOnboarding)
                        .environmentObject(alarmManager)
                } else {
                    AlarmListView(alarmStore: alarmManager.alarmStore)
                        .environmentObject(alarmManager)
                }
            }
            .onAppear {
                checkOnboardingStatus()
                alarmManager.rescheduleAllAlarms()
            }
            .fullScreenCover(isPresented: $alarmManager.showingChallenge) {
                AlarmChallengeView(
                    isPresented: $alarmManager.showingChallenge,
                    isTestMode: false
                )
                .environmentObject(alarmManager)
            }
        }
    }
    
    private func checkOnboardingStatus() {
        showOnboarding = !alarmManager.alarmStore.hasCompletedOnboarding
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
