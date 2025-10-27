# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SimpleAccount is a personal budgeting iOS app built with SwiftUI that functions as a single-account accounting system for tracking "spending money." The app uses double-entry bookkeeping principles while presenting a simple interface for recording income, expenses, and sales.

## Commands

### Build and Run
```bash
# Open the project in Xcode
open SimpleAccount.xcodeproj

# Build from command line (use specific simulator ID to avoid ambiguity)
xcodebuild -scheme SimpleAccount -destination 'platform=iOS Simulator,id=2981B45A-F168-4A1C-84E5-6FF50A9B63C0' build

# Clean and build
xcodebuild -scheme SimpleAccount -destination 'platform=iOS Simulator,id=2981B45A-F168-4A1C-84E5-6FF50A9B63C0' clean build

# Build for device
xcodebuild -scheme SimpleAccount build

# Run tests
xcodebuild -scheme SimpleAccount test

# List available simulators
xcrun simctl list devices available
```

## Architecture

### Data Persistence Strategy
The app uses **NSUbiquitousKeyValueStore + UserDefaults** for data persistence, NOT SwiftData (which had fundamental reliability issues). The core data model is:
- **Transaction** struct (Codable) with id, date, amount, description, and type
- **TransactionStore** (@ObservableObject) manages all transactions and persistence
- **TxType** enum: income, expense, sale

### Core Application Structure

#### App Entry Point
- **SimpleAccountApp.swift**: Creates and provides TransactionStore via @EnvironmentObject
- **ContentView.swift**: TabView with three tabs: Balance, Reports, and Settings

#### Data Flow
1. **TransactionStore** holds all transactions in memory and persists via iCloud Key-Value Store
2. All views receive TransactionStore via @EnvironmentObject
3. Balance is computed as sum of signed transaction amounts (income/sale = +, expense = -)
4. UI updates automatically when TransactionStore.transactions changes via @Published

#### View Architecture
All legacy view iterations have been removed from the codebase. The current views are:
- **BalanceView**: Displays current balance with formatted currency
- **TransactionListView**: Shows transactions with search and pagination (50 limit)
- **TransactionEntryView**: Form for adding new transactions
- **EditTransactionView**: Form for editing existing transactions
- **SettingsView**: Settings with SQLite export and statistics (includes ShareSheet helper)
- **ReportsView**: Analytics with time filtering (Week, Month, Quarter, Year, All Time)
- **SimpleCharts.swift**: Custom chart components (line, bar, pie)

#### Key Services
- **SQLiteTransactionExporter**: Exports transactions to SQLite database with proper schema and summary views

### Critical Implementation Details

#### Persistence Layer
- **iCloud Sync**: Uses NSUbiquitousKeyValueStore.default with local UserDefaults fallback
- **Data Format**: JSON encoding/decoding of Transaction array
- **Sync Strategy**: Saves to both iCloud and local, loads iCloud first with local fallback
- **Storage Key**: "savedTransactions" in both stores

#### Transaction Management
- **Balance Calculation**: Real-time sum of all transaction.signedAmount values (income/sale positive, expense negative)
- **Search**: Filter by description or transaction type
- **Pagination**: Shows first 50 transactions with "Show All" expansion
- **Export**: Full SQLite export with transactions table and account_summary view
- **Edit/Delete**: Transactions maintain their UUID through edits for proper tracking

#### Charts Implementation
- **Custom Drawing**: Uses SwiftUI Path and GeometryReader (not the Charts framework)
- **Dual Y-Axes**: Balance on left axis, Income/Expenses on right axis (always starts at 0)
- **Historical Context**: When filtering by time range, balance chart calculates initial balance from ALL transactions before the period, not just filtered transactions
- **Date Format**: Compact format (e.g., "10/1") to prevent X-axis crowding

#### iCloud Configuration
The app requires proper entitlement configuration in SimpleAccount.entitlements:
- `com.apple.developer.ubiquity-kvstore-identifier` must be set to `$(TeamIdentifierPrefix)$(CFBundleIdentifier)`
- `com.apple.developer.icloud-services` includes CloudKit and CloudDocuments
- Key-value storage capability enabled (not full CloudKit)

### Development Notes
- **SwiftData was abandoned** - All SwiftData models and services have been removed
- **Clean codebase** - All legacy view iterations have been deleted; only the current production views remain
- **Performance optimization** via transaction list pagination for large datasets
- **Export functionality** creates professional SQLite databases with summary views
- **UserDefaultsTransaction.swift** contains both the Transaction model and TransactionStore in a single file