import SwiftUI

@MainActor
enum Onboarding {
    private static let completedKey = "chopsticksAI.onboarding.completed"

    static var isCompleted: Bool {
        UserDefaults.standard.bool(forKey: completedKey)
    }

    static func presentIfNeeded(on presenter: OnboardingPresenter) {
        guard !isCompleted else { return }
        presenter.isPresented = true
    }

    static func markCompleted(on presenter: OnboardingPresenter) {
        UserDefaults.standard.set(true, forKey: completedKey)
        presenter.isPresented = false
    }
}

@MainActor
final class OnboardingPresenter: ObservableObject {
    static let shared = OnboardingPresenter()
    @Published var isPresented = false
}

struct OnboardingView: View {
    @ObservedObject var presenter: OnboardingPresenter
    @State private var page = 0

    private let pages: [(icon: String, title: String, body: String)] = [
        (
            "sparkles",
            "Welcome to cs.AI",
            "Free macOS AI assistant from Chopsticks HQ. Ask anything — no OpenRouter or OpenAI key on your side."
        ),
        (
            "chart.bar",
            "Allowance resets every 5 hours",
            "You get a free token allowance that resets on a rolling 5-hour window. Open Usage in the sidebar to see when it resets and redeem Fathom Pro keys for higher tiers."
        ),
        (
            "bubble.left.and.bubble.right",
            "Agents window + Browser",
            "Use the Agents chat for coding and files. The Browser rail opens pages inside the app. Live chat needs network; HQ product help can fall back to the offline knowledge base."
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("cs.AI")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Cursor.soft)
                Spacer()
                Text("\(page + 1) / \(pages.count)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Cursor.muted)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 12)

            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { idx, item in
                    VStack(spacing: 16) {
                        Image(systemName: item.icon)
                            .font(.system(size: 36, weight: .medium))
                            .foregroundStyle(Cursor.blue)
                            .padding(.top, 8)
                        Text(item.title)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Cursor.text)
                            .multilineTextAlignment(.center)
                        Text(item.body)
                            .font(.system(size: 14))
                            .foregroundStyle(Cursor.muted)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 360)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tag(idx)
                }
            }
            .tabViewStyle(.automatic)

            HStack(spacing: 10) {
                if page > 0 {
                    Button("Back") { page -= 1 }
                        .buttonStyle(OnboardingSecondaryButtonStyle())
                }
                Spacer()
                if page < pages.count - 1 {
                    Button("Next") { page += 1 }
                        .buttonStyle(OnboardingPrimaryButtonStyle())
                } else {
                    Button("Get started") {
                        Onboarding.markCompleted(on: presenter)
                    }
                    .buttonStyle(OnboardingPrimaryButtonStyle())
                }
            }
            .padding(24)
        }
        .frame(width: 440, height: 420)
        .background(Cursor.bg)
    }
}

private struct OnboardingPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Cursor.accentFg)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(Cursor.accent.opacity(configuration.isPressed ? 0.85 : 1))
            .clipShape(Capsule())
    }
}

private struct OnboardingSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Cursor.soft)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Cursor.hover.opacity(configuration.isPressed ? 0.9 : 1))
            .clipShape(Capsule())
    }
}
