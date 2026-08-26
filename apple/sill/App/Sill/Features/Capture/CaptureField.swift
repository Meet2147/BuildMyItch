//  CaptureField.swift
//
//  The most-used surface in the app, so it's the most designed one.
//  It never scrolls away, it never asks you to choose a project, and it shows
//  you what it made of your sentence *before* you commit it.

import SwiftUI
import SillCore

public struct CaptureField: View {

    @Binding var text: String
    let onCommit: (String) -> Void

    @Environment(\.colorScheme) private var scheme
    @FocusState private var focused: Bool
    @State private var preview: [ParsedTask] = []

    public init(text: Binding<String>, onCommit: @escaping (String) -> Void) {
        self._text = text
        self.onCommit = onCommit
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            if !preview.isEmpty {
                ParsePreview(tasks: preview)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            HStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Stone.inkFaint(scheme))

                TextField("Add anything…", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.sillBody())
                    .foregroundStyle(Stone.ink(scheme))
                    .lineLimit(1...4)
                    .focused($focused)
                    .submitLabel(.done)
                    .onSubmit(commit)
                    #if os(iOS)
                    .autocorrectionDisabled(false)
                    .textInputAutocapitalization(.sentences)
                    #endif

                if !text.isEmpty {
                    Button(action: commit) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Stone.raised(scheme))
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(Stone.accent(scheme)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add")
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 13)
            .softSurface(.carved, radius: 16)
        }
        .animation(Motion.snap, value: preview.count)
        // Debounced so the chips don't flicker on every keystroke. 300ms is
        // long enough to stop the strobing and short enough to feel live.
        .task(id: text) {
            guard !text.trimmingCharacters(in: .whitespaces).isEmpty else {
                preview = []
                return
            }
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            preview = CaptureParser(now: .now).parse(text)
        }
        #if os(macOS)
        .onExitCommand { text = ""; focused = false }
        #endif
    }

    private func commit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onCommit(trimmed)
        text = ""
        preview = []
    }
}

/// What the parser made of the sentence, as chips. Every one of them is a
/// suggestion — nothing here was silently assigned, and a wrong guess costs
/// exactly one tap to fix once the task exists.
struct ParsePreview: View {

    let tasks: [ParsedTask]
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                ForEach(Array(tasks.enumerated()), id: \.offset) { _, task in
                    chip(for: task)
                }
            }
            .padding(.horizontal, 2)
        }
        .frame(height: 30)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(summary)
    }

    private func chip(for task: ParsedTask) -> some View {
        HStack(spacing: 6) {
            Image(systemName: task.type.symbolName)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(task.typeWasRecognised ? Stone.accentInk(scheme) : Stone.inkFaint(scheme))
            Text(chipText(for: task))
                .font(.sillDetail())
                .foregroundStyle(Stone.inkSoft(scheme))
                .lineLimit(1)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .softSurface(.lifted, radius: 999)
    }

    private func chipText(for task: ParsedTask) -> String {
        var parts = [task.title]
        if let day = task.day { parts.append(day.formatted(.dateTime.weekday(.abbreviated).day())) }
        parts.append(Durations.short(task.estimateMinutes))
        return parts.joined(separator: " · ")
    }

    private var summary: String {
        tasks.count == 1
            ? "Will add: \(tasks[0].title)"
            : "Will add \(tasks.count) tasks: " + tasks.map(\.title).joined(separator: ", ")
    }
}
