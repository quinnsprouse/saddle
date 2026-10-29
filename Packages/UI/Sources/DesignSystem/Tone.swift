public import SwiftUI

public enum Tone: Sendable {
    case calm
    case caution
    case alert

    public var color: Color {
        switch self {
        case .calm:
            Palette.success
        case .caution:
            Palette.warning
        case .alert:
            Palette.critical
        }
    }
}
