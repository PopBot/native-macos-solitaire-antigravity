import SwiftUI

public struct DropTargetPreferenceData: Equatable, Sendable {
    public let location: CardLocation
    public let frame: CGRect
}

public struct DropTargetPreferenceKey: PreferenceKey {
    public static let defaultValue: [DropTargetPreferenceData] = []

    public static func reduce(value: inout [DropTargetPreferenceData], nextValue: () -> [DropTargetPreferenceData]) {
        value.append(contentsOf: nextValue())
    }
}

public struct DropTargetModifier: ViewModifier {
    public let location: CardLocation
    public let coordinateSpaceName: String

    public func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(
                            key: DropTargetPreferenceKey.self,
                            value: [
                                DropTargetPreferenceData(
                                    location: location,
                                    frame: proxy.frame(in: .named(coordinateSpaceName))
                                )
                            ]
                        )
                }
            )
    }
}

extension View {
    public func dropTargetLocation(_ location: CardLocation, in coordinateSpaceName: String = "GameBoard") -> some View {
        self.modifier(DropTargetModifier(location: location, coordinateSpaceName: coordinateSpaceName))
    }
}
