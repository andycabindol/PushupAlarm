import SwiftUI

struct AlarmChallengeView: View {
    @Binding var isPresented: Bool
    let isTestMode: Bool
    @StateObject private var pushupDetector = PushupDetector()
    @EnvironmentObject var alarmManager: AlarmManager
    @State private var showSuccess = false
    
    private let requiredPushups = 10
    
    var body: some View {
        ZStack {
            CameraView(pushupDetector: pushupDetector)
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Spacer()
                    
                    if isTestMode {
                        Button(action: {
                            isPresented = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 5)
                        }
                        .padding()
                    }
                }
                
                Spacer()
                
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(pushupDetector.bodyDetected ? Color.green.opacity(0.3) : Color.red.opacity(0.3))
                            .frame(width: 180, height: 180)
                        
                        VStack(spacing: 5) {
                            Text("\(pushupDetector.pushupCount)")
                                .font(.system(size: 80, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("/ \(requiredPushups)")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .shadow(color: .black.opacity(0.5), radius: 10)
                    
                    Text(pushupDetector.feedback)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black.opacity(0.6))
                        )
                        .shadow(color: .black.opacity(0.3), radius: 5)
                    
                    if pushupDetector.bodyDetected {
                        HStack(spacing: 15) {
                            Circle()
                                .fill(pushupDetector.currentPhase == .up ? Color.green : Color.gray.opacity(0.5))
                                .frame(width: 20, height: 20)
                            
                            Text("UP")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Rectangle()
                                .fill(Color.white.opacity(0.5))
                                .frame(width: 2, height: 20)
                            
                            Circle()
                                .fill(pushupDetector.currentPhase == .down ? Color.orange : Color.gray.opacity(0.5))
                                .frame(width: 20, height: 20)
                            
                            Text("DOWN")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.black.opacity(0.5))
                        )
                    }
                }
                .padding(.bottom, 60)
            }
            
            if showSuccess {
                ZStack {
                    Color.black.opacity(0.8)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 30) {
                        Text("🎉")
                            .font(.system(size: 100))
                        
                        Text("Alarm Dismissed!")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Great job on those pushups!")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .transition(.opacity)
            }
        }
        .onChange(of: pushupDetector.pushupCount) { oldValue, newValue in
            if newValue >= requiredPushups && !showSuccess {
                completeChallenge()
            }
        }
        .onAppear {
            if !isTestMode {
                alarmManager.playAlarmSound()
            }
        }
    }
    
    private func completeChallenge() {
        showSuccess = true
        
        if !isTestMode {
            alarmManager.alarmCompleted()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                isPresented = false
            }
        }
    }
}

#Preview {
    AlarmChallengeView(isPresented: .constant(true), isTestMode: true)
        .environmentObject(AlarmManager.shared)
}
