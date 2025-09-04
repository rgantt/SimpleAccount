import SwiftUI

struct BalanceChart: View {
    let transactions: [Transaction]
    
    var balanceOverTime: [(date: Date, balance: Decimal)] {
        let sortedTransactions = transactions.sorted { $0.date < $1.date }
        var runningBalance: Decimal = 0
        var balancePoints: [(date: Date, balance: Decimal)] = []
        
        for transaction in sortedTransactions {
            runningBalance += transaction.signedAmount
            balancePoints.append((date: transaction.date, balance: runningBalance))
        }
        
        return balancePoints
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Balance Over Time")
                .font(.headline)
            
            if balanceOverTime.isEmpty {
                Text("No data available")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                SimpleLineChart(data: balanceOverTime)
            }
        }
    }
}

struct IncomeExpenseChart: View {
    let transactions: [Transaction]
    
    var chartData: [(category: String, amount: Decimal, color: Color)] {
        let income = transactions.filter { $0.type == .income || $0.type == .sale }
            .reduce(Decimal.zero) { $0 + $1.amount }
        let expenses = transactions.filter { $0.type == .expense }
            .reduce(Decimal.zero) { $0 + $1.amount }
        
        return [
            ("Income", income, .green),
            ("Expenses", expenses, .red)
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Income vs Expenses")
                .font(.headline)
            
            SimpleBarChart(data: chartData)
        }
    }
}

struct TrendsChart: View {
    let transactions: [Transaction]
    
    var pieData: [(type: String, amount: Decimal, color: Color)] {
        let income = transactions.filter { $0.type == .income }.reduce(Decimal.zero) { $0 + $1.amount }
        let sales = transactions.filter { $0.type == .sale }.reduce(Decimal.zero) { $0 + $1.amount }
        let expenses = transactions.filter { $0.type == .expense }.reduce(Decimal.zero) { $0 + $1.amount }
        
        return [
            ("Income", income, .green),
            ("Sales", sales, .blue),
            ("Expenses", expenses, .red)
        ].filter { $0.amount > 0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Transaction Types")
                .font(.headline)
            
            SimplePieChart(data: pieData)
        }
    }
}

struct SimpleLineChart: View {
    let data: [(date: Date, balance: Decimal)]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
            let width = geometry.size.width
            let height = geometry.size.height
            
            if let minBalance = data.map(\.balance).min(),
               let maxBalance = data.map(\.balance).max(),
               let minDate = data.map(\.date).min(),
               let maxDate = data.map(\.date).max() {
                
                let dateRange = maxDate.timeIntervalSince(minDate)
                let balanceRange = maxBalance - minBalance
                if balanceRange > 0 {
                
                Path { path in
                    for (index, point) in data.enumerated() {
                        let x = width * (point.date.timeIntervalSince(minDate) / dateRange)
                        let balancePercent = (point.balance - minBalance) / balanceRange
                        let y = height * (1 - NSDecimalNumber(decimal: balancePercent).doubleValue)
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.blue, lineWidth: 2)
                } else {
                    Text("Insufficient range")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                Text("Insufficient data")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            }
        }
    }
}

struct SimpleBarChart: View {
    let data: [(category: String, amount: Decimal, color: Color)]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 20) {
            ForEach(data, id: \.category) { item in
                VStack(spacing: 8) {
                    if let maxAmount = data.map(\.amount).max(), maxAmount > 0 {
                        Rectangle()
                            .fill(item.color)
                            .frame(width: 60, height: CGFloat(NSDecimalNumber(decimal: item.amount / maxAmount).doubleValue) * 150)
                    }
                    
                    VStack(spacing: 2) {
                        Text(NumberFormatter.currency.string(from: NSDecimalNumber(decimal: item.amount)) ?? "$0")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Text(item.category)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct SimplePieChart: View {
    let data: [(type: String, amount: Decimal, color: Color)]
    
    var body: some View {
        HStack(spacing: 20) {
            // Simple pie representation with circles
            HStack(spacing: 8) {
                let total = data.map(\.amount).reduce(Decimal.zero, +)
                
                ForEach(data, id: \.type) { item in
                    if total > 0 {
                        let percentage = item.amount / total
                        Circle()
                            .fill(item.color)
                            .frame(width: CGFloat(NSDecimalNumber(decimal: percentage).doubleValue) * 60 + 20)
                    }
                }
            }
            
            // Legend
            VStack(alignment: .leading, spacing: 4) {
                ForEach(data, id: \.type) { item in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(item.color)
                            .frame(width: 12, height: 12)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.type)
                                .font(.caption)
                            Text(NumberFormatter.currency.string(from: NSDecimalNumber(decimal: item.amount)) ?? "$0")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}