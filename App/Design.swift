import SwiftUI
import DemoCore

enum Style {
    static let background = Color(red: 0.958, green: 0.962, blue: 0.978)
    static let blue = Color(red: 0.0, green: 0.36, blue: 0.69)
    static let navy = Color(red: 0.015, green: 0.18, blue: 0.37)
    static let gray = Color(red: 0.36, green: 0.40, blue: 0.43)
    static let purple = Color(red: 0.40, green: 0.13, blue: 0.73)
    static let teal = Color(red: 0.14, green: 0.55, blue: 0.50)
    static let error = Color(red: 0.56, green: 0.15, blue: 0.34)
    static let gradient = LinearGradient(colors: [navy, Color(red: 0, green: 0.28, blue: 0.56)], startPoint: .leading, endPoint: .trailing)
    static let inset: CGFloat = 20
    static let radius: CGFloat = 13
}
struct Avatar: View {
    let recipient: Recipient
    var size: CGFloat = 48
    var body: some View {
        Group {
            if recipient.initial.isEmpty { Image(systemName: "person").font(.system(size: size * 0.45, weight: .light)) }
            else { Text(recipient.initial).font(.system(size: size * (recipient.initial.count > 1 ? 0.38 : 0.49), weight: .light)) }
        }.foregroundStyle(Color.black).frame(width: size, height: size).background(Color(.systemGray6), in: Circle())
            .overlay(alignment: .bottomTrailing) { if recipient.registered { ZelleDemoBadge().frame(width: size * 0.32, height: size * 0.32).offset(x: 2, y: 2) } }
            .accessibilityElement(children: .ignore).accessibilityIdentifier("recipient-avatar")
            .accessibilityLabel(recipient.registered ? "Recipient avatar, demo Zelle badge" : "Recipient avatar")
    }
}
struct PrimaryButton: View {
    let title: String
    var loading = false
    let action: () -> Void
    var body: some View { Button(action: action) { HStack { Spacer(); if loading { ProgressView().tint(.white) }; Text(title).font(.system(size: 16, weight: .medium)); Spacer() }.frame(minHeight: 44).background(Style.blue, in: RoundedRectangle(cornerRadius: 4)).foregroundStyle(.white) }.buttonStyle(.plain).disabled(loading) }
}
struct NavHeader: View {
    let title: String
    var back: (() -> Void)?
    var cancel: (() -> Void)?
    var body: some View {
        ZStack {
            Text(title).font(.system(size: 18, weight: .semibold)).foregroundStyle(Color.black).lineLimit(1).padding(.horizontal, 68)
            HStack { if let back { Button(action: back) { Image(systemName: "chevron.left").font(.system(size: 22, weight: .medium)).frame(width: 44, height: 48) }.accessibilityLabel("Back") }; Spacer(); if let cancel { Button("Cancel", action: cancel).font(.system(size: 16, weight: .medium)).padding(.trailing, 20) } }
        }.frame(height: 54).foregroundStyle(Style.blue).background(Style.background)
    }
}
struct Identity: View {
    let recipient: Recipient
    var centered = false
    var body: some View {
        VStack(alignment: centered ? .center : .leading, spacing: 7) {
            HStack(alignment: .center, spacing: 10) {
                Avatar(recipient: recipient, size: 50)
                VStack(alignment: .leading, spacing: 3) {
                    RecipientNameLines(recipient: recipient)
                    if recipient.registered { HStack(spacing: 7) { Image(systemName: "person").foregroundStyle(Style.blue); Text(recipient.metadata.accountType) }.font(.system(size: 10)).accessibilityIdentifier("recipient-account-type") }
                }
            }
            if recipient.registered {
                HStack(spacing: 4) { CalendarGlyph().stroke(Style.gray, lineWidth: 0.7).frame(width: 10, height: 11); Text("Zelle® ID active since \(recipient.metadata.activeSince)").fixedSize(horizontal: false, vertical: true) }
                    .font(.system(size: 10)).padding(.horizontal, 4).padding(.vertical, 2).background(Style.background).padding(.leading, centered ? 0 : 60)
                    .accessibilityIdentifier("recipient-active-since")
            }
        }.fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
    }
}
struct RecipientNameLines: View {
    let recipient: Recipient
    var confirmation = false
    var body: some View {
        VStack(alignment: confirmation ? .center : .leading, spacing: 3) {
            Text(RecipientName.display(recipient, uppercase: confirmation)).font(.system(size: confirmation ? 18 : 12))
                .accessibilityIdentifier("recipient-name")
            if let registration = RecipientName.registration(recipient, uppercase: confirmation) {
                Text(registration).font(.system(size: confirmation ? 11 : 10)).foregroundStyle(Style.gray).accessibilityIdentifier("recipient-registration")
            }
            if !recipient.subtitle.isEmpty { Text(recipient.subtitle).font(.system(size: confirmation ? 11 : 10)).foregroundStyle(Style.gray).accessibilityIdentifier("recipient-contact") }
        }.multilineTextAlignment(confirmation ? .center : .leading).fixedSize(horizontal: false, vertical: true)
    }
}
struct RecipientRow: View {
    let recipient: Recipient
    let action: () -> Void
    var body: some View {
        Button(action: action) { HStack(spacing: 14) { Avatar(recipient: recipient, size: 36); VStack(alignment: .leading, spacing: 5) { Text(recipient.displayName).font(.system(size: 16)).foregroundStyle(Color.black); if !recipient.subtitle.isEmpty { Text(recipient.subtitle).font(.system(size: 11)).foregroundStyle(Style.gray) } }; Spacer(minLength: 4); Image(systemName: "chevron.right").foregroundStyle(Style.gray) }.padding(.vertical, 12).frame(minHeight: 58).contentShape(Rectangle()) }.buttonStyle(.plain).accessibilityIdentifier("recipient-\(recipient.id)")
        Divider()
    }
}
struct DocumentListGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        p.addRect(CGRect(x: w * 0.13, y: h * 0.04, width: w * 0.74, height: h * 0.92))
        for y in [0.26, 0.45, 0.64, 0.81] {
            p.move(to: CGPoint(x: w * 0.29, y: h * y)); p.addLine(to: CGPoint(x: w * 0.35, y: h * y))
            p.move(to: CGPoint(x: w * 0.47, y: h * y)); p.addLine(to: CGPoint(x: w * 0.73, y: h * y))
        }
        return p
    }
}
struct CalendarGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        p.addRoundedRect(in: CGRect(x: w * 0.06, y: h * 0.18, width: w * 0.88, height: h * 0.77), cornerSize: CGSize(width: 0.7, height: 0.7))
        p.move(to: CGPoint(x: w * 0.07, y: h * 0.39)); p.addLine(to: CGPoint(x: w * 0.93, y: h * 0.39))
        for x in [0.27, 0.73] { p.move(to: CGPoint(x: w * x, y: 0)); p.addLine(to: CGPoint(x: w * x, y: h * 0.28)) }
        return p
    }
}
struct MenuRow: View {
    let title: String
    let icon: String
    let action: () -> Void
    var body: some View { Button(action: action) { HStack(spacing: 14) { Image(systemName: icon).font(.system(size: 23, weight: .light)).foregroundStyle(Style.gray).frame(width: 26); Text(title).font(.system(size: 14)).foregroundStyle(Color.black); Spacer(); Image(systemName: "chevron.right").font(.system(size: 14)).foregroundStyle(Style.gray) }.frame(minHeight: 66).contentShape(Rectangle()) }.buttonStyle(.plain); Divider() }
}
