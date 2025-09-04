import SwiftUI

struct WorkingSettingsView: View {
    @EnvironmentObject var store: TransactionStore
    @State private var showingExportSuccess = false
    @State private var showingExportError = false
    @State private var errorMessage = ""
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?
    
    var body: some View {
        Form {
            Section("Statistics") {
                HStack {
                    Text("Total Transactions")
                    Spacer()
                    Text("\(store.transactions.count)")
                        .foregroundStyle(.secondary)
                }
                
                if let oldest = store.transactions.map(\.date).min() {
                    HStack {
                        Text("Oldest Transaction")
                        Spacer()
                        Text(oldest, style: .date)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section("Export") {
                Button {
                    exportToSQLite()
                } label: {
                    Label("Export to SQLite", systemImage: "square.and.arrow.up")
                }
                .disabled(store.transactions.isEmpty)
                
                Text("Exports all transactions to a SQLite database file with account summary view.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("3.0.0 (iCloud)")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Storage")
                    Spacer()
                    Text("iCloud + Local Backup")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .alert("Export Successful", isPresented: $showingExportSuccess) {
            Button("Share") {
                showingShareSheet = true
            }
            Button("OK") { }
        } message: {
            Text("Your transactions have been exported to SQLite format.")
        }
        .alert("Export Error", isPresented: $showingExportError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportedFileURL {
                ShareSheet(fileURL: url)
            }
        }
    }
    
    private func exportToSQLite() {
        let exporter = SQLiteTransactionExporter()
        
        do {
            exportedFileURL = try exporter.exportTransactions(store.transactions)
            showingExportSuccess = true
            print("📤 Exported \(store.transactions.count) transactions to SQLite")
        } catch {
            errorMessage = error.localizedDescription
            showingExportError = true
            print("❌ Export failed: \(error)")
        }
    }
}

// ShareSheet defined in SettingsView.swift