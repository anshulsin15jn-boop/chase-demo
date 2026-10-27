import SwiftUI

// Native vectors only: no reference pixels or external service integrations.
struct ZelleDemoGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let points: [(CGFloat, CGFloat)] = [(0.13,0.22),(0.87,0.22),(0.87,0.37),(0.40,0.70),(0.84,0.70),(0.84,0.86),(0.12,0.86),(0.12,0.71),(0.59,0.38),(0.13,0.38)]
        p.addLines(points.map { CGPoint(x: rect.minX + rect.width * $0.0, y: rect.minY + rect.height * $0.1) }); p.closeSubpath()
        p.addRect(CGRect(x: rect.minX + rect.width * 0.44, y: rect.minY + rect.height * 0.06, width: rect.width * 0.15, height: rect.height * 0.20))
        p.addRect(CGRect(x: rect.minX + rect.width * 0.40, y: rect.minY + rect.height * 0.82, width: rect.width * 0.15, height: rect.height * 0.18))
        return p
    }
}
struct ZelleDemoBadge: View {
    var body: some View {
        ZelleDemoGlyph().fill(Style.purple).padding(1)
            .background(.white, in: RoundedRectangle(cornerRadius: 2))
            .accessibilityHidden(true)
    }
}
struct SiriDemoOrb: View {
    var body: some View {
        GeometryReader { g in
            let s = min(g.size.width, g.size.height)
            ZStack {
                Circle().fill(AngularGradient(colors: [.cyan, Color(red: 0.0, green: 0.55, blue: 0.42), .pink, .purple, .blue, .cyan], center: .center, startAngle: .degrees(15), endAngle: .degrees(375)))
                Ellipse().fill(LinearGradient(colors: [.clear, .white.opacity(0.7), .cyan.opacity(0.2)], startPoint: .top, endPoint: .bottom)).frame(width: s * 0.9, height: s * 0.39).rotationEffect(.degrees(-33))
                Ellipse().stroke(LinearGradient(colors: [.white.opacity(0.1), .cyan.opacity(0.9), .white.opacity(0.7), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: s * 0.05).frame(width: s * 0.72, height: s * 0.90).rotationEffect(.degrees(31))
                Ellipse().stroke(.white.opacity(0.3), lineWidth: s * 0.03).frame(width: s * 0.93, height: s * 0.56).rotationEffect(.degrees(37))
                Circle().fill(RadialGradient(colors: [.white.opacity(0.98), .white.opacity(0.25), .clear], center: .center, startRadius: 0, endRadius: s * 0.34)).frame(width: s * 0.75, height: s * 0.75)
                Circle().fill(RadialGradient(colors: [.clear, .clear, .black.opacity(0.28)], center: .center, startRadius: 0, endRadius: s * 0.5))
            }.clipShape(Circle()).overlay(Circle().stroke(.black.opacity(0.12), lineWidth: 0.4))
        }.accessibilityHidden(true)
    }
}
struct SiriDemoButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                SiriDemoOrb().frame(width: 31, height: 31)
                Text("Add to Siri").font(.system(size: 14, weight: .semibold)).foregroundStyle(.black)
            }.padding(.horizontal, 20).frame(minHeight: 52).background(.white, in: RoundedRectangle(cornerRadius: 4))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(.systemGray2), lineWidth: 0.8)).contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityIdentifier("add-to-siri").accessibilityLabel("Add to Siri, local demonstration")
    }
}
