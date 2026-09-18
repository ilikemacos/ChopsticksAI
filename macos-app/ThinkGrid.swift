import SwiftUI

/// 3×3 thinking mark: left-to-right column sweep (Ninja Chat style).
struct ThinkGrid: View {
    var cell: CGFloat = 4
    var gap: CGFloat = 1.5
    var settled: Bool = false
    var locked: Bool = false

    var body: some View {
        Group {
            if settled || locked {
                grid(opacity: locked ? 0.9 : 0.28, scale: locked ? 1 : 0.78)
            } else {
                TimelineView(.animation) { context in
                    gridLive(context.date.timeIntervalSinceReferenceDate)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(settled ? "cs.AI" : "Working")
    }

    private func cellView(opacity: Double, scale: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 0.4, style: .continuous)
            .fill(Cursor.text)
            .frame(width: cell, height: cell)
            .opacity(opacity)
            .scaleEffect(scale)
    }

    private func grid(opacity: Double, scale: CGFloat) -> some View {
        HStack(spacing: gap) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(spacing: gap) {
                    ForEach(0..<3, id: \.self) { _ in
                        cellView(opacity: opacity, scale: scale)
                    }
                }
            }
        }
        .frame(width: 3 * cell + 2 * gap, height: 3 * cell + 2 * gap)
        .opacity(settled && !locked ? 0.85 : 1)
    }

    private func gridLive(_ t: Double) -> some View {
        HStack(spacing: gap) {
            ForEach(0..<3, id: \.self) { col in
                VStack(spacing: gap) {
                    ForEach(0..<3, id: \.self) { _ in
                        let k = Self.columnLevel(col, t: t)
                        cellView(opacity: 0.12 + 0.88 * k, scale: CGFloat(0.52 + 0.48 * k))
                    }
                }
            }
        }
        .frame(width: 3 * cell + 2 * gap, height: 3 * cell + 2 * gap)
    }

    /// Peak travels left → right, then restarts on the left.
    private static func columnLevel(_ col: Int, t: Double) -> Double {
        let cycle = 0.92
        let phase = (t.truncatingRemainder(dividingBy: cycle) / cycle)
        let peak = phase * 3.2 - 0.15
        let dist = abs(Double(col) - peak)
        return exp(-dist * dist * 2.4)
    }
}

enum AgentWorkMark: Equatable {
    case wait, run, done
}

struct AgentWorkStep: Identifiable, Equatable {
    let id: String
    var label: String
    var mark: AgentWorkMark
}

struct AgentWorkTrace: Equatable {
    var title: String
    var steps: [AgentWorkStep]

    static func starting(title: String, labels: [String]) -> AgentWorkTrace {
        AgentWorkTrace(
            title: title,
            steps: labels.enumerated().map { i, label in
                AgentWorkStep(id: "\(i)", label: label, mark: i == 0 ? .run : .wait)
            }
        )
    }

    mutating func advance(to index: Int) {
        for i in steps.indices {
            if i < index { steps[i].mark = .done }
            else if i == index { steps[i].mark = .run }
            else { steps[i].mark = .wait }
        }
    }

    mutating func finishAll() {
        for i in steps.indices { steps[i].mark = .done }
    }
}

struct AgentWorkPanel: View {
    let trace: AgentWorkTrace
    var showMark: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if showMark { ThinkGrid() }
                Text(trace.title)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(Cursor.text)
            }
            VStack(alignment: .leading, spacing: 3) {
                ForEach(trace.steps) { step in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(markGlyph(step.mark))
                            .font(.system(size: 13, design: .monospaced))
                            .frame(width: 14, alignment: .center)
                            .foregroundStyle(Cursor.text)
                        Text(step.label)
                            .font(.system(size: 13))
                    }
                    .opacity(step.mark == .wait ? 0.38 : step.mark == .done ? 0.72 : 1)
                    .foregroundStyle(Cursor.text)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(trace.title)
    }

    private func markGlyph(_ mark: AgentWorkMark) -> String {
        switch mark {
        case .done: return "✓"
        case .run: return "→"
        case .wait: return "○"
        }
    }
}
