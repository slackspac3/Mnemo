import SwiftUI
import SwiftData
import MnemoUI
import MnemoCore
import MnemoMemory

/// Dedicated Threads tab. Confirmed threads as cards + pending proposals banner.
struct ThreadsView: View {

    @Query(sort: \MemoryThread.startDate, order: .reverse) private var threads: [MemoryThread]

    private var confirmedThreads: [MemoryThread] {
        threads.filter(\.isConfirmed)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colours.background.ignoresSafeArea()

                if confirmedThreads.isEmpty {
                    EmptyThreadsView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: DS.Spacing.sm) {
                            ForEach(confirmedThreads, id: \.id) { thread in
                                ThreadCard(thread: thread)
                            }
                        }
                        .padding(.horizontal, DS.Spacing.md)
                        .padding(.top, DS.Spacing.sm)
                        .padding(.bottom, DS.Spacing.xxxl)
                    }
                }
            }
            .navigationTitle("Threads")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ThreadCard: View {
    let thread: MemoryThread

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: "link")
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.Colours.accent)
                Text(thread.name)
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.Colours.textPrimary)
                Spacer()
            }

            if !thread.threadDescription.isEmpty {
                Text(thread.threadDescription)
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colours.textSecondary)
                    .lineLimit(2)
            }

            HStack(spacing: DS.Spacing.xs) {
                Text(thread.startDate.formatted(.dateTime.day().month().year()))
                    .font(DS.Typography.caption1)
                    .foregroundStyle(DS.Colours.textTertiary)

                Image(systemName: "arrow.right")
                    .font(DS.Typography.caption1)
                    .foregroundStyle(DS.Colours.textTertiary)

                if let endDate = thread.endDate {
                    Text(endDate.formatted(.dateTime.day().month().year()))
                        .font(DS.Typography.caption1)
                        .foregroundStyle(DS.Colours.textTertiary)
                } else {
                    Text("ongoing")
                        .font(DS.Typography.caption1)
                        .foregroundStyle(DS.Colours.textTertiary)
                }
            }
        }
        .padding(DS.Spacing.md)
        .background(DS.Colours.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.large))
        .shadow(
            color: DS.Shadows.subtle.color,
            radius: DS.Shadows.subtle.radius,
            x: DS.Shadows.subtle.x,
            y: DS.Shadows.subtle.y
        )
    }
}

struct EmptyThreadsView: View {
    var body: some View {
        VStack(spacing: DS.Spacing.lg) {
            Image(systemName: "link")
                .font(DS.Typography.largeTitle)
                .foregroundStyle(DS.Colours.textTertiary)
            Text("No threads yet")
                .font(DS.Typography.title3)
                .foregroundStyle(DS.Colours.textPrimary)
            Text("Automatic thread suggestions are not active in this build. Confirmed threads will appear here when that flow is ready.")
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colours.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Spacing.xl)
        }
        .padding(DS.Spacing.xl)
    }
}
