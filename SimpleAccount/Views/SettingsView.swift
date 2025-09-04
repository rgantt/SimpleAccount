import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var accounts: [Account]
    @Query private var entries: [JournalEntry]
    
    @State private var showingExportSuccess = false
    @State private var showingExportError = false
    @State private var errorMessage = ""
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?
    
    var totalTransactions: Int {
        entries.count
    }
    
    var oldestTransaction: Date? {
        entries.map(\.date).min()
    }
    
    var body: some View {
        Form {
            Section("Database Info") {
                HStack {
                    Text("Total Transactions")
                    Spacer()
                    Text("\(totalTransactions)")
                        .foregroundStyle(.secondary)
                }
                
                if let oldest = oldestTransaction {
                    HStack {
                        Text("Oldest Transaction")
                        Spacer()
                        Text(oldest, style: .date)
                            .foregroundStyle(.secondary)
                    }
                }
                
                HStack {
                    Text("Accounts")
                    Spacer()
                    Text("\(accounts.count)")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Export") {
                Button {
                    exportToSQLite()
                } label: {
                    Label("Export to SQLite", systemImage: "square.and.arrow.up")
                }
                
                Text("Exports all transactions to a SQLite database file that can be opened in any database application.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("Data Management") {
                Button(role: .destructive) {
                    
                } label: {
                    Label("Clear All Data", systemImage: "trash")
                        .foregroundStyle(.red)
                }
                .disabled(true)
            }
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Storage")
                    Spacer()
                    Text("iCloud Sync Enabled")
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
            Text("Your data has been exported to SQLite format.")
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
        let exporter = SQLiteExporter(modelContext: modelContext)
        
        do {
            exportedFileURL = try exporter.export()
            showingExportSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showingExportError = true
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let fileURL: URL
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}