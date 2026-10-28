public import SwiftUI

public enum Tone: Sendable {
    case calm
    case caution
    case alert

    public var color: Color {
        switch self {
        case .calm:
            .green
        case .caution:
            .orange
        case .alert:
            .red
        }
    }
}
