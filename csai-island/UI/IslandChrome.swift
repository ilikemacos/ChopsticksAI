import SwiftUI

struct IslandChrome<Content: View>: View {
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var mgr = IslandStateManager.shared
    var content: () -> Content

    var body: some View {
        let r = settings.cornerRadius
        content()
            .padding(.horizontal, mgr.phase == .idle ? 6 : 12)
            .padding(.vertical, mgr.phase == .idle ? 2 : 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(chrome)
            .clipShape(RoundedRectangle(cornerRadius: r, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.6)
            )
            .shadow(color: .black.opacity(0.45), radius: mgr.phase == .idle ? 4 : 18, y: 8)
            .opacity(settings.opacity)
            .environment(\.colorScheme, settings.appearance == .light ? .light : .dark)
    }

    @ViewBuilder
    private var chrome: some View {
        ZStack {
            RoundedRectangle(cornerRadius: settings.cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(settings.blurIntensity)
            RoundedRectangle(cornerRadius: settings.cornerRadius, style: .continuous)
                .fill(Color.black.opacity(settings.appearance == .light ? 0.18 : 0.72))
        }
    }
}
