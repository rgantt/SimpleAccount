import SwiftUI

struct EditTransactionView: View {
    @EnvironmentObject var store: TransactionStore
    @Environment(\.dismiss) var dismiss
    
    let transaction: Transaction
    
    @State private var amount: String
    @State private var description: String
    @State private var type: TxType
    @State private var date: Date
    
    init(transaction: Transaction) {
        self.transaction = transaction
        _amount = State(initialValue: String(describing: NSDecimalNumber(decimal: transaction.amount)))
        _description = State(initialValue: transaction.description)
        _type = State(initialValue: transaction.type)
        _date = State(initialValue: transaction.date)
    }
    
    var isValid: Bool {
        !amount.isEmpty && 
        !description.isEmpty && 
        Decimal(string: amount) != nil &&
        Decimal(string: amount)! > 0
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Transaction Details") {
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    TextField("Description", text: $description)
                    
                    Picker("Type", selection: $type) {
                        ForEach(TxType.allCases, id: \.self) { txType in
                            Label(txType.rawValue, systemImage: txType.icon)
                                .tag(txType)
                        }
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                Section {
                    Text("Original: \(transaction.formattedAmount) - \(transaction.description)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private func saveChanges() {
        guard let decimalAmount = Decimal(string: amount) else { return }
        
        let updatedTransaction = Transaction(
            amount: decimalAmount,
            description: description,
            type: type,
            date: date
        )
        
        store.updateTransaction(transaction, with: updatedTransaction)
        dismiss()
    }
}