import SwiftUI

struct DesignSystem {
    static let primaryRed = Color(red: 1.0, green: 0.23, blue: 0.19)
    static let darkRed = Color(red: 0.8, green: 0.1, blue: 0.1)
    
    struct GlassButton: ViewModifier {
        let isDestructive: Bool
        
        func body(content: Content) -> some View {
            content
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                        
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isDestructive ? Color.red.opacity(0.1) : Color.black.opacity(0.05))
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        }
    }
    
    struct GlassCard: ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding()
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                        
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.05))
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 8)
        }
    }
    
    struct GlassHeader: ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding()
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                        
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.1))
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

extension View {
    func glassButton(isDestructive: Bool = false) -> some View {
        modifier(DesignSystem.GlassButton(isDestructive: isDestructive))
    }
    
    func glassCard() -> some View {
        modifier(DesignSystem.GlassCard())
    }
    
    func glassHeader() -> some View {
        modifier(DesignSystem.GlassHeader())
    }
}
