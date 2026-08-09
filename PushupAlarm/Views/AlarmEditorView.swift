import SwiftUI

struct AlarmEditorView: View {
    let alarm: Alarm?
    let onSave: (Alarm) -> Void
    let onCancel: () -> Void
    
    @State private var time: Date
    @State private var pushupCount: Int
    @State private var repeatDays: Set<Weekday>
    @State private var label: String
    
    init(alarm: Alarm?, onSave: @escaping (Alarm) -> Void, onCancel: @escaping () -> Void) {
        self.alarm = alarm
        self.onSave = onSave
        self.onCancel = onCancel
        
        _time = State(initialValue: alarm?.time ?? Date())
        _pushupCount = State(initialValue: alarm?.pushupCount ?? 10)
        _repeatDays = State(initialValue: alarm?.repeatDays ?? [])
        _label = State(initialValue: alarm?.label ?? "")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        VStack(spacing: 16) {
                            Text("Time")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            DatePicker(
                                "Alarm Time",
                                selection: $time,
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                        }
                        .padding(.horizontal, 24)
                        
                        Divider()
                            .padding(.horizontal, 24)
                        
                        VStack(spacing: 16) {
                            Text("Repeat")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 12) {
                                ForEach(Weekday.allCases, id: \.self) { day in
                                    WeekdayButton(
                                        day: day,
                                        isSelected: repeatDays.contains(day),
                                        onToggle: {
                                            toggleDay(day)
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Divider()
                            .padding(.horizontal, 24)
                        
                        VStack(spacing: 16) {
                            Text("Push-ups")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 24) {
                                Button(action: {
                                    if pushupCount > 1 {
                                        pushupCount -= 1
                                        generateHaptic(.light)
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 44))
                                        .foregroundColor(pushupCount > 1 ? .black : .gray)
                                }
                                .disabled(pushupCount <= 1)
                                
                                Spacer()
                                
                                Text("\(pushupCount)")
                                    .font(.system(size: 72, weight: .bold))
                                    .foregroundColor(DesignSystem.primaryRed)
                                    .frame(minWidth: 120)
                                
                                Spacer()
                                
                                Button(action: {
                                    if pushupCount < 100 {
                                        pushupCount += 1
                                        generateHaptic(.light)
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 44))
                                        .foregroundColor(pushupCount < 100 ? .black : .gray)
                                }
                                .disabled(pushupCount >= 100)
                            }
                            .padding(.vertical, 20)
                        }
                        .padding(.horizontal, 24)
                        
                        Divider()
                            .padding(.horizontal, 24)
                        
                        VStack(spacing: 16) {
                            Text("Label (Optional)")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            TextField("e.g., Morning workout", text: $label)
                                .font(.body)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.1))
                                )
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 24)
                }
            }
            .navigationTitle(alarm == nil ? "Add Alarm" : "Edit Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.gray)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .foregroundColor(DesignSystem.primaryRed)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func toggleDay(_ day: Weekday) {
        if repeatDays.contains(day) {
            repeatDays.remove(day)
        } else {
            repeatDays.insert(day)
        }
        generateHaptic(.light)
    }
    
    private func save() {
        let savedAlarm = Alarm(
            id: alarm?.id ?? UUID(),
            time: time,
            isEnabled: true,
            pushupCount: pushupCount,
            repeatDays: repeatDays,
            label: label.isEmpty ? nil : label
        )
        onSave(savedAlarm)
        generateHaptic(.medium)
    }
    
    private func generateHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

struct WeekdayButton: View {
    let day: Weekday
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            ZStack {
                Circle()
                    .fill(isSelected ? DesignSystem.primaryRed : Color.gray.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Text(day.veryShortName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .gray)
            }
        }
    }
}

#Preview {
    AlarmEditorView(
        alarm: nil,
        onSave: { _ in },
        onCancel: {}
    )
}
