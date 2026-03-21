// CostDashboardView.swift
// Botcrew

import SwiftUI
import Charts

struct CostDashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    private var records: [CostRecord] {
        appState.costHistory
    }

    private var totalCost: Double {
        records.reduce(0) { $0 + $1.cost }
    }

    private var todayCost: Double {
        let today = Calendar.current.startOfDay(for: Date())
        return records.filter { $0.date >= today }.reduce(0) { $0 + $1.cost }
    }

    private var dailyCosts: [(date: Date, cost: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: records) { record in
            calendar.startOfDay(for: record.date)
        }
        let last7Days = (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: Date()))
        }
        return last7Days.reversed().map { day in
            (date: day, cost: grouped[day]?.reduce(0) { $0 + $1.cost } ?? 0)
        }
    }

    private var projectCosts: [(name: String, cost: Double)] {
        let grouped = Dictionary(grouping: records) { $0.projectId }
        return grouped.compactMap { (projectId, records) in
            let name = appState.projects.first(where: { $0.id == projectId })?.name ?? "Unknown"
            let cost = records.reduce(0) { $0 + $1.cost }
            return (name: name, cost: cost)
        }.sorted { $0.cost > $1.cost }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Cost Dashboard")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: 0x0A84FF))
            }
            .padding(16)

            Divider().opacity(0.15)

            ScrollView {
                VStack(spacing: 16) {
                    // Summary cards
                    HStack(spacing: 12) {
                        costCard(label: "TODAY", value: todayCost)
                        costCard(label: "ALL TIME", value: totalCost)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    // 7-day chart
                    if !records.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("LAST 7 DAYS")
                                .font(.system(size: 10, weight: .semibold))
                                .tracking(0.5)
                                .foregroundStyle(.white.opacity(0.35))

                            Chart(dailyCosts, id: \.date) { item in
                                BarMark(
                                    x: .value("Date", item.date, unit: .day),
                                    y: .value("Cost", item.cost)
                                )
                                .foregroundStyle(Color(hex: 0x0A84FF).opacity(0.6))
                                .cornerRadius(3)
                            }
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day)) { value in
                                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                                        .foregroundStyle(.white.opacity(0.35))
                                }
                            }
                            .chartYAxis {
                                AxisMarks { value in
                                    AxisValueLabel {
                                        if let v = value.as(Double.self) {
                                            Text(String(format: "$%.2f", v))
                                                .foregroundStyle(.white.opacity(0.35))
                                        }
                                    }
                                }
                            }
                            .frame(height: 120)
                        }
                        .padding(.horizontal, 16)
                    }

                    // Per-project breakdown
                    if !projectCosts.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("BY PROJECT")
                                .font(.system(size: 10, weight: .semibold))
                                .tracking(0.5)
                                .foregroundStyle(.white.opacity(0.35))

                            ForEach(projectCosts, id: \.name) { item in
                                HStack {
                                    Text(item.name)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.75))
                                    Spacer()
                                    Text(String(format: "$%.4f", item.cost))
                                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                                        .foregroundStyle(.white.opacity(0.85))
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    if records.isEmpty {
                        Text("No cost data yet. Start a session to begin tracking.")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.45))
                            .padding(.top, 30)
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .frame(width: 380, height: 420)
    }

    private func costCard(label: String, value: Double) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(.white.opacity(0.35))
            Text(String(format: "$%.4f", value))
                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.04))
        )
    }
}
