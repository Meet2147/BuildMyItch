//  RootView.swift
//
//  Three platforms, three different shapes. A universal SwiftUI blob that's
//  identical everywhere is its own kind of vibe-coded — the whole reason to be
//  Apple-only is that we get to build each one properly.

import SwiftUI

public struct RootView: View {

    @Environment(\.colorScheme) private var scheme
    @State private var selection: Destination = .today

    public enum Destination: String, CaseIterable, Identifiable {
        case today, pile
        public var id: String { rawValue }
        var title: String { self == .today ? "Today" : "The pile" }
        var symbol: String { self == .today ? "sun.horizon" : "tray.full" }
    }

    public init() {}

    public var body: some View {
        #if os(macOS)
        NavigationSplitView {
            List(Destination.allCases, selection: sidebarSelection) { destination in
                Label(destination.title, systemImage: destination.symbol).tag(destination)
            }
            .navigationSplitViewColumnWidth(min: 170, ideal: 190, max: 240)
            .scrollContentBackground(.hidden)
            .background(Stone.ground(scheme))
        } detail: {
            detail
        }
        .tint(Stone.accent(scheme))
        #else
        TabView(selection: $selection) {
            ForEach(Destination.allCases) { destination in
                content(for: destination)
                    .tabItem { Label(destination.title, systemImage: destination.symbol) }
                    .tag(destination)
            }
        }
        .tint(Stone.accent(scheme))
        #endif
    }

    /// The sidebar hands back an optional; a nil selection should leave the
    /// detail where it was rather than blanking the window.
    private var sidebarSelection: Binding<Destination?> {
        Binding(get: { selection }, set: { if let new = $0 { selection = new } })
    }

    @ViewBuilder private var detail: some View {
        content(for: selection)
    }

    @ViewBuilder
    private func content(for destination: Destination) -> some View {
        switch destination {
        case .today: TodayView()
        case .pile:  PileView()
        }
    }
}
