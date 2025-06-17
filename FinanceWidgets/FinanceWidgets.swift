//
//  FinanceWidgets.swift
//  FinanceWidgets
//
//  Created by Jas  on 6/2/25.
//

import WidgetKit
import SwiftUI

// ------------------------------------------------
// MARK: – THE TIMELINE ENTRY (unchanged)
struct FinanceEntry: TimelineEntry {
    let date: Date
    let summaries: [SummaryEntry]
}

// ------------------------------------------------
// MARK: – THE PROVIDER (unchanged)
struct FinanceProvider: TimelineProvider {
    func placeholder(in context: Context) -> FinanceEntry {
        FinanceEntry(date: Date(), summaries: placeholderSummaries())
    }

    func getSnapshot(in context: Context, completion: @escaping (FinanceEntry) -> Void) {
        completion(FinanceEntry(date: Date(), summaries: placeholderSummaries()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FinanceEntry>) -> Void) {
        let entries = loadSummaries()
        let timeline = Timeline(entries: [FinanceEntry(date: Date(), summaries: entries)],
                                policy: .atEnd)
        completion(timeline)
    }

    private func loadSummaries() -> [SummaryEntry] {
        let defaults = UserDefaults(suiteName: "group.com.singh.financeapp")
        guard
            let data = defaults?.data(forKey: "summaryData"),
            let decoded = try? JSONDecoder().decode([SummaryEntry].self, from: data)
        else {
            return placeholderSummaries()
        }
        return decoded
    }

    private func placeholderSummaries() -> [SummaryEntry] {
        [
            SummaryEntry(title: "Spent Today", amount:  42.75, subtitle: "Yesterday $38.12"),
            SummaryEntry(title: "Spent This Week", amount: 310.25, subtitle: "Last Week $298.50"),
            SummaryEntry(title: "Spent This Month", amount: 1200.40, subtitle: "Last Month $1150.00")
        ]
    }
}


// ------------------------------------------------
// MARK: – WIDGET‐1: The Existing Spending Summary Widget

struct FinanceWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: FinanceEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                LockScreenCircularView(latest: entry.summaries.first)
            case .systemMedium:
                HomeScreenMediumView(summaries: entry.summaries)
            default:
                HomeScreenMediumView(summaries: entry.summaries)
            }
        }
        .padding()
        .containerBackground(.clear, for: .widget)
    }
}

struct FinanceWidget: Widget {
    let kind: String = "FinanceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind,
                            provider: FinanceProvider()) { entry in
            FinanceWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Spending Summary")
        .description("See your recent spending in a small Lock Screen circular widget or a medium Home Screen widget.")
        .supportedFamilies([.accessoryCircular, .systemMedium])
    }
}

// MARK: – Existing Home Screen (Medium) View
struct HomeScreenMediumView: View {
    let summaries: [SummaryEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending Summary")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .padding(.bottom, 2)

            HStack(spacing: 12) {
                if summaries.indices.contains(0) {
                    let today = summaries[0]
                    VStack(alignment: .leading, spacing: 4) {
                        Text(today.title.uppercased())
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                        Text("$\(today.amount, specifier: "%.2f")")
                            .font(.title3).bold()
                            .foregroundColor(.white)
                        Text(today.subtitle)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                Spacer()

                if summaries.indices.contains(1) {
                    let week = summaries[1]
                    VStack(alignment: .leading, spacing: 4) {
                        Text(week.title.uppercased())
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                        Text("$\(week.amount, specifier: "%.2f")")
                            .font(.title3).bold()
                            .foregroundColor(.white)
                        Text(week.subtitle)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.10, green: 0.10, blue: 0.15),
                            Color(red: 0.12, green: 0.12, blue: 0.18)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .purple.opacity(0.4), radius: 10, x: 0, y: 4)
        )
        .containerBackground(.clear, for: .widget)
    }
}


// MARK: – Existing Lock Screen (Circular) View (#1)
struct LockScreenCircularView: View {
    let latest: SummaryEntry?

    var body: some View {
        ZStack {
            // Purple → Magenta gradient circle
            Circle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(red: 0.55, green: 0.15, blue: 0.55), location: 0.0),
                            .init(color: Color(red: 0.85, green: 0.25, blue: 0.65), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    // thin white border
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )

            // Icon + amount
            VStack(spacing: 0) {
                if let today = latest {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)

                    Text("\(Int(today.amount))")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                } else {
                    Image(systemName: "dollarsign.circle")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.7))
                        .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)

                    Text("–")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.7))
                        .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                }
            }
        }
        .frame(width: 60, height: 60) // EXACTLY the Lock Screen accessory circular size
    }
}


