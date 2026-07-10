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
                DS.Colours.backgroundGrouped.ignoresSafeArea()

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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: DS.Spacing.xs) {
                    dateRangeStart
                    Image(systemName: "arrow.right")
                        .accessibilityHidden(true)
                    dateRangeEnd
                }

                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    dateRangeStart
                    dateRangeEnd
                }
            }
            .font(DS.Typography.caption1)
            .foregroundStyle(DS.Colours.textTertiary)
        }
        .padding(DS.Spacing.md)
        .background(DS.Colours.memoryCardSurface)
        .overlay {
            RoundedRectangle(cornerRadius: DS.CornerRadius.large)
                .stroke(DS.Colours.memoryCardBorder, lineWidth: 1.0)
        }
        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.large))
    }

    private var dateRangeStart: some View {
        Text(thread.startDate.formatted(.dateTime.day().month().year()))
    }

    @ViewBuilder
    private var dateRangeEnd: some View {
        if let endDate = thread.endDate {
            Text(endDate.formatted(.dateTime.day().month().year()))
        } else {
            Text("Ongoing")
        }
    }
}

struct EmptyThreadsView: View {
    var body: some View {
        VStack(spacing: DS.Spacing.lg) {
            Image(systemName: "link")
                .font(DS.Typography.largeTitle)
                .foregroundStyle(DS.Colours.textTertiary)
                .accessibilityHidden(true)
            Text("No threads yet")
                .font(DS.Typography.title3)
                .foregroundStyle(DS.Colours.textPrimary)
            Text("Automatic thread suggestions are coming soon. Confirmed threads will appear here when they are ready.")
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colours.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Spacing.xl)
        }
        .padding(DS.Spacing.xl)
    }
}
