import Foundation

struct Alarm: Identifiable, Codable {
    let id: UUID
    var time: Date
    var isEnabled: Bool
    var pushupCount: Int
    var repeatDays: Set<Weekday>
    var label: String?
    
    init(
        id: UUID = UUID(),
        time: Date = Date(),
        isEnabled: Bool = true,
        pushupCount: Int = 10,
        repeatDays: Set<Weekday> = [],
        label: String? = nil
    ) {
        self.id = id
        self.time = time
        self.isEnabled = isEnabled
        self.pushupCount = pushupCount
        self.repeatDays = repeatDays
        self.label = label
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
    
    var hourMinute: (hour: Int, minute: Int) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        return (components.hour ?? 0, components.minute ?? 0)
    }
    
    var isRepeating: Bool {
        !repeatDays.isEmpty
    }
    
    var repeatDescription: String {
        if repeatDays.isEmpty {
            return "Never"
        }
        
        let allDays: Set<Weekday> = Set(Weekday.allCases)
        if repeatDays == allDays {
            return "Every day"
        }
        
        let weekdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
        if repeatDays == weekdays {
            return "Weekdays"
        }
        
        let weekend: Set<Weekday> = [.saturday, .sunday]
        if repeatDays == weekend {
            return "Weekends"
        }
        
        let sorted = repeatDays.sorted { $0.rawValue < $1.rawValue }
        return sorted.map { $0.shortName }.joined(separator: " ")
    }
}

enum Weekday: Int, Codable, CaseIterable, Comparable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    var name: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
    
    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
    
    var veryShortName: String {
        switch self {
        case .sunday: return "S"
        case .monday: return "M"
        case .tuesday: return "T"
        case .wednesday: return "W"
        case .thursday: return "T"
        case .friday: return "F"
        case .saturday: return "S"
        }
    }
    
    static func < (lhs: Weekday, rhs: Weekday) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    static func from(date: Date) -> Weekday {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        return Weekday(rawValue: weekday) ?? .sunday
    }
}
