import SwiftUI
import SwiftData

struct TransactionEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let accountingService: AccountingService
    
    @State private var amount: String = ""
    @State private var description: String = ""
    @State private var transactionType: TransactionType = .expense
    @State private var showingError = false
    @State private var errorMessage = ""
    
    enum TransactionType: String, CaseIterable {
        case expense = "Spend Money"
        case contribution = "Add Money"
        case sale = "Record Sale"
        
        var systemImage: String {
            switch self {
            case .expense: return "cart.fill"
            case .contribution: return "plus.circle.fill"
            case .sale: return "tag.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .expense: return .red
            case .contribution: return .green
            case .sale: return .blue
            }
        }
    }
    
    
    var decimalAmount: Decimal? {
        guard !amount.isEmpty else { return nil }
        let cleanedAmount = amount.replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
        return Decimal(string: cleanedAmount)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Transaction Type") {
                    Picker("Type", selection: $transactionType) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.systemImage)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Details") {
                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                    
                    TextField("Description", text: $description)
                }
                
                Section {
                    Button(action: saveTransaction) {
                        HStack {
                            Image(systemName: transactionType.systemImage)
                            Text(transactionType.rawValue)
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.white)
                        .padding()
                        .background(transactionType.color)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .disabled(decimalAmount == nil || decimalAmount! <= 0 || description.isEmpty)
                }
            }
            .navigationTitle("New Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveTransaction() {
        guard let amount = decimalAmount, amount > 0 else {
            errorMessage = "Please enter a valid amount"
            showingError = true
            return
        }
        
        // Ensure AccountingService has the current context
        accountingService.setup(with: modelContext)
        
        do {
            switch transactionType {
            case .expense:
                try accountingService.spendMoney(amount: amount, description: description)
            case .contribution:
                try accountingService.addMoney(amount: amount, description: description, isSale: false)
            case .sale:
                try accountingService.addMoney(amount: amount, description: description, isSale: true)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}