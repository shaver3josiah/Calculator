import SwiftUI

enum BloomFontRole {
    static let bodyFamily = "Quicksand"
    static let numberFamily = "Playfair Display"
    static let scriptFamily = "Great Vibes"
}

func bloomBody(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    .custom(BloomFontRole.bodyFamily, size: size).weight(weight)
}

func bloomNumber(_ size: CGFloat, weight: Font.Weight = .medium, italic: Bool = false) -> Font {
    if italic {
        return .custom(BloomFontRole.numberFamily, size: size).italic().weight(weight)
    }
    return .custom(BloomFontRole.numberFamily, size: size).weight(weight)
}

func bloomScript(_ size: CGFloat) -> Font {
    .custom(BloomFontRole.scriptFamily, size: size)
}
