import Foundation
import UserNotifications
import AVFoundation
import SwiftUI

class AlarmManager: NSObject, ObservableObject {
    static let shared = AlarmManager()
    
    @Published var isAlarmSet = false
    @Published var alarmTime: Date?
    @Published var showingChallenge = false
    
    private var audioPlayer: AVAudioPlayer?
    private let notificationCenter = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        notificationCenter.delegate = self
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func setAlarm(for date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Wake Up!"
        content.body = "Time to do 10 pushups!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("alarm_sound.wav"))
        content.categoryIdentifier = "ALARM_CATEGORY"
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "pushupAlarm", content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error scheduling notification: \(error)")
                } else {
                    self.isAlarmSet = true
                    self.alarmTime = date
                    print("Alarm set for \(date)")
                }
            }
        }
    }
    
    func cancelAlarm() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["pushupAlarm"])
        stopAlarmSound()
        isAlarmSet = false
        alarmTime = nil
    }
    
    func checkForActiveAlarm() {
        notificationCenter.getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                self.isAlarmSet = requests.contains(where: { $0.identifier == "pushupAlarm" })
                if self.isAlarmSet, let request = requests.first(where: { $0.identifier == "pushupAlarm" }),
                   let trigger = request.trigger as? UNCalendarNotificationTrigger,
                   let nextTriggerDate = trigger.nextTriggerDate() {
                    self.alarmTime = nextTriggerDate
                }
            }
        }
    }
    
    func playAlarmSound() {
        guard let soundURL = Bundle.main.url(forResource: "alarm_sound", withExtension: "wav") else {
            print("Alarm sound file not found")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.volume = 1.0
            audioPlayer?.play()
        } catch {
            print("Failed to play alarm sound: \(error)")
        }
    }
    
    func stopAlarmSound() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    func alarmCompleted() {
        stopAlarmSound()
        cancelAlarm()
        showingChallenge = false
    }
}

extension AlarmManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if notification.request.identifier == "pushupAlarm" {
            DispatchQueue.main.async {
                self.showingChallenge = true
                self.playAlarmSound()
            }
            completionHandler([.banner, .sound])
        } else {
            completionHandler([.banner, .sound, .badge])
        }
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.notification.request.identifier == "pushupAlarm" {
            DispatchQueue.main.async {
                self.showingChallenge = true
                self.playAlarmSound()
            }
        }
        completionHandler()
    }
}
