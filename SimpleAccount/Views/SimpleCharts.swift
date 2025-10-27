import SwiftUI

struct BalanceChart: View {
    let transactions: [Transaction]
    let allTransactions: [Transaction]

    var chartData: (balance: [(date: Date, balance: Decimal)], income: [(date: Date, income: Decimal)], expenses: [(date: Date, expenses: Decimal)]) {
        let sortedTransactions = transactions.sorted { $0.date < $1.date }

        // Calculate initial balance from all transactions before the filtered period
        let initialBalance: Decimal
        if let firstFilteredDate = sortedTransactions.first?.date {
            initialBalance = allTransactions
                .filter { $0.date < firstFilteredDate }
                .reduce(Decimal.zero) { $0 + $1.signedAmount }
        } else {
            initialBalance = 0
        }

        var runningBalance: Decimal = initialBalance
        var runningIncome: Decimal = 0
        var runningExpenses: Decimal = 0

        var balancePoints: [(date: Date, balance: Decimal)] = []
        var incomePoints: [(date: Date, income: Decimal)] = []
        var expensePoints: [(date: Date, expenses: Decimal)] = []

        for transaction in sortedTransactions {
            runningBalance += transaction.signedAmount

            if transaction.type == .income || transaction.type == .sale {
                runningIncome += transaction.amount
            } else {
                runningExpenses += transaction.amount
            }

            balancePoints.append((date: transaction.date, balance: runningBalance))
            incomePoints.append((date: transaction.date, income: runningIncome))
            expensePoints.append((date: transaction.date, expenses: runningExpenses))
        }

        return (balance: balancePoints, income: incomePoints, expenses: expensePoints)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Financial Trends")
                    .font(.headline)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Label("Balance", systemImage: "circle.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Label("Income", systemImage: "circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                    Label("Expenses", systemImage: "circle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .font(.caption2)
            }
            
            if chartData.balance.isEmpty {
                Text("No data available")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                MultiLineChart(
                    balanceData: chartData.balance,
                    incomeData: chartData.income,
                    expenseData: chartData.expenses
                )
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

struct MultiLineChart: View {
    let balanceData: [(date: Date, balance: Decimal)]
    let incomeData: [(date: Date, income: Decimal)]
    let expenseData: [(date: Date, expenses: Decimal)]

    var body: some View {
        GeometryReader { geometry in
            let chartWidth = geometry.size.width - 100  // Increased for right Y-axis
            let chartHeight = geometry.size.height - 50
            let chartOriginX: CGFloat = 50
            let chartOriginY: CGFloat = 10

            ZStack {
                let allDates = balanceData.map(\.date)

                if let minDate = allDates.min(),
                   let maxDate = allDates.max(),
                   !balanceData.isEmpty {

                    // Calculate separate Y-axis ranges
                    // Left Y-axis: Balance only
                    let balanceValues = balanceData.map(\.balance)
                    let minBalance = balanceValues.min() ?? 0
                    let maxBalance = balanceValues.max() ?? 0
                    let balanceRange = maxBalance - minBalance
                    let balancePadding = balanceRange * 0.1
                    let balanceMin = minBalance - balancePadding
                    let balanceMax = maxBalance + balancePadding
                    let balanceAxisRange = balanceMax - balanceMin

                    // Right Y-axis: Income and Expenses (always starts at 0)
                    let incomeExpenseValues = incomeData.map(\.income) + expenseData.map(\.expenses)
                    let maxIncomeExpense = incomeExpenseValues.max() ?? 0
                    let incomeExpensePadding = maxIncomeExpense * 0.1
                    let incomeExpenseMin: Decimal = 0
                    let incomeExpenseMax = maxIncomeExpense + incomeExpensePadding
                    let incomeExpenseAxisRange = incomeExpenseMax - incomeExpenseMin

                    let dateRange = maxDate.timeIntervalSince(minDate)

                    // Background grid
                    Path { path in
                        // Horizontal grid lines
                        for i in 0...4 {
                            let y = chartOriginY + chartHeight * CGFloat(i) / 4
                            path.move(to: CGPoint(x: chartOriginX, y: y))
                            path.addLine(to: CGPoint(x: chartOriginX + chartWidth, y: y))
                        }

                        // Vertical grid lines
                        for i in 0...4 {
                            let x = chartOriginX + chartWidth * CGFloat(i) / 4
                            path.move(to: CGPoint(x: x, y: chartOriginY))
                            path.addLine(to: CGPoint(x: x, y: chartOriginY + chartHeight))
                        }
                    }
                    .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)

                    // Zero line for balance if zero is in range
                    if balanceMin <= 0 && balanceMax >= 0 {
                        let zeroY = chartOriginY + chartHeight * (1 - CGFloat(NSDecimalNumber(decimal: (0 - balanceMin) / balanceAxisRange).doubleValue))
                        Path { path in
                            path.move(to: CGPoint(x: chartOriginX, y: zeroY))
                            path.addLine(to: CGPoint(x: chartOriginX + chartWidth, y: zeroY))
                        }
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    }

                    // Balance line (using left Y-axis scale)
                    if !balanceData.isEmpty && balanceAxisRange > 0 {
                        Path { path in
                            for (index, point) in balanceData.enumerated() {
                                let x = chartOriginX + chartWidth * (point.date.timeIntervalSince(minDate) / dateRange)
                                let y = chartOriginY + chartHeight * (1 - CGFloat(NSDecimalNumber(decimal: (point.balance - balanceMin) / balanceAxisRange).doubleValue))

                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Color.blue, lineWidth: 3)
                    }

                    // Income line (using right Y-axis scale)
                    if !incomeData.isEmpty && incomeExpenseAxisRange > 0 {
                        Path { path in
                            for (index, point) in incomeData.enumerated() {
                                let x = chartOriginX + chartWidth * (point.date.timeIntervalSince(minDate) / dateRange)
                                let y = chartOriginY + chartHeight * (1 - CGFloat(NSDecimalNumber(decimal: (point.income - incomeExpenseMin) / incomeExpenseAxisRange).doubleValue))

                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Color.green, lineWidth: 2)
                    }

                    // Expenses line (using right Y-axis scale)
                    if !expenseData.isEmpty && incomeExpenseAxisRange > 0 {
                        Path { path in
                            for (index, point) in expenseData.enumerated() {
                                let x = chartOriginX + chartWidth * (point.date.timeIntervalSince(minDate) / dateRange)
                                let y = chartOriginY + chartHeight * (1 - CGFloat(NSDecimalNumber(decimal: (point.expenses - incomeExpenseMin) / incomeExpenseAxisRange).doubleValue))

                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Color.red, lineWidth: 2)
                    }

                    // Left Y-axis labels (Balance)
                    ForEach([0, 1, 2, 3, 4], id: \.self) { i in
                        let fraction = Double(i) / 4.0
                        let range = NSDecimalNumber(decimal: balanceMax - balanceMin).doubleValue
                        let maxValue = NSDecimalNumber(decimal: balanceMax).doubleValue
                        let valueDouble = maxValue - range * fraction
                        let yPosition = chartOriginY + chartHeight * CGFloat(i) / 4

                        Text(NumberFormatter.currency.string(from: NSNumber(value: valueDouble)) ?? "$0")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                            .position(x: 25, y: yPosition)
                    }

                    // Right Y-axis labels (Income/Expenses)
                    ForEach([0, 1, 2, 3, 4], id: \.self) { i in
                        let fraction = Double(i) / 4.0
                        let range = NSDecimalNumber(decimal: incomeExpenseMax - incomeExpenseMin).doubleValue
                        let maxValue = NSDecimalNumber(decimal: incomeExpenseMax).doubleValue
                        let valueDouble = maxValue - range * fraction
                        let yPosition = chartOriginY + chartHeight * CGFloat(i) / 4

                        Text(NumberFormatter.currency.string(from: NSNumber(value: valueDouble)) ?? "$0")
                            .font(.caption2)
                            .foregroundStyle(.green)
                            .position(x: chartOriginX + chartWidth + 35, y: yPosition)
                    }

                    // X-axis date labels
                    ForEach([0, 1, 2, 3, 4], id: \.self) { i in
                        let xPosition = chartOriginX + chartWidth * CGFloat(i) / 4
                        let dateInterval = dateRange * Double(i) / 4.0
                        let labelDate = Date(timeInterval: dateInterval, since: minDate)

                        Text(labelDate.formatted(.dateTime.month(.defaultDigits).day(.defaultDigits)))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .position(x: xPosition, y: chartOriginY + chartHeight + 20)
                    }

                } else {
                    Text("Insufficient data")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(minHeight: 200)
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