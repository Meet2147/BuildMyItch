//  TaskRow.swift
//  The most-seen component in the app, so it gets the most attention.

import SwiftUI
import SillCore

public struct TaskRow: View {

    let todo: Todo
    let onComplete: () -> Void
    let onSetType: (TaskType) -> Void

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        todo: Todo,
        onComplete: @escaping () -> Void,
        onSetType: @escaping (TaskType) -> Void = { _ in }
    ) {
        self.todo = todo
        self.onComplete = onComplete
        self.onSetType = onSetType
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            completionCircle

            VStack(alignment: .leading, spacing: 3) {
                Text(todo.title)
                    .font(.sillBody())
                    // Done text sets in *weight*, not a strikethrough. A struck
                    // line is still shouting; a settled one is finished.
                    .fontWeight(todo.isDone ? .medium : .regular)
                    .foregroundStyle(todo.isDone ? Stone.inkFaint(scheme) : Stone.ink(scheme))
                    .opacity(1 - todo.quietness() * 0.35)

                if let note = todo.note, !note.isEmpty {
                    Text(note)
                        .font(.sillDetail())
                        .foregroundStyle(Stone.inkFaint(scheme))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            Text(metadata)
                .font(.sillNumeric())
                .foregroundStyle(Stone.inkFaint(scheme))
                .fontWeight(todo.estimateWasStated ? .medium : .regular)
                .opacity(todo.estimateWasStated ? 1 : 0.72)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .softSurface(.lifted, radius: 15)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(todo.title)
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(todo.isDone ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint(todo.isDone ? "Double tap to reopen" : "Double tap to complete")
        .accessibilityAction { complete() }
        .onTapGesture { complete() }
        // A small two-part click-then-done, rather than one generic buzz.
        .sensoryFeedback(trigger: todo.isDone) { _, done in
            done ? .impact(flexibility: .rigid) : nil
        }
        .sensoryFeedback(trigger: todo.isDone) { _, done in
            done ? .success : nil
        }
        .contextMenu {
            Button(todo.isDone ? "Reopen" : "Mark done", systemImage: todo.isDone ? "arrow.uturn.backward" : "checkmark") {
                complete()
            }
            Divider()
            Menu("Type") {
                ForEach(TaskType.allCases, id: \.self) { type in
                    Button(type.title, systemImage: type.symbolName) { onSetType(type) }
                }
            }
        }
    }

    private var completionCircle: some View {
        Button(action: complete) {
            ZStack {
                Circle()
                    .fill(todo.isDone ? Stone.accent(scheme) : Stone.ground(scheme))
                    .frame(width: 19, height: 19)
                    .softSurface(todo.isDone ? .flush : .carved, radius: 10)

                if todo.isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Stone.raised(scheme))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityHidden(true)      // the whole row is the control
    }

    private var metadata: String {
        if todo.isDone { return "" }
        if todo.type == .errand || todo.type == .idle { return todo.type.title.lowercased() }
        return Durations.short(todo.estimateMinutes)
    }

    private var accessibilityValue: String {
        var parts = [todo.type.title]
        if !todo.isDone { parts.append(Durations.short(todo.estimateMinutes)) }
        if todo.isDone { parts.append("done") }
        return parts.joined(separator: ", ")
    }

    private func complete() {
        // The row doesn't animate itself out — it changes state, and the list
        // slides it down into the done well. Motion follows the data.
        withAnimation(reduceMotion ? nil : Motion.settle) {
            onComplete()
        }
    }
}
