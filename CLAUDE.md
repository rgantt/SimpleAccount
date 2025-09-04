# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SimpleAccount is a personal budgeting iOS app built with SwiftUI that functions as a single-account accounting system for tracking "spending money." The app uses double-entry bookkeeping principles while presenting a simple interface for recording income, expenses, and sales.

## Commands

### Build and Run
```bash
# Open the project in Xcode
open SimpleAccount.xcodeproj

# Build from command line
xcodebuild -scheme SimpleAccount -destination 'platform=iOS Simulator,name=iPhone 16' build

# Build for device
xcodebuild -scheme SimpleAccount build

# Run tests
xcodebuild -scheme SimpleAccount test
```

## Architecture

### Data Persistence Strategy
The app uses **NSUbiquitousKeyValueStore + UserDefaults** for data persistence, NOT SwiftData (which had reliability issues). The core data model is:
- **Transaction** struct (Codable) with amount, description, type, and date
- **TransactionStore** (@ObservableObject) manages all transactions and persistence
- **TxType** enum: income, expense, sale

### Core Application Structure

#### App Entry Point
- **SimpleAccountApp.swift**: Creates and provides TransactionStore via @EnvironmentObject
- **ContentView.swift**: TabView with Balance, Reports, and Settings tabs

#### Data Flow
1. **TransactionStore** holds all transactions in memory and persists via iCloud Key-Value Store
2. All views receive TransactionStore via @EnvironmentObject  
3. Balance is computed as sum of signed transaction amounts (income/sale = +, expense = -)
4. UI updates automatically when TransactionStore.transactions changes

#### View Architecture
**Active Views** (currently used):
- **WorkingBalanceView**: Displays current balance
- **WorkingTransactionList**: Shows transactions with search and pagination (50 limit)
- **WorkingTransactionEntry**: Form for adding new transactions
- **WorkingSettingsView**: Settings with SQLite export functionality
- **ReportsView**: Analytics with time filtering and basic charts

**Legacy Views** (unused): Multiple iterations exist from development (BalanceView, SimpleBalanceView, etc.) - these can be removed.

#### Key Services  
- **SQLiteTransactionExporter**: Exports transactions to SQLite database with proper schema
- **SimpleCharts.swift**: Custom chart components (line, bar, pie) since Charts framework wasn't used

### Critical Implementation Details

#### Persistence Layer
- **iCloud Sync**: Uses NSUbiquitousKeyValueStore.default with local UserDefaults fallback
- **Data Format**: JSON encoding/decoding of Transaction array
- **Sync Strategy**: Saves to both iCloud and local, loads iCloud first with local fallback

#### Transaction Management
- **Balance Calculation**: Real-time sum of all transaction.signedAmount values
- **Search**: Filter by description or transaction type
- **Pagination**: Shows first 50 transactions with "Show All" expansion
- **Export**: Full SQLite export with transactions table and account_summary view

#### iCloud Configuration Required
The app requires iCloud Key-value storage capability in Xcode project settings:
1. Add "iCloud" capability
2. Enable "Key-value storage" (not CloudKit)

### Development Notes
- **SwiftData was abandoned** due to fundamental data persistence failures
- **Multiple model iterations exist** - the working implementation uses UserDefaultsTransaction.swift
- **Performance optimization** via transaction list pagination for large datasets
- **Export functionality** creates professional SQLite databases with summary views