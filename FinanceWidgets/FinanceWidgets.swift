//
//  FinanceWidgets.swift
//  FinanceWidgets
//
//  Created by Jas  on 6/2/25.
//
import WidgetKit
import SwiftUI

// ─── WidgetBundle Entry Point ────────────────────────────────────────────────
@main
struct FinanceWidgetsBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        BudgetSummaryWidget()
        BudgetRingWidget()
    }
}

// ─── Timeline Entry ────────────────────────────────────────────────────────────
struct BudgetEntry: TimelineEntry {
    let date: Date
    let today: Double
    let yesterday: Double
    let weeklyBudget: Double
}

// ─── Timeline Provider ─────────────────────────────────────────────────────────
// ─── Timeline Provider ─────────────────────────────────────────────────────────
struct BudgetProvider: TimelineProvider {
    // Create an instance of the data manager to read shared data.
    private let dataManager = WidgetDataManager()

    // The placeholder is for the widget gallery. This is fine to be hardcoded.
    func placeholder(in context: Context) -> BudgetEntry {
        BudgetEntry(date: .now, today: 100, yesterday: 40, weeklyBudget: 200)
    }

    // Snapshot tries to load real data for a more accurate preview in the gallery.
    func getSnapshot(in context: Context, completion: @escaping (BudgetEntry) -> Void) {
        if let sharedData = dataManager.load() {
            let entry = BudgetEntry(date: .now, today: sharedData.today, yesterday: sharedData.yesterday, weeklyBudget: sharedData.weeklyBudget)
            completion(entry)
        } else {
            // Fallback to placeholder if no data is found.
            completion(placeholder(in: context))
        }
    }

    // getTimeline provides the actual data for the live widget on your home screen.
    func getTimeline(in context: Context, completion: @escaping (Timeline<BudgetEntry>) -> Void) {
        let entry: BudgetEntry

        // Try to load the real data from the shared container.
        if let sharedData = dataManager.load() {
            entry = BudgetEntry(date: .now, today: sharedData.today, yesterday: sharedData.yesterday, weeklyBudget: sharedData.weeklyBudget)
            print("Widget timeline created with REAL data.")
        } else {
            // If no data exists yet (e.g., before the app runs), use placeholder data.
            entry = placeholder(in: context)
            print("Widget timeline created with PLACEHOLDER data.")
        }

        // Create the timeline. Use .atEnd so it waits for the main app to trigger reloads
        // instead of updating on a fixed schedule.
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

// ─── Shared Background Helper ─────────────────────────────────────────────────
extension View {
    @ViewBuilder
    func widgetBackground<Background: View>(_ backgroundView: Background) -> some View {
        if #available(iOS 17.0, *) {
            self
              .containerBackground(for: .widget) {}
              .background(backgroundView)
        } else {
            self.background(backgroundView)
        }
    }
}

// ─── 1) Home‐Screen small (.systemSmall) ───────────────────────────────────────
struct BudgetSummaryWidget: Widget {
    let kind = "BudgetSummaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BudgetProvider()) { entry in
            SignatureWidgetView(
                today: entry.today,
                yesterday: entry.yesterday,
                weeklyBudget: entry.weeklyBudget
            )
        }
        .configurationDisplayName("Budget Summary")
        .description("Today’s spend, yesterday’s spend, and weekly remaining.")
        .supportedFamilies([.systemSmall])
    }
}

struct SignatureWidgetView: View {
    let today: Double
    let yesterday: Double
    let weeklyBudget: Double

    private var remaining: Double {
        max(weeklyBudget - today, 0)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            // Hero Number: Today's Spend
            Text(today, format: .currency(code: "USD").precision(.fractionLength(0)))
                .font(.system(size: 64, weight: .heavy, design: .rounded))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .contentTransition(.numericText())

            Spacer(minLength: 0)

            // Bottom Info Blocks
            // Bottom Info Blocks—two equal columns
            HStack(spacing: 12) {
                InfoBlockView(title: "YESTERDAY", value: yesterday, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                InfoBlockView(title: "REMAINING", value: remaining, alignment: .trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

        }
        .padding(14)
        .widgetBackground(Color(uiColor: .systemBackground))
    }
}

struct InfoBlockView: View {
    let title: String
    let value: Double
    let alignment: HorizontalAlignment

    var body: some View {
            VStack(alignment: alignment, spacing: 2) {
                Text(title)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)                   // ← no wrapping
                    .minimumScaleFactor(0.6)        // ← shrink if needed

                Text(value, format: .currency(code: "USD").precision(.fractionLength(0)))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)                   // ← no wrapping
                    .minimumScaleFactor(0.6)        // ← shrink if needed
            }
            .frame(maxWidth: .infinity,
                   alignment: alignment == .leading ? .leading : .trailing)
        }
}

// ─── 2) Lock‐Screen accessory (.accessoryCircular) ─────────────────────────────
struct BudgetRingWidget: Widget {
    let kind = "BudgetRingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BudgetProvider()) { entry in
            ThicknessRingView(value: entry.today)
        }
        .configurationDisplayName("Spending Ring")
        .description("Lock-screen gauge of today’s spend.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct ThicknessRingView: View {
    /// 1) How much you’ve spent today
    let value: Double
    
    /// 2) “Full-thickness” threshold — at or above this, ring is maxWidth
    let fullThreshold: Double = 200
    
    /// 3) Min/max stroke widths for 0…fullThreshold
    let minWidth: CGFloat = 1
    let maxWidth: CGFloat = 10

    /// Normalize value to 0…1
    private var ratio: CGFloat {
        CGFloat(min(value / fullThreshold, 1))
    }
    
    /// Line width = minWidth + (maxWidth-minWidth)×ratio
    private var lineWidth: CGFloat {
        minWidth + (maxWidth - minWidth) * ratio
    }

    var body: some View {
        ZStack {
          // 1) Frosted-glass backdrop
          Circle()
            .fill(.ultraThinMaterial)        // iOS17+ only
            .opacity(0.8)                    // slightly transparent
            .clipShape(Circle())

          // 2) Your dynamic ring (same as before)
          Circle()
            .stroke(
              style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .foregroundStyle(.primary)

          // 3) Center label
            Text("$\(Int(value))")
                .font(.system(size: 18, weight: .bold, design: .rounded))
        }
        
        .widgetBackground(Color.clear)
    }
}

// ─── Previews ─────────────────────────────────────────────────────────────────
#if DEBUG
struct BudgetWidgets_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SignatureWidgetView(today: 72, yesterday: 65, weeklyBudget: 200)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Home • Small")

            ThicknessRingView(value: 72)
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
                .previewDisplayName("Lock • Circular")
        }
    }
}
#endif


