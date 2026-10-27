import SwiftUI
import DemoCore

enum Style {
    static let background = Color(red: 0.958, green: 0.962, blue: 0.978)
    static let blue = Color(red: 0.0, green: 0.36, blue: 0.69)
    static let navy = Color(red: 0.015, green: 0.18, blue: 0.37)
    static let gray = Color(red: 0.36, green: 0.40, blue: 0.43)
    static let purple = Color(red: 0.40, green: 0.13, blue: 0.73)
    static let teal = Color(red: 0.14, green: 0.55, blue: 0.50)
    static let gradient = LinearGradient(colors: [navy, Color(red: 0, green: 0.28, blue: 0.56)], startPoint: .leading, endPoint: .trailing)
    static let inset: CGFloat = 20
    static let radius: CGFloat = 13
}
struct Avatar: View {
    let recipient: Recipient
    var size: CGFloat = 48
    var body: some View {
        Text(recipient.initial).font(.system(size: size * 0.49, weight: .light)).frame(width: size, height: size).background(Color(.systemGray6), in: Circle())
            .overlay(alignment: .bottomTrailing) { Text("Æµ").font(.system(size: size * 0.30, weight: .heavy)).foregroundStyle(Style.purple).offset(x: 2, y: 2) }.accessibilityHidden(true)
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
        }.frame(height: 64).foregroundStyle(Style.blue).background(Style.background)
    }
}
struct Identity: View {
    let recipient: Recipient
    var centered = false
    var body: some View {
        VStack(alignment: centered ? .center : .leading, spacing: 7) {
            HStack(alignment: .center, spacing: 12) { Avatar(recipient: recipient, size: 52); VStack(alignment: .leading, spacing: 3) { Text(recipient.name).font(.system(size: 14)); Text("Registered as \(recipient.name)").font(.system(size: 11)).foregroundStyle(Style.gray); Text(recipient.contact).font(.system(size: 11)).foregroundStyle(Style.gray); Label("Personal account", systemImage: "person").font(.system(size: 11)) } }
            Label("ZelleÂ® ID active since Feb 2025", systemImage: "calendar").font(.system(size: 11)).padding(.horizontal, 4).padding(.vertical, 2).background(Style.background)
        }.frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
    }
}
struct RecipientRow: View {
    let recipient: Recipient
    let action: () -> Void
    var body: some View {
        Button(action: action) { HStack(spacing: 14) { Avatar(recipient: recipient, size: 36); VStack(alignment: .leading, spacing: 5) { Text(recipient.name).font(.system(size: 16)).foregroundStyle(Color.black); Text(recipient.contact).font(.system(size: 11)).foregroundStyle(Style.gray) }; Spacer(minLength: 4); Image(systemName: "chevron.right").foregroundStyle(Style.gray) }.padding(.vertical, 12).frame(minHeight: 58).contentShape(Rectangle()) }.buttonStyle(.plain).accessibilityIdentifier("recipient-\(recipient.id)")
        Divider()
    }
}
struct MenuRow: View {
    let title: String
    let icon: String
    let action: () -> Void
    var body: some View { Button(action: action) { HStack(spacing: 14) { Image(systemName: icon).font(.system(size: 23, weight: .light)).foregroundStyle(Style.gray).frame(width: 26); Text(title).font(.system(size: 14)).foregroundStyle(Color.black); Spacer(); Image(systemName: "chevron.right").font(.system(size: 14)).foregroundStyle(Style.gray) }.frame(minHeight: 66).contentShape(Rectangle()) }.buttonStyle(.plain); Divider() }
}
