import SwiftUI

struct BalanceView: View {
    @EnvironmentObject var store: TransactionStore
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Current Balance")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text(store.formattedBalance)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}