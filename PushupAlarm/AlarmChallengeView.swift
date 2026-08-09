import SwiftUI

struct AlarmChallengeView: View {
    @Binding var isPresented: Bool
    let isTestMode: Bool
    @StateObject private var pushupDetector = PushupDetector()
    @EnvironmentObject var alarmManager: AlarmManager
    @State private var showSuccess = false
    @State private var requiredPushups = 10
    
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
            
            VStack {
                HStack {
                    Spacer()
                    
                    if isTestMode {
                        Button(action: {
                            isPresented = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 5)
                        }
                        .padding()
                    }
                }
                
                if !isTestMode && pushupDetector.pushupCount == 0 {
                    VStack(spacing: 24) {
                        Text("GET UP")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 10)
                        
                        Text("\(requiredPushups) push-up\(requiredPushups == 1 ? "" : "s")")
                            .font(.title)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 5)
                        
                        Text("Tap to start")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.top, 8)
                    }
                    .frame(maxHeight: .infinity)
                    .padding(.bottom, 100)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Detector starts automatically
                    }
                }
                
                if isTestMode || pushupDetector.pushupCount > 0 || pushupDetector.bodyDetected {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            Text("\(pushupDetector.pushupCount)")
                                .font(.system(size: 80, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text(" / \(requiredPushups)")
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
                        }
                    }
                    .padding(.bottom, 60)
                }
            }
            
            if showSuccess {
                CompletionOverlay(
                    pushupCount: requiredPushups,
                    isAlarm: !isTestMode
                )
            }
        }
        .onChange(of: pushupDetector.pushupCount) { oldValue, newValue in
            if newValue >= requiredPushups && !showSuccess {
                completeChallenge()
            } else if newValue > oldValue {
                generateHaptic(.light)
            }
        }
        .onAppear {
            requiredPushups = alarmManager.requiredPushups
            if !isTestMode {
                alarmManager.playAlarmSound()
            }
        }
    }
    
    private func completeChallenge() {
        showSuccess = true
        generateHaptic(.success)
        
        if !isTestMode {
            alarmManager.alarmCompleted()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                isPresented = false
            }
        }
    }
    
    private func generateHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

struct CompletionOverlay: View {
    let pushupCount: Int
    let isAlarm: Bool
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Text("✓")
                    .font(.system(size: 100, weight: .bold))
                    .foregroundColor(DesignSystem.primaryRed)
                
                if isAlarm {
                    Text("You're up.")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("Nice work!")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("\(pushupCount) push-up\(pushupCount == 1 ? "" : "s") complete")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
                
                if isAlarm {
                    Text("Go get your day.")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 8)
                }
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

#Preview {
    AlarmChallengeView(isPresented: .constant(true), isTestMode: true)
        .environmentObject(AlarmManager.shared)
}
