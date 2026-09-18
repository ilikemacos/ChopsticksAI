import SwiftUI

struct IslandSpring: ViewModifier {
    @ObservedObject var settings = AppSettings.shared

    func body(content: Content) -> some View {
        content.animation(
            .spring(response: settings.springResponse, dampingFraction: settings.springDamping),
            value: IslandStateManager.shared.phase
        )
    }
}

extension View {
    func islandSpring() -> some View { modifier(IslandSpring()) }
}
