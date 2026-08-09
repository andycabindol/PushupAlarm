import SwiftUI

struct OnboardingTestView: View {
    @Binding var isPresented: Bool
    let pushupCount: Int
    let onComplete: () -> Void
    
    @StateObject private var pushupDetector = PushupDetector()
    @State private var showSuccess = false
    
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
                
                Spacer()
                
                VStack(spacing: 20) {
                    Text("\(pushupDetector.pushupCount)")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 10)
                    
                    Text("/ \(pushupCount)")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.5), radius: 5)
                    
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
                .padding(.bottom, 60)
            }
            
            if showSuccess {
                SuccessOverlay(
                    pushupCount: pushupCount,
                    onDismiss: {
                        onComplete()
                        isPresented = false
                    }
                )
            }
        }
        .onChange(of: pushupDetector.pushupCount) { oldValue, newValue in
            if newValue >= pushupCount && !showSuccess {
                showSuccess = true
                generateHaptic(.success)
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

struct SuccessOverlay: View {
    let pushupCount: Int
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(DesignSystem.primaryRed)
                
                Text("You're all set!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                Text("\(pushupCount) push-up\(pushupCount == 1 ? "" : "s") complete")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    opacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onDismiss()
                }
            }
        }
    }
}

#Preview {
    OnboardingTestView(
        isPresented: .constant(true),
        pushupCount: 5,
        onComplete: {}
    )
}
