import SwiftUI
import Charts

struct ReportsView: View {
    @EnvironmentObject var store: TransactionStore
    @State private var timeRange = TimeRange.month
    @State private var selectedMetric = Metric.balance
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"
        case all = "All Time"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            case .year: return 365
            case .all: return Int.max
            }
        }
    }
    
    enum Metric: String, CaseIterable {
        case balance = "Balance Over Time"
        case income = "Income vs Expenses"
        case trends = "Spending Trends"
        
        var systemImage: String {
            switch self {
            case .balance: return "chart.line.uptrend.xyaxis"
            case .income: return "chart.bar.xaxis"
            case .trends: return "chart.pie"
            }
        }
    }
    
    var filteredTransactions: [Transaction] {
        guard timeRange != .all else { return store.transactions }
        
        let cutoffDate = Calendar.current.date(
            byAdding: .day,
            value: -timeRange.days,
            to: Date()
        ) ?? Date()
        
        return store.transactions.filter { $0.date >= cutoffDate }
    }
    
    var totalIncome: Decimal {
        filteredTransactions
            .filter { $0.type == .income || $0.type == .sale }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }
    
    var totalExpenses: Decimal {
        filteredTransactions
            .filter { $0.type == .expense }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }
    
    var netChange: Decimal {
        totalIncome - totalExpenses
    }
    
    var averageTransaction: Decimal {
        guard !filteredTransactions.isEmpty else { return 0 }
        return filteredTransactions.reduce(Decimal.zero) { $0 + abs($1.signedAmount) } / Decimal(filteredTransactions.count)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time Range Picker
                Picker("Time Range", selection: $timeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Summary Stats
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatCard(
                        title: "Total Income",
                        amount: totalIncome,
                        color: .green,
                        icon: "arrow.down.circle.fill"
                    )
                    
                    StatCard(
                        title: "Total Expenses",
                        amount: totalExpenses,
                        color: .red,
                        icon: "arrow.up.circle.fill"
                    )
                    
                    StatCard(
                        title: "Net Change",
                        amount: netChange,
                        color: netChange >= 0 ? .blue : .orange,
                        icon: "equal.circle.fill"
                    )
                    
                    StatCard(
                        title: "Avg Transaction",
                        amount: averageTransaction,
                        color: .purple,
                        icon: "chart.bar.fill"
                    )
                }
                .padding(.horizontal)
                
                // Chart Section
                if !filteredTransactions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Metric", selection: $selectedMetric) {
                            ForEach(Metric.allCases, id: \.self) { metric in
                                Label(metric.rawValue, systemImage: metric.systemImage)
                                    .tag(metric)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        Group {
                            switch selectedMetric {
                            case .balance:
                                BalanceChart(transactions: filteredTransactions)
                            case .income:
                                IncomeExpenseChart(transactions: filteredTransactions)
                            case .trends:
                                TrendsChart(transactions: filteredTransactions)
                            }
                        }
                        .frame(height: 250)
                    }
                    .padding()
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Transaction Breakdown
                TransactionBreakdown(transactions: filteredTransactions)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Reports")
    }
}

struct StatCard: View {
    let title: String
    let amount: Decimal
    let color: Color
    let icon: String
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            VStack(spacing: 4) {
                Text(formattedAmount)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGroupedBackground))
        .cornerRadius(10)
    }
}

struct TransactionBreakdown: View {
    let transactions: [Transaction]
    
    var typeBreakdown: [(type: TxType, count: Int, total: Decimal)] {
        let grouped = Dictionary(grouping: transactions) { $0.type }
        return TxType.allCases.compactMap { type in
            guard let txs = grouped[type], !txs.isEmpty else { return nil }
            let total = txs.reduce(Decimal.zero) { $0 + $1.amount }
            return (type: type, count: txs.count, total: total)
        }.sorted { $0.total > $1.total }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Breakdown by Type")
                .font(.headline)
            
            ForEach(typeBreakdown, id: \.type) { item in
                HStack {
                    Image(systemName: item.type.icon)
                        .foregroundStyle(item.type.color)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.type.rawValue)
                            .font(.body)
                        Text("\(item.count) transactions")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(NumberFormatter.currency.string(from: NSDecimalNumber(decimal: item.total)) ?? "$0.00")
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
}

extension NumberFormatter {
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }()
}