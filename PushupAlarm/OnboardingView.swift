import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var selectedTime = Date()
    @State private var pushupCount = 10
    @State private var showingTest = false
    @State private var showingSuccess = false
    @EnvironmentObject var alarmManager: AlarmManager
    
    var body: some View {
        ZStack {
            if currentPage != 3 {
                Color.white.ignoresSafeArea()
            }
            
            if showingSuccess {
                OnboardingSuccessView(
                    selectedTime: selectedTime,
                    pushupCount: pushupCount,
                    onDismiss: {
                        completeOnboarding()
                    }
                )
            } else {
                TabView(selection: $currentPage) {
                    WelcomeSlide(currentPage: $currentPage)
                        .tag(0)
                    
                    AlarmTimeSlide(selectedTime: $selectedTime, currentPage: $currentPage)
                        .tag(1)
                    
                    PushupCountSlide(pushupCount: $pushupCount, currentPage: $currentPage)
                        .tag(2)
                    
                    TestSlide(
                        pushupCount: $pushupCount,
                        showingTest: $showingTest,
                        showingSuccess: $showingSuccess,
                        selectedTime: $selectedTime
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: currentPage == 3 ? .never : .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }
        }
    }
    
    private func completeOnboarding() {
        alarmManager.alarmStore.hasCompletedOnboarding = true
        alarmManager.requiredPushups = pushupCount
        alarmManager.setAlarm(for: selectedTime)
        isPresented = false
    }
}

struct WelcomeSlide: View {
    @Binding var currentPage: Int
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
                Text("💪")
                    .font(.system(size: 100))
                
                Text("Pushup Alarm")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.black)
                
                Text("Wake up stronger, not groggier")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                FeatureRow(icon: "alarm.fill", text: "Set your morning alarm")
                FeatureRow(icon: "figure.strengthtraining.traditional", text: "Do pushups to dismiss it")
                FeatureRow(icon: "brain.head.profile", text: "Start your day energized")
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    currentPage = 1
                }
            }) {
                Text("Get Started")
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

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(DesignSystem.primaryRed)
                .frame(width: 40)
            
            Text(text)
                .font(.body)
                .foregroundColor(.black)
            
            Spacer()
        }
        .padding()
        .glassCard()
    }
}

struct AlarmTimeSlide: View {
    @Binding var selectedTime: Date
    @Binding var currentPage: Int
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("⏰")
                    .font(.system(size: 80))
                
                Text("When should we wake you?")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                Text("Set your alarm time")
                    .font(.body)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 40)
            
            DatePicker(
                "Alarm Time",
                selection: $selectedTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .padding()
            .glassCard()
            .padding(.horizontal, 40)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    currentPage = 2
                }
            }) {
                Text("Continue")
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

struct PushupCountSlide: View {
    @Binding var pushupCount: Int
    @Binding var currentPage: Int
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("💪")
                    .font(.system(size: 80))
                
                Text("How many pushups?")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                Text("Choose your daily challenge")
                    .font(.body)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 40)
            
            VStack(spacing: 24) {
                Text("\(pushupCount)")
                    .font(.system(size: 80, weight: .bold))
                    .foregroundColor(DesignSystem.primaryRed)
                
                HStack(spacing: 20) {
                    Button(action: {
                        if pushupCount > 5 {
                            pushupCount -= 5
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(pushupCount > 5 ? .black : .gray)
                    }
                    .disabled(pushupCount <= 5)
                    
                    Button(action: {
                        if pushupCount < 100 {
                            pushupCount += 5
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(pushupCount < 100 ? .black : .gray)
                    }
                    .disabled(pushupCount >= 100)
                }
                
                Text("pushups to dismiss alarm")
                    .font(.body)
                    .foregroundColor(.gray)
            }
            .padding(40)
            .glassCard()
            .padding(.horizontal, 40)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    currentPage = 3
                }
            }) {
                Text("Continue")
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

struct TestSlide: View {
    @Binding var pushupCount: Int
    @Binding var showingTest: Bool
    @Binding var showingSuccess: Bool
    @Binding var selectedTime: Date
    @EnvironmentObject var alarmManager: AlarmManager
    @StateObject private var pushupDetector = PushupDetector()
    @State private var testCompleted = false
    
    var body: some View {
        ZStack {
            CameraView(pushupDetector: pushupDetector)
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                let lineY = geometry.size.height * 0.65
                
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: lineY - 1)
                    
                    Rectangle()
                        .fill(DesignSystem.primaryRed)
                        .frame(height: 2)
                        .overlay(
                            Rectangle()
                                .fill(DesignSystem.primaryRed.opacity(0.3))
                                .frame(height: 30)
                        )
                    
                    Spacer()
                }
            }
            .allowsHitTesting(false)
            
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    Text("Let's test it!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 10)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        CompactInstruction(text: "Place phone on floor, camera facing you")
                        CompactInstruction(text: "Dip your head below the red line")
                        CompactInstruction(text: "Do \(pushupCount) pushup\(pushupCount == 1 ? "" : "s")")
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .padding(.top, 50)
                .padding(.horizontal, 24)
                
                Spacer()
                
                VStack(spacing: 20) {
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("\(pushupDetector.pushupCount)")
                            .font(.system(size: 80, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(" / \(pushupCount)")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .shadow(color: .black.opacity(0.5), radius: 10)
                    
                    if pushupDetector.bodyDetected {
                        Text(pushupDetector.feedback)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .shadow(color: .black.opacity(0.2), radius: 8)
                    } else {
                        Text("Position yourself in front of the camera")
                            .font(.body)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.5))
                            )
                    }
                }
                .padding(.bottom, 30)
                
                Button(action: {
                    showingSuccess = true
                }) {
                    Text("Skip")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.5))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                .padding(.bottom, 50)
            }
        }
        .onChange(of: pushupDetector.pushupCount) { oldValue, newValue in
            if newValue >= pushupCount && !testCompleted {
                testCompleted = true
                generateHaptic(.success)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showingSuccess = true
                }
            } else if newValue > oldValue {
                generateHaptic(.light)
            }
        }
    }
    
    private func generateHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

struct CompactInstruction: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(DesignSystem.primaryRed)
                .frame(width: 6, height: 6)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

struct OnboardingSuccessView: View {
    let selectedTime: Date
    let pushupCount: Int
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    var body: some View {
        VStack(spacing: 48) {
            Spacer()
            
            VStack(spacing: 24) {
                Text("✓")
                    .font(.system(size: 100, weight: .bold))
                    .foregroundColor(DesignSystem.primaryRed)
                
                Text("Your alarm is set")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.black)
                
                Text("Wake up. Get moving.\nGet your day back.")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            VStack(spacing: 20) {
                HStack(spacing: 16) {
                    Image(systemName: "alarm.fill")
                        .font(.system(size: 24))
                        .foregroundColor(DesignSystem.primaryRed)
                    
                    Text(timeString(from: selectedTime))
                        .font(.system(size: 48, weight: .thin))
                        .foregroundColor(.black)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    
                    Text("\(pushupCount) push-up\(pushupCount == 1 ? "" : "s")")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
            }
            .padding(32)
            .glassCard()
            .padding(.horizontal, 40)
            
            Spacer()
            
            Button(action: {
                onDismiss()
            }) {
                Text("Done")
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
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            generateHaptic(.success)
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func generateHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

struct InstructionRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(DesignSystem.primaryRed)
                    .frame(width: 32, height: 32)
                
                Text("\(number)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text(text)
                .font(.body)
                .foregroundColor(.black)
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
        .environmentObject(AlarmManager.shared)
}
