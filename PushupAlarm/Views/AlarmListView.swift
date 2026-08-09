import SwiftUI

struct AlarmListView: View {
    @EnvironmentObject var alarmManager: AlarmManager
    @StateObject private var alarmStore: AlarmStore
    @State private var showingAlarmEditor = false
    @State private var editingAlarm: Alarm?
    
    init(alarmStore: AlarmStore) {
        _alarmStore = StateObject(wrappedValue: alarmStore)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                if alarmStore.alarms.isEmpty {
                    EmptyAlarmState(onAddAlarm: {
                        editingAlarm = nil
                        showingAlarmEditor = true
                    })
                } else {
                    ScrollView {
                        VStack(spacing: 1) {
                            ForEach(alarmStore.alarms) { alarm in
                                AlarmRow(
                                    alarm: alarm,
                                    onToggle: {
                                        toggleAlarm(alarm)
                                    },
                                    onEdit: {
                                        editingAlarm = alarm
                                        showingAlarmEditor = true
                                    },
                                    onDelete: {
                                        deleteAlarm(alarm)
                                    }
                                )
                            }
                        }
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("Alarm")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        editingAlarm = nil
                        showingAlarmEditor = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(DesignSystem.primaryRed)
                    }
                }
            }
            .sheet(isPresented: $showingAlarmEditor) {
                AlarmEditorView(
                    alarm: editingAlarm,
                    onSave: { alarm in
                        saveAlarm(alarm)
                        showingAlarmEditor = false
                    },
                    onCancel: {
                        showingAlarmEditor = false
                    }
                )
            }
        }
    }
    
    private func toggleAlarm(_ alarm: Alarm) {
        alarmStore.toggleAlarm(alarm)
        
        if alarm.isEnabled {
            alarmManager.cancelAlarm(alarm)
        } else {
            alarmManager.scheduleAlarm(alarm)
        }
        
        generateHaptic(.light)
    }
    
    private func saveAlarm(_ alarm: Alarm) {
        if let index = alarmStore.alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarmManager.cancelAlarm(alarmStore.alarms[index])
            alarmStore.updateAlarm(alarm)
        } else {
            alarmStore.addAlarm(alarm)
        }
        
        if alarm.isEnabled {
            alarmManager.scheduleAlarm(alarm)
        }
        
        generateHaptic(.medium)
    }
    
    private func deleteAlarm(_ alarm: Alarm) {
        alarmManager.cancelAlarm(alarm)
        alarmStore.deleteAlarm(alarm)
        generateHaptic(.medium)
    }
    
    private func generateHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

struct EmptyAlarmState: View {
    let onAddAlarm: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "alarm.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.gray)
                
                Text("No Alarms")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Text("Add an alarm to get started")
                    .font(.body)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: onAddAlarm) {
                Text("Add Alarm")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .glassButton()
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(DesignSystem.primaryRed)
                    .padding(.horizontal, 40)
            )
        }
    }
}

struct AlarmRow: View {
    let alarm: Alarm
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(alarm.timeString)
                        .font(.system(size: 48, weight: .thin))
                        .foregroundColor(alarm.isEnabled ? .black : .gray)
                    
                    HStack(spacing: 12) {
                        if alarm.isRepeating {
                            Text(alarm.repeatDescription)
                                .font(.body)
                                .foregroundColor(alarm.isEnabled ? .black : .gray)
                        }
                        
                        if alarm.isRepeating && alarm.pushupCount > 0 {
                            Circle()
                                .fill(alarm.isEnabled ? Color.gray : Color.gray.opacity(0.5))
                                .frame(width: 4, height: 4)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 12))
                            Text("\(alarm.pushupCount)")
                                .font(.body)
                        }
                        .foregroundColor(alarm.isEnabled ? DesignSystem.primaryRed : DesignSystem.primaryRed.opacity(0.5))
                    }
                    
                    if let label = alarm.label, !label.isEmpty {
                        Text(label)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { alarm.isEnabled },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
                .tint(DesignSystem.primaryRed)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(Color.white)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    let store = AlarmStore()
    store.alarms = [
        Alarm(time: Date(), isEnabled: true, pushupCount: 20, repeatDays: [.monday, .tuesday, .wednesday, .thursday, .friday]),
        Alarm(time: Date().addingTimeInterval(3600), isEnabled: false, pushupCount: 10, repeatDays: [])
    ]
    
    return AlarmListView(alarmStore: store)
        .environmentObject(AlarmManager.shared)
}
