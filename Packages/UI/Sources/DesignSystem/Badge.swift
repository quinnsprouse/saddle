public import SwiftUI

public struct Badge: View {
    private let title: LocalizedStringResource
    private let tone: Tone
    @ScaledMetric(relativeTo: .caption) private var dotSize = Spacing.small

    public init(_ title: LocalizedStringResource, tone: Tone) {
        self.title = title
        self.tone = tone
    }

    public var body: some View {
        HStack(spacing: Spacing.extraSmall) {
            Circle()
                .fill(tone.color)
                .frame(width: dotSize, height: dotSize)
                .accessibilityHidden(true)
            Text(title)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.primary)
        .padding(.horizontal, Spacing.small)
        .padding(.vertical, Spacing.extraSmall)
        .background(.fill.tertiary, in: .capsule)
    }
}
