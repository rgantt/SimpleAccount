import SwiftUI

struct WorkingTransactionEntry: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: TransactionStore
    
    @State private var amount: String = ""
    @State private var description: String = ""
    @State private var selectedType = TxType.expense
    
    var decimalAmount: Decimal? {
        guard !amount.isEmpty else { return nil }
        return Decimal(string: amount.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: ""))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Transaction Type", selection: $selectedType) {
                        ForEach(TxType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
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
                    Button("Save Transaction") {
                        saveTransaction()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(decimalAmount == nil || decimalAmount! <= 0 || description.isEmpty)
                }
            }
            .navigationTitle("New Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func saveTransaction() {
        guard let amount = decimalAmount, amount > 0 else { return }
        
        let transaction = Transaction(
            amount: amount,
            description: description,
            type: selectedType
        )
        
        store.addTransaction(transaction)
        dismiss()
    }
}