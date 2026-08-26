//  PileView.swift
//
//  Not "Inbox" — that implies obligation. Not "All Tasks" — that implies a
//  database. It's the pile: one flat list, newest first, no folders.
//
//  Old items lose contrast on a curve rather than turning red. At thirty days
//  Sill asks once, quietly, whether the thing is still real. That question is
//  the anti-guilt mechanism, and it's the reason the backlog never becomes a
//  monument to everything you haven't done.

import SwiftUI
import SwiftData
import SillCore

public struct PileView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme

    @Query(sort: \Todo.createdAt, order: .reverse) private var allTodos: [Todo]
    @State private var search = ""

    private var store: TodoStore { TodoStore(context: context) }

    public init() {}

    private var open: [Todo] {
        allTodos.filter { todo in
            guard todo.isOpen else { return false }
            guard !search.isEmpty else { return true }
            return todo.title.localizedCaseInsensitiveContains(search)
        }
    }

    private var stale: [Todo] {
        allTodos.filter { $0.shouldAskStillReal() }
    }

    public var body: some View {
        ZStack {
            Stone.ground(scheme).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("\(open.count) open").bandLabel()
                        Text("The pile")
                            .font(.sillTitle())
                            .foregroundStyle(Stone.ink(scheme))
                    }

                    searchField

                    if let ask = stale.first {
                        stillRealCard(ask)
                    }

                    if open.isEmpty {
                        Text(search.isEmpty ? "Nothing waiting." : "Nothing matches “\(search)”.")
                            .font(.sillHeading())
                            .foregroundStyle(Stone.inkSoft(scheme))
                            .padding(.vertical, 40)
                    } else {
                        ForEach(open) { todo in
                            TaskRow(todo: todo) {
                                store.complete(todo)
                            } onSetType: { type in
                                store.setType(type, on: todo)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
    }

    /// Not the system search bar: it needs a navigation container we don't
    /// want, and a translucent chrome bar on this ground looks borrowed.
    private var searchField: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Stone.inkFaint(scheme))
            TextField("Search", text: $search)
                .textFieldStyle(.plain)
                .font(.sillBody())
                .foregroundStyle(Stone.ink(scheme))
            if !search.isEmpty {
                Button {
                    search = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Stone.inkFaint(scheme))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .softSurface(.carved, radius: 14)
    }

    /// Asked once, on a quiet card, and never again. Letting go is not
    /// deleting — it goes somewhere you never have to look at.
    private func stillRealCard(_ todo: Todo) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("\(todo.daysOld()) days ago").bandLabel()
            Text(todo.title)
                .font(.sillHeading())
                .foregroundStyle(Stone.ink(scheme))
                .fixedSize(horizontal: false, vertical: true)
            Text("Still real?")
                .font(.sillBody())
                .foregroundStyle(Stone.inkSoft(scheme))

            HStack(spacing: 10) {
                Button("Keep") { store.keep(todo) }
                    .buttonStyle(SoftButtonStyle(resting: .lifted, radius: 13))
                Button("Let go") { store.letGo(todo) }
                    .buttonStyle(SoftButtonStyle(resting: .lifted, radius: 13))
                    .foregroundStyle(Stone.inkSoft(scheme))
            }
            .font(.sillBody())
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .softSurface(.raised, radius: 20)
    }
}
