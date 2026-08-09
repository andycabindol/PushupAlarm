import Foundation

class AlarmStore: ObservableObject {
    @Published var alarms: [Alarm] = []
    
    private let alarmsKey = "saved_alarms"
    private let hasCompletedOnboardingKey = "has_completed_onboarding"
    
    init() {
        loadAlarms()
    }
    
    var hasCompletedOnboarding: Bool {
        get {
            UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hasCompletedOnboardingKey)
        }
    }
    
    func addAlarm(_ alarm: Alarm) {
        alarms.append(alarm)
        saveAlarms()
    }
    
    func updateAlarm(_ alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index] = alarm
            saveAlarms()
        }
    }
    
    func deleteAlarm(_ alarm: Alarm) {
        alarms.removeAll { $0.id == alarm.id }
        saveAlarms()
    }
    
    func toggleAlarm(_ alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index].isEnabled.toggle()
            saveAlarms()
        }
    }
    
    func getNextAlarm() -> Alarm? {
        let now = Date()
        let calendar = Calendar.current
        let currentWeekday = Weekday.from(date: now)
        
        let enabledAlarms = alarms.filter { $0.isEnabled }
        
        var candidateAlarms: [(alarm: Alarm, fireDate: Date)] = []
        
        for alarm in enabledAlarms {
            let (hour, minute) = alarm.hourMinute
            
            if alarm.isRepeating {
                for day in alarm.repeatDays {
                    if let fireDate = nextFireDate(
                        hour: hour,
                        minute: minute,
                        weekday: day,
                        from: now
                    ) {
                        candidateAlarms.append((alarm, fireDate))
                    }
                }
            } else {
                var components = calendar.dateComponents([.year, .month, .day], from: now)
                components.hour = hour
                components.minute = minute
                components.second = 0
                
                if let fireDate = calendar.date(from: components) {
                    if fireDate <= now {
                        if let nextDay = calendar.date(byAdding: .day, value: 1, to: fireDate) {
                            candidateAlarms.append((alarm, nextDay))
                        }
                    } else {
                        candidateAlarms.append((alarm, fireDate))
                    }
                }
            }
        }
        
        candidateAlarms.sort { $0.fireDate < $1.fireDate }
        return candidateAlarms.first?.alarm
    }
    
    private func nextFireDate(hour: Int, minute: Int, weekday: Weekday, from date: Date) -> Date? {
        let calendar = Calendar.current
        let currentWeekday = Weekday.from(date: date)
        
        var daysToAdd = weekday.rawValue - currentWeekday.rawValue
        if daysToAdd < 0 {
            daysToAdd += 7
        }
        
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        components.second = 0
        
        guard let targetDate = calendar.date(from: components) else { return nil }
        
        if daysToAdd == 0 && targetDate <= date {
            daysToAdd = 7
        }
        
        return calendar.date(byAdding: .day, value: daysToAdd, to: targetDate)
    }
    
    private func saveAlarms() {
        if let encoded = try? JSONEncoder().encode(alarms) {
            UserDefaults.standard.set(encoded, forKey: alarmsKey)
        }
    }
    
    private func loadAlarms() {
        if let data = UserDefaults.standard.data(forKey: alarmsKey),
           let decoded = try? JSONDecoder().decode([Alarm].self, from: data) {
            alarms = decoded
        }
    }
}
