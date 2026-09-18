import SwiftUI

struct MarkdownBubble: View {
    let text: String

    var body: some View {
        Text(attributed)
            .font(.system(size: 12.5, weight: .regular, design: .rounded))
            .foregroundStyle(.white.opacity(0.92))
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var attributed: AttributedString {
        (try? AttributedString(
            markdown: text,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        )) ?? AttributedString(text)
    }
}

struct CodeishModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 11.5, weight: .medium, design: .monospaced))
            .padding(8)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