// ------------------------------------------------
// MARK: – WIDGET‐2: The New Gauge Widget

struct GaugeWidgetEntryView: View {
    let entry: FinanceEntry

    // Extract “today’s” amount from the first summary if it exists, else zero:
    var todayAmount: Double {
        entry.summaries.first?.amount ?? 0
    }

    // Determine ring color based on thresholds:
    private var ringColor: Color {
        switch todayAmount {
        case _ where todayAmount > 100:
            return .red
        case 25...100:
            return .yellow
        default:
            return .green
        }
    }

    // Map the numeric value into a 0…1 “progress” (cap at 200):
    private var progress: Double {
        min(todayAmount / 200.0, 1.0)
    }

    var body: some View {
        ZStack {
            // 1) Gray “track” circle behind
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [ringColor, ringColor.opacity(0.6)]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )


            // 2) Colored ring “progress”
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    ringColor.gradient, // Use gradient for vibrance
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90)) // Start from top

            // 3) Numeric label in center
            if todayAmount > 0 {
                Text("\(Int(todayAmount))")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
            } else {
                Text("–")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                    .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
        }
        .padding(8) // so that the ring is not clipped at the edges
        .background(
            // dark background so white text/ring pops:
            Circle().fill(Color(UIColor.systemGray6))
        )
        .frame(width: 60, height: 60) // EXACTLYLock Screen circular size
        .containerBackground(.clear, for: .widget)

    }
}

struct GaugeWidget: Widget {
    let kind: String = "GaugeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind,
                            provider: FinanceProvider()) { entry in
            GaugeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Today’s Spending Gauge")
        .description("A quick glance at how much you’ve spent today (green/yellow/red).")
        .supportedFamilies([.accessoryCircular]) // this widget is circular‐only
    }
}


// ------------------------------------------------
// MARK: – WIDGET BUNDLE




// ------------------------------------------------
// MARK: – PREVIEWS (for both widgets)

#if DEBUG
struct FinanceWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview the Spending Summary (Medium + Circular):
            FinanceWidgetEntryView(
                entry: FinanceEntry(
                    date: Date(),
                    summaries: [
                        SummaryEntry(title: "Spent Today", amount: 50.0, subtitle: "Yesterday $45.00"),
                        SummaryEntry(title: "Spent This Week", amount: 300.0, subtitle: "Last Week $280.00")
                    ]
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemMedium))

            FinanceWidgetEntryView(
                entry: FinanceEntry(
                    date: Date(),
                    summaries: [
                        SummaryEntry(title: "Spent Today", amount: 75.0, subtitle: "Yesterday $65.00")
                    ]
                )
            )
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))

            // Preview the new Gauge widget with various values:
            GaugeWidgetEntryView(
                entry: FinanceEntry(
                    date: Date(),
                    summaries: [
                        SummaryEntry(title: "Spent Today", amount: 10.0, subtitle: "…")
                    ]
                )
            )
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            .previewDisplayName("Gauge – Green (<25)")

            GaugeWidgetEntryView(
                entry: FinanceEntry(
                    date: Date(),
                    summaries: [
                        SummaryEntry(title: "Spent Today", amount: 60.0, subtitle: "…")
                    ]
                )
            )
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            .previewDisplayName("Gauge – Yellow (25≤amt≤100)")

            GaugeWidgetEntryView(
                entry: FinanceEntry(
                    date: Date(),
                    summaries: [
                        SummaryEntry(title: "Spent Today", amount: 150.0, subtitle: "…")
                    ]
                )
            )
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            .previewDisplayName("Gauge – Red (>100)")
        }
    }
}
#endif



