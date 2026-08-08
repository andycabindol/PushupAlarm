import SwiftUI

struct ContentView: View {
    @EnvironmentObject var alarmManager: AlarmManager
    @State private var selectedTime = Date()
    @State private var showingChallenge = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Text("💪 Pushup Alarm")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if alarmManager.isAlarmSet {
                        VStack(spacing: 20) {
                            Text("Alarm Set For:")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.9))
                            
                            Text(alarmManager.alarmTime ?? Date(), style: .time)
                                .font(.system(size: 50, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Do 10 pushups to dismiss!")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Button(action: {
                                alarmManager.cancelAlarm()
                            }) {
                                Text("Cancel Alarm")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(15)
                            }
                            .padding(.horizontal, 40)
                        }
                    } else {
                        VStack(spacing: 20) {
                            DatePicker(
                                "Select Time",
                                selection: $selectedTime,
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(20)
                            
                            Button(action: {
                                alarmManager.setAlarm(for: selectedTime)
                            }) {
                                HStack {
                                    Image(systemName: "alarm.fill")
                                    Text("Set Alarm")
                                }
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.green, .blue]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(15)
                            }
                            .padding(.horizontal, 40)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showingChallenge = true
                    }) {
                        Text("Test Pushup Detection")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.7))
                            .underline()
                    }
                }
                .padding()
            }
            .fullScreenCover(isPresented: $showingChallenge) {
                AlarmChallengeView(isPresented: $showingChallenge, isTestMode: true)
            }
            .fullScreenCover(isPresented: $alarmManager.showingChallenge) {
                AlarmChallengeView(
                    isPresented: $alarmManager.showingChallenge,
                    isTestMode: false
                )
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AlarmManager.shared)
}
