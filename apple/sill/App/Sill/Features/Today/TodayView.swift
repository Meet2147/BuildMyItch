//  TodayView.swift
//
//  Today is not a view of the app. It is the app. Everything else takes a
//  deliberate act to reach.

import SwiftUI
import SwiftData
import SillCore

public struct TodayView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Query(sort: \Todo.createdAt, order: .forward) private var allTodos: [Todo]

    @State private var model = TodayModel()
    @State private var captureText = ""

    private var store: TodoStore { TodoStore(context: context) }

    public init() {}

    public var body: some View {
        ZStack {
            Stone.ground(scheme).ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        let sections = model.sections(from: allTodos)
                        if sections.isEmpty {
                            emptyState
                        } else {
                            ForEach(sections) { section in
                                bandSection(section)
                            }
                        }
                        doneWell
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.interactively)

                CaptureField(text: $captureText) { text in
                    _ = store.capture(text)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
        }
        .animation(reduceMotion ? nil : Motion.settle, value: allTodos.count)
    }

    // MARK: - Pieces

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(model.subtitle(from: allTodos))
                .bandLabel()
            Text("Today")
                .font(.sillTitle())
                .foregroundStyle(Stone.ink(scheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func bandSection(_ section: TodaySection) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(section.band.title)
                .bandLabel()
                .padding(.leading, 2)

            ForEach(section.todos) { todo in
                TaskRow(todo: todo) {
                    store.complete(todo)
                } onSetType: { type in
                    store.setType(type, on: todo)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(model.emptyLine(from: allTodos))
                .font(.sillHeading())
                .foregroundStyle(Stone.inkSoft(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 44)
    }

    /// Completed work slides down into a well rather than vanishing, so you can
    /// watch the day accumulate. The count is the entire reward mechanism —
    /// no streaks, no confetti, nothing to keep up.
    @ViewBuilder
    private var doneWell: some View {
        let done = model.completedToday(from: allTodos)
        if !done.isEmpty {
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Text("Done today").bandLabel()
                    Spacer()
                    Text("\(done.count)")
                        .font(.sillNumeric())
                        .foregroundStyle(Stone.inkFaint(scheme))
                }
                ForEach(done.prefix(4)) { todo in
                    TaskRow(todo: todo) { store.uncomplete(todo) }
                }
                if done.count > 4 {
                    Text("and \(done.count - 4) more")
                        .font(.sillDetail())
                        .foregroundStyle(Stone.inkFaint(scheme))
                        .padding(.leading, 2)
                }
            }
            .padding(14)
            .softSurface(.carved, radius: 18)
        }
    }
}
