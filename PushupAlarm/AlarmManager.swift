import Foundation
import UserNotifications
import AVFoundation
import SwiftUI

class AlarmManager: NSObject, ObservableObject {
    static let shared = AlarmManager()
    
    @Published var showingChallenge = false
    @Published var currentAlarm: Alarm?
    @Published var requiredPushups = 10
    
    private var audioPlayer: AVAudioPlayer?
    private let notificationCenter = UNUserNotificationCenter.current()
    let alarmStore = AlarmStore()
    
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
        let alarm = Alarm(
            time: date,
            isEnabled: true,
            pushupCount: requiredPushups,
            repeatDays: []
        )
        alarmStore.addAlarm(alarm)
        scheduleAlarm(alarm)
    }
    
    func scheduleAlarm(_ alarm: Alarm) {
        guard alarm.isEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Wake Up!"
        content.body = "Time to do \(alarm.pushupCount) pushup\(alarm.pushupCount == 1 ? "" : "s")!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("alarm_sound.wav"))
        content.categoryIdentifier = "ALARM_CATEGORY"
        content.userInfo = ["alarmId": alarm.id.uuidString, "pushupCount": alarm.pushupCount]
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: alarm.time)
        
        if alarm.isRepeating {
            for day in alarm.repeatDays {
                var dayComponents = components
                dayComponents.weekday = day.rawValue
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: dayComponents, repeats: true)
                let identifier = "\(alarm.id.uuidString)_\(day.rawValue)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                
                notificationCenter.add(request) { error in
                    if let error = error {
                        print("Error scheduling notification: \(error)")
                    }
                }
            }
        } else {
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: alarm.id.uuidString, content: content, trigger: trigger)
            
            notificationCenter.add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                }
            }
        }
    }
    
    func cancelAlarm(_ alarm: Alarm) {
        if alarm.isRepeating {
            let identifiers = alarm.repeatDays.map { "\(alarm.id.uuidString)_\($0.rawValue)" }
            notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        } else {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [alarm.id.uuidString])
        }
    }
    
    func rescheduleAllAlarms() {
        notificationCenter.removeAllPendingNotificationRequests()
        for alarm in alarmStore.alarms where alarm.isEnabled {
            scheduleAlarm(alarm)
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
        
        if let alarm = currentAlarm, !alarm.isRepeating {
            alarmStore.updateAlarm(Alarm(
                id: alarm.id,
                time: alarm.time,
                isEnabled: false,
                pushupCount: alarm.pushupCount,
                repeatDays: alarm.repeatDays,
                label: alarm.label
            ))
        }
        
        currentAlarm = nil
        showingChallenge = false
    }
}

extension AlarmManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        handleAlarmNotification(notification)
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        handleAlarmNotification(response.notification)
        completionHandler()
    }
    
    private func handleAlarmNotification(_ notification: UNNotification) {
        guard let alarmIdString = notification.request.content.userInfo["alarmId"] as? String,
              let alarmId = UUID(uuidString: alarmIdString),
              let alarm = alarmStore.alarms.first(where: { $0.id == alarmId }) else {
            return
        }
        
        let pushupCount = notification.request.content.userInfo["pushupCount"] as? Int ?? alarm.pushupCount
        
        DispatchQueue.main.async {
            self.currentAlarm = alarm
            self.requiredPushups = pushupCount
            self.showingChallenge = true
            self.playAlarmSound()
        }
    }
}
