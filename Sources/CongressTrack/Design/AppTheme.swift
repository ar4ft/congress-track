import SwiftUI

/// Research-console colors. Opaque surfaces also respect Reduce Transparency.
enum AppTheme {
    static let spacing: CGFloat = 28
    static let cornerRadius: CGFloat = 10
    static let accent = adaptive(0xA35A16, dark: 0xEDAD58)
    static let onAccent = adaptive(0xFFFAF6, dark: 0x241A0E)
    static let ink = adaptive(0x22272E, dark: 0xEDF0F5)
    static let secondaryInk = adaptive(0x596370, dark: 0xB4BDC9)
    static let benchmark = secondaryInk
    static let surface = adaptive(0xFFFFFF, dark: 0x21262D)
    static let canvas = adaptive(0xF7F8FA, dark: 0x181C21)
    static let rule = adaptive(0xDBE0E6, dark: 0x3B424C)
    static let selection = adaptive(0xFFF1DF, dark: 0x3A3022)
    static let sidebar = adaptive(0x22272E, dark: 0x13171C)
    static let sidebarInk = Color(red: 0.933, green: 0.945, blue: 0.961)
    static let sidebarSecondary = Color(red: 0.702, green: 0.745, blue: 0.792)
    static let sidebarAccent = Color(red: 0.929, green: 0.678, blue: 0.345)
    static let sidebarSelection = Color(red: 0.271, green: 0.208, blue: 0.141)
    static let screenTitle = Font.system(.largeTitle, design: .default, weight: .bold).width(.condensed)
    static let sectionTitle = Font.system(.title2, design: .default, weight: .bold)

    private static func adaptive(_ light: UInt32, dark: UInt32) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let value = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
            return NSColor(srgbRed: Double((value >> 16) & 0xff) / 255,
                           green: Double((value >> 8) & 0xff) / 255,
                           blue: Double(value & 0xff) / 255, alpha: 1)
        })
    }
}
