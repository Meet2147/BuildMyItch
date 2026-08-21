import SwiftUI

struct PlanView: View {
    @Environment(ScanStore.self) private var store

    private var routine: [Exercise] {
        GuidanceEngine.dailyRoutine(for: store.latestScan?.metrics, profile: store.profile)
    }

    private var otherExercises: [Exercise] {
        let routineIDs = Set(routine.map(\.id))
        return ExerciseCatalog.all.filter { !routineIDs.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        streakHeader

                        if store.latestScan == nil {
                            Text("This routine is tuned to your quiz answers — scan your face and it also adapts to your weakest metrics.")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                                .padding(.horizontal)
                        }

                        section("Today's routine", exercises: routine, showCheck: true)
                        section("Exercise library", exercises: otherExercises, showCheck: false)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Train")
            .toolbarBackground(Theme.background, for: .navigationBar)
        }
    }

    private var streakHeader: some View {
        let done = routine.filter { store.isCompleted($0.id) }.count
        return HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(store.streak) day streak")
                    .font(.title3.bold())
                Text("\(done)/\(routine.count) exercises done today")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Image(systemName: "flame.fill")
                .font(.system(size: 34))
                .foregroundStyle(store.streak > 0 ? Theme.warn : Theme.textSecondary)
        }
        .card()
        .padding(.horizontal)
    }

    private func section(_ title: String, exercises: [Exercise], showCheck: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            ForEach(exercises) { exercise in
                NavigationLink {
                    ExerciseDetailView(exercise: exercise)
                } label: {
                    ExerciseRow(
                        exercise: exercise,
                        completed: showCheck && store.isCompleted(exercise.id),
                        onToggle: showCheck ? { store.toggleCompletion(exercise.id) } : nil
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            }
        }
    }
}

struct ExerciseRow: View {
    let exercise: Exercise
    let completed: Bool
    let onToggle: (() -> Void)?

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: exercise.icon)
                .font(.title3)
                .foregroundStyle(Theme.accent)
                .frame(width: 40, height: 40)
                .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text(exercise.name)
                    .font(.subheadline.bold())
                    .strikethrough(completed, color: Theme.textSecondary)
                Text(exercise.sets)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            if let onToggle {
                Button(action: onToggle) {
                    Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(completed ? Theme.good : Theme.textSecondary)
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .card()
        .opacity(completed ? 0.65 : 1)
    }
}

#Preview {
    PlanView()
        .environment(ScanStore())
}
