# RBP Flutter Migration Plan â€” Complete Implementation Guide

> **Purpose:** This document is a fully self-contained, exhaustive specification for an AI agent (Codex or similar) to implement the Flutter/Dart port of the RBP (Rivas Budget Planning) personal finance app. Every screen, widget, database table, business logic rule, color, and interaction is described in enough detail to produce a 1:1 functional replica. **This app targets THREE platforms from a single codebase: Android (mobile), Windows (desktop), and Web (browser).**

---

## TABLE OF CONTENTS

1. [Project Overview](#1-project-overview)
2. [Technology Stack](#2-technology-stack)
3. [Project Structure](#3-project-structure)
4. [Database Schema (SQLite)](#4-database-schema-sqlite)
5. [Data Models (Dart Classes)](#5-data-models-dart-classes)
6. [Database Service Layer](#6-database-service-layer)
7. [Business Logic / Finance Service](#7-business-logic--finance-service)
8. [Navigation & App Shell](#8-navigation--app-shell)
9. [Screen 1: Dashboard (Resumen)](#9-screen-1-dashboard-resumen)
10. [Screen 2: Income (Ingresos)](#10-screen-2-income-ingresos)
11. [Screen 3: New Expense (Nuevo Gasto)](#11-screen-3-new-expense-nuevo-gasto)
12. [Screen 4: Fixed Payments (Pagos Fijos)](#12-screen-4-fixed-payments-pagos-fijos)
13. [Screen 5: Loans (PrÃ©stamos)](#13-screen-5-loans-prÃ©stamos)
14. [Screen 6: Savings (Ahorro)](#14-screen-6-savings-ahorro)
15. [Screen 7: Settings (ConfiguraciÃ³n)](#15-screen-7-settings-configuraciÃ³n)
16. [Dialogs & Modals](#16-dialogs--modals)
17. [PDF Report Generation](#17-pdf-report-generation)
18. [CSV Export](#18-csv-export)
19. [Backup & Restore System](#19-backup--restore-system)
20. [Period Logic (Quincenal/Mensual)](#20-period-logic-quincenalmensual)
21. [Theme, Colors, Typography & App Visual Style](#21-theme-colors-typography--app-visual-style)
22. [State Management](#22-state-management)
23. [License & Activation System](#23-license--activation-system)
24. [Business Model & Revenue Flow](#24-business-model--revenue-flow)
25. [Multi-Platform Architecture & Distribution](#25-multi-platform-architecture--distribution)
26. [Scalability Architecture](#26-scalability-architecture)
27. [Firebase Integration (Phase 2)](#27-firebase-integration-phase-2)
28. [AdMob Integration (Phase 2)](#28-admob-integration-phase-2)
29. [In-App Purchases (Phase 2)](#29-in-app-purchases-phase-2)
30. [Testing Strategy](#30-testing-strategy)
31. [Build & Release (Multi-Platform)](#31-build--release-multi-platform)
32. [Implementation Order & Milestones](#32-implementation-order--milestones)

---

## 1. PROJECT OVERVIEW

**RBP (Rivas Budget Planning)** is a personal finance application currently built with Python + Flet (Flutter-based UI framework) + SQLite. It tracks income, expenses, fixed payments, loans, and savings on a quincenal (bi-weekly/fortnightly) or monthly cycle. The currency is RD$ (Dominican Peso).

### Target Platforms (MANDATORY â€” all three from one codebase):
| Platform | Target | Distribution Channel |
|----------|--------|---------------------|
| **Android** (mobile) | API 21+ (Android 5.0+) | Google Play Store |
| **Windows** (desktop) | Windows 10/11 x64 | Direct download (.exe/.msix) + Microsoft Store |
| **Web** (browser) | Chrome, Firefox, Edge, Safari | Firebase Hosting or Vercel |

**CRITICAL:** The UI must be **responsive** â€” it must adapt its layout to phone screens (360-428dp wide), tablet screens (600-900dp), desktop windows (1024px+), and browser windows. Use `LayoutBuilder` and breakpoints (see Section 25).

### App Identity:
- **App Name:** RBP - Rivas Budget Planning
- **Package Name (Android):** `com.rivasbudget.rbp`
- **Bundle ID (future iOS):** `com.rivasbudget.rbp`
- **Windows App ID:** `com.rivasbudget.rbp`
- **Target Audience:** Dominican Republic users managing personal finances (Spanish-only UI)
- **Business Model:** Freemium (free with ads + premium subscription). See Section 24.
- **License System:** Machine-ID based activation for desktop. See Section 23.

### Current features to replicate:
- Dashboard with financial summary cards and period navigation
- Quincenal (1st-15th / 16th-end) OR monthly period modes
- Customizable paydays for both modes
- Custom quincena date ranges (override standard dates)
- Salaries: base salary + per-period overrides
- Expense tracking with multi-category support and source (salary or savings)
- Fixed/recurring payments with due dates and paid/unpaid status tracking
- Loans given to people with deduction options (none, expense, savings)
- Savings: deposits, withdrawals, extra contributions, savings goals with progress bars
- Extra income tracking
- PDF report generation with styled header, tables, and branding
- CSV export
- Backup and restore (SQLite file copy)
- Category management (create, rename, delete with usage validation)
- Configurable settings: period mode, paydays, auto-export, beta updates
- Pie chart visualization of expenses by category
- Period closing alert with optional auto-export
- Recent expenses list in dashboard (includes paid fixed payments shown in green)

### NEW features to add in this Flutter version:
- **License/activation system** for desktop distribution (see Section 23)
- **AdMob ads** in free tier (banner + interstitial) (see Section 28)
- **In-app purchases** for premium subscription (see Section 29)
- **Responsive multi-platform UI** that adapts to mobile, desktop, and web (see Section 25)
- **Cloud sync** via Firebase (Phase 2) (see Section 27)

---

## 2. TECHNOLOGY STACK

### Flutter App â€” Phase 1 (Core â€” ALL platforms)
| Component | Package | Version | Purpose |
|-----------|---------|---------|---------|
| Framework | Flutter SDK | **>=3.24.0** | Multi-platform UI framework |
| Language | Dart | **>=3.5.0** | Programming language |
| Local DB (mobile) | `sqflite` | ^2.3.3 | SQLite for Android |
| Local DB (desktop/web) | `sqflite_common_ffi_web` + `sqflite_common_ffi` | ^0.4.0 / ^2.3.3 | SQLite for Windows & Web |
| Path util | `path_provider` | ^2.1.4 | App documents directory |
| Path join | `path` | ^1.9.0 | Cross-platform path manipulation |
| State Mgmt | `provider` | ^6.1.2 | ChangeNotifier-based state management |
| Charts | `fl_chart` | ^0.69.0 | Pie charts, bar charts |
| PDF gen | `pdf` | ^3.11.1 | Generate PDF documents (dart:pdf) |
| PDF preview | `printing` | ^5.13.3 | Preview and print/share PDFs |
| CSV | `csv` | ^6.0.0 | CSV encoding/decoding |
| File sharing | `share_plus` | ^10.0.0 | Share files (mobile) / save (desktop) |
| File picker | `file_picker` | ^8.1.2 | Pick files for import/restore |
| Date picker | Flutter built-in `showDatePicker` | â€” | Material date picker |
| Intl/format | `intl` | ^0.19.0 | Date/number formatting (month names) |
| Icons | Material Icons (built-in) | â€” | All UI icons |
| Window mgmt | `window_manager` | ^0.4.2 | Desktop window size, title, min size |
| URL launcher | `url_launcher` | ^6.3.0 | Open links in browser |
| Package info | `package_info_plus` | ^8.0.0 | App version for about/updates |

### Phase 1 â€” License & Activation System (Desktop only)
| Component | Package | Version | Purpose |
|-----------|---------|---------|---------|
| Device ID | `device_info_plus` | ^10.1.2 | Get hardware fingerprint (CPU ID, disk serial, etc.) |
| Crypto | `crypto` | ^3.0.5 | SHA-256 hash for machine ID + license key validation |
| Secure storage | `flutter_secure_storage` | ^9.2.2 | Store activation key securely on device |
| Platform check | `universal_platform` | ^1.1.0 | Detect current platform (mobile/desktop/web) |

### Phase 1 â€” Platform-Specific
| Component | Package | Purpose |
|-----------|---------|---------|
| Web support | `flutter_web_plugins` | Built-in web platform support |
| Desktop tray | `system_tray` (optional) | System tray icon on Windows |
| Windows MSIX | `msix` | ^3.16.8 | Package Windows app as MSIX for Store |

### Phase 2 â€” Monetization & Cloud
| Component | Package | Version | Purpose |
|-----------|---------|---------|---------|
| Firebase Core | `firebase_core` | ^3.6.0 | Firebase initialization |
| Auth | `firebase_auth` | ^5.3.1 | Email/password + Google Sign-In |
| Cloud DB | `cloud_firestore` | ^5.4.4 | Cloud data sync |
| Analytics | `firebase_analytics` | ^11.3.3 | Usage tracking |
| Crashlytics | `firebase_crashlytics` | ^4.1.3 | Crash reporting |
| Ads | `google_mobile_ads` | ^5.2.0 | Banner + interstitial ads (Android only) |
| IAP | `in_app_purchase` | ^3.2.0 | Premium subscription (Android + Web) |
| Notifications | `firebase_messaging` | ^15.1.3 | Push notifications |
| Local notifs | `flutter_local_notifications` | ^17.2.3 | Scheduled local notifications |
| Remote Config | `firebase_remote_config` | ^5.1.3 | Feature flags, dynamic config |
| Google Sign-In | `google_sign_in` | ^6.2.1 | Google account authentication |

### Development Tools
| Tool | Purpose |
|------|---------|
| `flutter_launcher_icons` ^0.14.1 | Generate app icons for all platforms |
| `flutter_lints` ^4.0.0 | Dart linting rules |
| `build_runner` ^2.4.12 | Code generation (if needed) |
| `flutter_test` (built-in) | Unit + widget testing |
| `integration_test` (built-in) | End-to-end testing |
| Android Studio / VS Code | IDE |
| Chrome DevTools | Web debugging |

### `pubspec.yaml` â€” EXACT Phase 1 dependencies:
```yaml
name: rbp_flutter
description: RBP - Rivas Budget Planning. App de finanzas personales.
version: 1.0.0+1
publish_to: 'none'

environment:
  sdk: '>=3.5.0 <4.0.0'
  flutter: '>=3.24.0'

dependencies:
  flutter:
    sdk: flutter
  # Database
  sqflite: ^2.3.3
  sqflite_common_ffi: ^2.3.3
  sqflite_common_ffi_web: ^0.4.0
  path_provider: ^2.1.4
  path: ^1.9.0
  # State management
  provider: ^6.1.2
  # UI
  fl_chart: ^0.69.0
  intl: ^0.19.0
  # File export
  pdf: ^3.11.1
  printing: ^5.13.3
  csv: ^6.0.0
  share_plus: ^10.0.0
  file_picker: ^8.1.2
  # License system
  device_info_plus: ^10.1.2
  crypto: ^3.0.5
  flutter_secure_storage: ^9.2.2
  universal_platform: ^1.1.0
  # Desktop
  window_manager: ^0.4.2
  # Utilities
  url_launcher: ^6.3.0
  package_info_plus: ^8.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  flutter_launcher_icons: ^0.14.1
  msix: ^3.16.8

flutter:
  uses-material-design: true
  assets:
    - assets/icon.png
    - assets/Untitled.png

flutter_launcher_icons:
  android: true
  ios: false
  windows:
    generate: true
  image_path: "assets/icon.png"

msix_config:
  display_name: RBP - Rivas Budget Planning
  publisher_display_name: Rivas Budget Planning
  identity_name: com.rivasbudget.rbp
  msix_version: 1.0.0.0
  logo_path: assets/icon.png
```

---

## 3. PROJECT STRUCTURE

```
rbp_flutter/
â”œâ”€â”€ android/
â”œâ”€â”€ windows/
â”œâ”€â”€ web/
â”œâ”€â”€ lib/
â”‚   â”œâ”€â”€ main.dart                         # Entry point, platform init, DB init
â”‚   â”œâ”€â”€ app.dart                          # MaterialApp, theme, routes
â”‚   â”œâ”€â”€ config/
â”‚   â”‚   â”œâ”€â”€ constants.dart                # Colors, default values, strings
â”‚   â”‚   â”œâ”€â”€ breakpoints.dart              # Responsive layout breakpoints
â”‚   â”‚   â””â”€â”€ platform_config.dart          # Platform-specific configurations
â”‚   â”œâ”€â”€ data/
â”‚   â”‚   â”œâ”€â”€ database/
â”‚   â”‚   â”‚   â”œâ”€â”€ database_helper.dart      # SQLite init, migrations, raw queries
â”‚   â”‚   â”‚   â””â”€â”€ tables.dart               # SQL CREATE statements as constants
â”‚   â”‚   â”œâ”€â”€ models/
â”‚   â”‚   â”‚   â”œâ”€â”€ user.dart
â”‚   â”‚   â”‚   â”œâ”€â”€ category.dart
â”‚   â”‚   â”‚   â”œâ”€â”€ expense.dart
â”‚   â”‚   â”‚   â”œâ”€â”€ fixed_payment.dart
â”‚   â”‚   â”‚   â”œâ”€â”€ fixed_payment_record.dart
â”‚   â”‚   â”‚   â”œâ”€â”€ loan.dart
â”‚   â”‚   â”‚   â”œâ”€â”€ extra_income.dart
â”‚   â”‚   â”‚   â”œâ”€â”€ savings.dart
â”‚   â”‚   â”‚   â”œâ”€â”€ savings_goal.dart
â”‚   â”‚   â”‚   â”œâ”€â”€ budget.dart
â”‚   â”‚   â”‚   â”œâ”€â”€ salary_override.dart
â”‚   â”‚   â”‚   â”œâ”€â”€ user_setting.dart
â”‚   â”‚   â”‚   â”œâ”€â”€ custom_quincena.dart
â”‚   â”‚   â”‚   â””â”€â”€ license_info.dart         # License data model
â”‚   â”‚   â””â”€â”€ repositories/
â”‚   â”‚       â”œâ”€â”€ user_repository.dart
â”‚   â”‚       â”œâ”€â”€ category_repository.dart
â”‚   â”‚       â”œâ”€â”€ expense_repository.dart
â”‚   â”‚       â”œâ”€â”€ fixed_payment_repository.dart
â”‚   â”‚       â”œâ”€â”€ loan_repository.dart
â”‚   â”‚       â”œâ”€â”€ income_repository.dart
â”‚   â”‚       â”œâ”€â”€ savings_repository.dart
â”‚   â”‚       â””â”€â”€ settings_repository.dart
â”‚   â”œâ”€â”€ services/
â”‚   â”‚   â”œâ”€â”€ finance_service.dart          # All business logic (port of FinanceService)
â”‚   â”‚   â”œâ”€â”€ backup_service.dart           # Backup/restore SQLite file
â”‚   â”‚   â”œâ”€â”€ pdf_service.dart              # PDF report generation
â”‚   â”‚   â”œâ”€â”€ csv_service.dart              # CSV export
â”‚   â”‚   â””â”€â”€ license_service.dart          # Machine-ID licensing (desktop)
â”‚   â”œâ”€â”€ providers/
â”‚   â”‚   â”œâ”€â”€ finance_provider.dart         # ChangeNotifier wrapping FinanceService
â”‚   â”‚   â””â”€â”€ settings_provider.dart        # Period mode, paydays, etc.
â”‚   â”œâ”€â”€ ui/
â”‚   â”‚   â”œâ”€â”€ screens/
â”‚   â”‚   â”‚   â”œâ”€â”€ home_screen.dart          # Tab scaffold with all 7 tabs
â”‚   â”‚   â”‚   â”œâ”€â”€ dashboard_tab.dart        # Screen 1
â”‚   â”‚   â”‚   â”œâ”€â”€ income_tab.dart           # Screen 2
â”‚   â”‚   â”‚   â”œâ”€â”€ expense_tab.dart          # Screen 3
â”‚   â”‚   â”‚   â”œâ”€â”€ fixed_payments_tab.dart   # Screen 4
â”‚   â”‚   â”‚   â”œâ”€â”€ loans_tab.dart            # Screen 5
â”‚   â”‚   â”‚   â”œâ”€â”€ savings_tab.dart          # Screen 6
â”‚   â”‚   â”‚   â”œâ”€â”€ settings_tab.dart         # Screen 7
â”‚   â”‚   â”‚   â””â”€â”€ activation_screen.dart    # License activation (desktop only)
â”‚   â”‚   â”œâ”€â”€ widgets/
â”‚   â”‚   â”‚   â”œâ”€â”€ stat_card.dart            # Reusable summary card
â”‚   â”‚   â”‚   â”œâ”€â”€ expense_list_item.dart    # Row in recent expenses
â”‚   â”‚   â”‚   â”œâ”€â”€ fixed_payment_item.dart   # Row in fixed payments list
â”‚   â”‚   â”‚   â”œâ”€â”€ loan_item.dart            # Row in loans list
â”‚   â”‚   â”‚   â”œâ”€â”€ income_item.dart          # Row in income list
â”‚   â”‚   â”‚   â”œâ”€â”€ savings_goal_item.dart    # Row with progress bar
â”‚   â”‚   â”‚   â”œâ”€â”€ category_item.dart        # Row in settings category list
â”‚   â”‚   â”‚   â”œâ”€â”€ pie_chart_widget.dart     # Expense by category chart
â”‚   â”‚   â”‚   â”œâ”€â”€ period_nav_bar.dart       # Prev/Next/Today/Calendar/PDF/CSV buttons
â”‚   â”‚   â”‚   â””â”€â”€ responsive_layout.dart    # Responsive wrapper (mobile/tablet/desktop)
â”‚   â”‚   â””â”€â”€ dialogs/
â”‚   â”‚       â”œâ”€â”€ edit_expense_dialog.dart
â”‚   â”‚       â”œâ”€â”€ edit_fixed_payment_dialog.dart
â”‚   â”‚       â”œâ”€â”€ edit_loan_dialog.dart
â”‚   â”‚       â”œâ”€â”€ edit_income_dialog.dart
â”‚   â”‚       â”œâ”€â”€ edit_goal_dialog.dart
â”‚   â”‚       â”œâ”€â”€ custom_quincena_dialog.dart
â”‚   â”‚       â”œâ”€â”€ rename_category_dialog.dart
â”‚   â”‚       â””â”€â”€ confirm_dialog.dart
â”‚   â””â”€â”€ utils/
â”‚       â”œâ”€â”€ currency_formatter.dart       # format_currency("RD$", amount)
â”‚       â”œâ”€â”€ date_helpers.dart             # quincenal cycle logic, ranges, labels
â”‚       â”œâ”€â”€ validators.dart               # Form validation helpers
â”‚       â””â”€â”€ platform_utils.dart           # Platform detection helpers
â”œâ”€â”€ assets/
â”‚   â”œâ”€â”€ icon.png                          # App icon (for PDF header + launcher)
â”‚   â””â”€â”€ Untitled.png                      # Logo
â”œâ”€â”€ test/
â”‚   â”œâ”€â”€ unit/
â”‚   â”‚   â”œâ”€â”€ finance_service_test.dart
â”‚   â”‚   â”œâ”€â”€ date_helpers_test.dart
â”‚   â”‚   â”œâ”€â”€ database_test.dart
â”‚   â”‚   â””â”€â”€ license_service_test.dart
â”‚   â””â”€â”€ widget/
â”‚       â”œâ”€â”€ dashboard_tab_test.dart
â”‚       â””â”€â”€ stat_card_test.dart
â”œâ”€â”€ pubspec.yaml
â””â”€â”€ README.md
```

---

## 4. DATABASE SCHEMA (SQLite)

Replicate these tables exactly. The schema must be identical to enable data migration from the Python app.

### Table: `users`
```sql
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    email TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT 1
);
```

### Table: `categories`
```sql
CREATE TABLE IF NOT EXISTS categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    color TEXT,
    icon TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    UNIQUE(user_id, name)
);
```

### Table: `budgets`
```sql
CREATE TABLE IF NOT EXISTS budgets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    category_id INTEGER NOT NULL,
    amount REAL NOT NULL,
    quincenal_cycle INTEGER NOT NULL,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (category_id) REFERENCES categories(id),
    UNIQUE(user_id, category_id, quincenal_cycle, year, month)
);
```

### Table: `expenses`
```sql
CREATE TABLE IF NOT EXISTS expenses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    amount REAL NOT NULL,
    description TEXT NOT NULL,
    date DATE NOT NULL,
    quincenal_cycle INTEGER NOT NULL,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```
**Status values:** `'pending'`, `'completed_salary'`, `'completed_savings'`

### Table: `expense_categories`
```sql
CREATE TABLE IF NOT EXISTS expense_categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    expense_id INTEGER NOT NULL,
    category_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id),
    UNIQUE(expense_id, category_id)
);
```

### Table: `fixed_payments`
```sql
CREATE TABLE IF NOT EXISTS fixed_payments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    amount REAL NOT NULL,
    category_id INTEGER,
    due_day INTEGER NOT NULL,        -- 0 = no fixed date (manual payment)
    frequency TEXT DEFAULT 'monthly',
    is_active BOOLEAN DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (category_id) REFERENCES categories(id)
);
```
**Important:** `due_day = 0` means "no fixed date" â€” user marks it paid manually.

### Table: `fixed_payment_records`
```sql
CREATE TABLE IF NOT EXISTS fixed_payment_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    fixed_payment_id INTEGER NOT NULL,
    expense_id INTEGER,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    quincenal_cycle INTEGER,
    status TEXT DEFAULT 'pending',    -- 'pending' | 'paid'
    paid_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (fixed_payment_id) REFERENCES fixed_payments(id),
    FOREIGN KEY (expense_id) REFERENCES expenses(id)
);
```

### Table: `extra_income`
```sql
CREATE TABLE IF NOT EXISTS extra_income (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    amount REAL NOT NULL,
    description TEXT NOT NULL,
    date DATE NOT NULL,
    income_type TEXT DEFAULT 'bonus',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### Table: `savings`
```sql
CREATE TABLE IF NOT EXISTS savings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    total_saved REAL DEFAULT 0,
    last_quincenal_savings REAL,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    quincenal_cycle INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    UNIQUE(user_id, year, month, quincenal_cycle)
);
```

### Table: `backups`
```sql
CREATE TABLE IF NOT EXISTS backups (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    backup_file TEXT NOT NULL,
    backup_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### Table: `loans`
```sql
CREATE TABLE IF NOT EXISTS loans (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    person TEXT NOT NULL,
    amount REAL NOT NULL,
    description TEXT,
    date DATE NOT NULL,
    is_paid BOOLEAN DEFAULT 0,
    paid_date DATE,
    deduction_type TEXT DEFAULT 'ninguno',  -- 'ninguno' | 'gasto' | 'ahorro'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### Table: `savings_goals`
```sql
CREATE TABLE IF NOT EXISTS savings_goals (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    target_amount REAL NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### Table: `user_salary`
```sql
CREATE TABLE IF NOT EXISTS user_salary (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL UNIQUE,
    amount REAL NOT NULL DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### Table: `salary_overrides`
```sql
CREATE TABLE IF NOT EXISTS salary_overrides (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    cycle INTEGER NOT NULL,
    amount REAL NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    UNIQUE(user_id, year, month, cycle)
);
```

### Table: `user_period_mode`
```sql
CREATE TABLE IF NOT EXISTS user_period_mode (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL UNIQUE,
    mode TEXT NOT NULL DEFAULT 'quincenal',  -- 'quincenal' | 'mensual'
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### Table: `user_settings`
```sql
CREATE TABLE IF NOT EXISTS user_settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    setting_key TEXT NOT NULL,
    setting_value TEXT NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    UNIQUE(user_id, setting_key)
);
```
**Known setting keys:**
- `quincenal_pay_day_1` (default: `"1"`) â€” day of month for Q1 start
- `quincenal_pay_day_2` (default: `"16"`) â€” day of month for Q2 start
- `monthly_pay_day` (default: `"1"`) â€” day of month for monthly period start
- `auto_export_close_period` (default: `"0"`) â€” `"1"` = auto export PDF+CSV on period close
- `include_beta_updates` (default: `"0"`)
- `update_snoozed_version` â€” tag name of snoozed update
- `update_last_check_date_stable` â€” ISO date
- `update_last_check_date_beta` â€” ISO date
- `update_last_seen_version` â€” version tag
- `last_auto_export_key` â€” e.g. `"Q:2026-02-1"` or `"M:2026-02"`

### Table: `custom_quincena`
```sql
CREATE TABLE IF NOT EXISTS custom_quincena (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    cycle INTEGER NOT NULL,
    start_date TEXT NOT NULL,           -- 'YYYY-MM-DD'
    end_date TEXT NOT NULL,             -- 'YYYY-MM-DD'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    UNIQUE(user_id, year, month, cycle)
);
```

---

## 5. DATA MODELS (Dart Classes)

Each model must have:
- Named constructor from `Map<String, dynamic>` (for SQLite row conversion)
- `toMap()` method returning `Map<String, dynamic>` (for SQLite insert/update)
- All fields matching the DB columns exactly

### Example: `expense.dart`
```dart
class Expense {
  final int? id;
  final int userId;
  final double amount;
  final String description;
  final String date;         // 'YYYY-MM-DD'
  final int quincenalCycle;
  final String status;       // 'pending' | 'completed_salary' | 'completed_savings'
  final String? createdAt;
  final String? updatedAt;
  final String? categoryIds; // comma-separated IDs from JOIN, e.g. "1,3"

  Expense({
    this.id,
    required this.userId,
    required this.amount,
    required this.description,
    required this.date,
    required this.quincenalCycle,
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
    this.categoryIds,
  });

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String,
      date: map['date'] as String,
      quincenalCycle: map['quincenal_cycle'] as int,
      status: map['status'] as String? ?? 'pending',
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
      categoryIds: map['category_ids'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'amount': amount,
      'description': description,
      'date': date,
      'quincenal_cycle': quincenalCycle,
      'status': status,
    };
  }

  bool get isFromSavings =>
      status == 'completed_savings' || status == 'savings';

  List<int> get categoryIdList {
    if (categoryIds == null || categoryIds!.isEmpty) return [];
    return categoryIds!
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((s) => int.tryParse(s))
        .whereType<int>()
        .toList();
  }
}
```

**Create similar models for ALL tables listed in Section 4. Each model follows the same pattern.**

Key model-specific notes:
- `FixedPayment`: add computed `bool get hasNoFixedDate => dueDay <= 0;`
- `Loan`: add `bool get isPaid => is_paid == 1;` and `String get deductionType`
- `SavingsGoal`: add `double progressPercent(double totalSavings)` method
- `Category`: simple id, userId, name, color, icon
- `CustomQuincena`: startDate/endDate as Strings

---

## 6. DATABASE SERVICE LAYER

### `database_helper.dart`

```dart
class DatabaseHelper {
  static const _databaseName = 'finanzas.db';
  static const _databaseVersion = 1;

  // Singleton
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Execute ALL CREATE TABLE statements from Section 4
    // in a single batch
    await db.execute(usersTable);
    await db.execute(categoriesTable);
    // ... etc for all 15 tables
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle schema migrations here
  }

  // Generic query helpers
  Future<int> insert(String table, Map<String, dynamic> row) async { ... }
  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs, String? orderBy}) async { ... }
  Future<int> update(String table, Map<String, dynamic> values, {String? where, List<dynamic>? whereArgs}) async { ... }
  Future<int> delete(String table, {String? where, List<dynamic>? whereArgs}) async { ... }
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async { ... }
}
```

### Repository Pattern

Each repository encapsulates all DB operations for one entity. Example:

```dart
class ExpenseRepository {
  final DatabaseHelper _db;
  ExpenseRepository(this._db);

  Future<int> create(Expense expense, List<int> categoryIds) async { ... }
  Future<List<Expense>> getByCustomRange(int userId, String startDate, String endDate) async { ... }
  Future<void> update(int expenseId, {double? amount, String? description, String? date, String? status, List<int>? categoryIds}) async { ... }
  Future<void> delete(int expenseId) async { ... }
  Future<Expense?> getById(int expenseId) async { ... }
}
```

**Create repositories for:** Users, Categories, Expenses, FixedPayments, Loans, ExtraIncome, Savings, Settings (covers user_settings, user_period_mode, user_salary, salary_overrides, custom_quincena).

---

## 7. BUSINESS LOGIC / FINANCE SERVICE

Port the entire `FinanceService` class. This is the most critical file. It orchestrates all business rules.

### `finance_service.dart` â€” Complete method list

```dart
class FinanceService {
  final DatabaseHelper db;
  final UserRepository userRepo;
  final CategoryRepository categoryRepo;
  final ExpenseRepository expenseRepo;
  final FixedPaymentRepository fixedPaymentRepo;
  final LoanRepository loanRepo;
  final IncomeRepository incomeRepo;
  final SavingsRepository savingsRepo;
  final SettingsRepository settingsRepo;

  late int userId;

  // === INITIALIZATION ===
  Future<void> init() async { ... }  // ensure user & default categories

  // === CATEGORIES ===
  Future<List<Category>> getCategories();
  Future<void> addCategory(String name);
  Future<void> renameCategory(int categoryId, String newName);
  Future<void> deleteCategory(int categoryId);
  // RULE: deleteCategory must check usage in expense_categories AND fixed_payments
  // If used, throw exception with message "No se puede eliminar una categorÃ­a en uso."

  // === EXPENSES ===
  Future<void> addExpense(double amount, String description, int categoryId, String dateText, {String source = 'sueldo'});
  // RULE: if source == 'ahorro' â†’ status = 'completed_savings', else 'completed_salary'
  // RULE: cycle is determined by getCycleForDate(date)

  // === FIXED PAYMENTS ===
  Future<void> addFixedPayment(String name, double amount, int dueDay, int? categoryId, {bool noFixedDate = false});
  // RULE: if noFixedDate â†’ dueDay = 0
  Future<void> deleteFixedPayment(int paymentId);
  // RULE: soft delete â€” set is_active = 0
  Future<void> setFixedPaymentPaid(int paymentId, int year, int month, int cycle, bool paid);
  Future<List<FixedPaymentWithStatus>> getFixedPaymentsForPeriod(int year, int month, int cycle);
  // COMPLEX RULE (see Section 20 for full logic):
  // - Get all active fixed_payments for user
  // - Compute period range from get_period_range(year, month, cycle)
  // - For each fixed payment:
  //   - If due_day <= 0 (no fixed date): always include, check record status, never overdue
  //   - If due_day > 0: check if due date falls within period range
  //     - Iterate months between start and end of period
  //     - Create date(year, month, min(due_day, last_day_of_month))
  //     - If date is within [start_d, end_d], include it
  //     - default_status for payments WITH a due_day is "paid" (not "pending")
  //     - is_overdue = (due_date <= today)
  // - Sort by: (due_date == "" first), then due_date ascending, then name

  // === SAVINGS ===
  Future<void> addSavings(double amount);
  Future<void> addExtraSavings(double amount);      // adds to total without affecting period savings
  Future<double> getPeriodSavings(int year, int month, int cycle);
  Future<double> getTotalSavings();
  Future<bool> withdrawSavings(double amount);       // returns false if insufficient
  Future<void> addSavingsGoal(String name, double target);
  Future<List<SavingsGoal>> getSavingsGoals();
  Future<void> deleteSavingsGoal(int goalId);
  Future<void> updateSavingsGoal(int goalId, String name, double target);

  // === SALARY ===
  Future<void> setSalary(double amount);
  Future<double> getSalary();
  Future<void> setSalaryOverride(int year, int month, int cycle, double amount);
  Future<double?> getSalaryOverride(int year, int month, int cycle);
  Future<void> deleteSalaryOverride(int year, int month, int cycle);
  Future<double> getSalaryForPeriod(int year, int month, int cycle);
  // RULE: if override exists â†’ use override; else â†’ use base salary

  // === PERIOD MODE ===
  Future<void> setPeriodMode(String mode);   // 'quincenal' | 'mensual'
  Future<String> getPeriodMode();             // default 'quincenal'

  // === SETTINGS ===
  Future<void> setSetting(String key, String value);
  Future<String> getSetting(String key, {String defaultValue = ''});

  // === INCOME ===
  Future<void> addIncome(double amount, String description, String dateText);
  Future<List<ExtraIncome>> getIncomes(int year, int month, int cycle);
  Future<double> getTotalIncome(int year, int month, int cycle);
  Future<void> deleteIncome(int incomeId);

  // === LOANS ===
  Future<void> addLoan(String person, double amount, String description, String dateText, {String deductionType = 'ninguno'});
  Future<List<Loan>> getLoans({bool includePaid = false});
  Future<void> markLoanPaid(int loanId);
  Future<void> deleteLoan(int loanId);
  Future<double> getTotalUnpaidLoans();

  // === EDITING ===
  Future<void> updateExpense(int eid, double amount, String description, String dateText, int categoryId);
  Future<void> updateFixedPayment(int pid, String name, double amount, int dueDay, int? categoryId);
  Future<void> updateLoan(int lid, String person, double amount, String description, String deductionType);
  Future<void> updateIncome(int iid, double amount, String description, String dateText);

  // === PERIOD LOGIC ===
  (int, int) getQuincenalPaydays();
  // Returns (day1, day2) from settings, default (1, 16). If equal, forces day2 = 16 or 15.

  int getMonthlyPayday();
  // Returns day from setting, default 1.

  (String, String) getQuincenaRange(int year, int month, int cycle);
  // COMPLEX LOGIC â€” See Section 20

  (String, String) getPeriodRange(int year, int month, int cycle);
  // if mensual â†’ getMonthRangeByPayday; else â†’ getQuincenaRange

  int getCycleForDate(DateTime date);
  // if mensual â†’ always 1
  // else: check if date falls in Q1 range â†’ 1, otherwise â†’ 2

  // === CUSTOM QUINCENA ===
  Future<void> setCustomQuincena(int y, int m, int c, String start, String end);
  Future<Map<String, dynamic>?> getCustomQuincena(int y, int m, int c);
  Future<void> deleteCustomQuincena(int cqId);

  // === DASHBOARD ===
  Future<DashboardData> getDashboardData({int? year, int? month, int? cycle});
  // THIS IS THE CORE CALCULATION. See Section 9 for the exact data structure and formulas.

  // === REPORTS ===
  Future<String> generateReport(int year, int month, int cycle);  // returns file path
  Future<String> exportCsv(int year, int month, int cycle);       // returns file path
}
```

---

## 8. NAVIGATION & APP SHELL

### `home_screen.dart`

The app uses a **TabBar with 7 tabs** at the top (not bottom navigation).

```dart
TabBar / TabBarView with tabs:
  0: "Resumen"        icon: Icons.dashboard
  1: "Ingresos"       icon: Icons.attach_money
  2: "Nuevo gasto"    icon: Icons.add_circle_outline
  3: "Pagos fijos"    icon: Icons.repeat
  4: "PrÃ©stamos"      icon: Icons.money_off
  5: "Ahorro"         icon: Icons.savings
  6: "ConfiguraciÃ³n"  icon: Icons.settings
```

**Tab bar colors:**
- Selected tab label: `#1565C0` (primary blue)
- Unselected tab label: `#757575` (subtitle gray)
- Indicator: `#1565C0`

**App bar:** Row with logo image (36x36) + Text "Rivas Budget Planning" (size 14, color `#757575`)

**Page background:** `#FAFAFA`

---

## 9. SCREEN 1: DASHBOARD (RESUMEN)

### Layout (top to bottom):
1. **Period navigation bar** (Row)
2. **Row 1: 3 stat cards** (responsive â€” 3 columns on wide, stacked on narrow)
3. **Row 2: 3 stat cards**
4. **Label "Ãšltimos gastos"**
5. **Recent expenses list** (scrollable, inside bordered container)

### Period Navigation Bar
```
[< ChevronLeft] [Period Label Text] [ChevronRight >] [Hoy button]  [expand]  [Calendar icon] [GrÃ¡fico button] [PDF button] [CSV button]
```

- **Period label format (quincenal):** `"1-15 Feb 2026  (Q1)"` â€” shows actual day range from quincena range
- **Period label format (mensual):** `"1-28 Feb 2026  (Mensual)"`
- **Prev/Next:** In mensual mode, goes to prev/next month (cycle always 1). In quincenal, navigates Q1â†”Q2 and rolls months.
- **Hoy:** Resets to current period
- **Calendar icon:** Opens custom quincena dialog (only in quincenal mode)
- **GrÃ¡fico:** Opens pie chart in AlertDialog (820x520)
- **PDF/CSV:** Generates and opens/shares file

### Navigation logic (prev/next quincena):
```
_prev_q(y, m, c):
  if c == 2: return (y, m, 1)
  if m == 1: return (y-1, 12, 2)
  return (y, m-1, 2)

_next_q(y, m, c):
  if c == 1: return (y, m, 2)
  if m == 12: return (y+1, 1, 1)
  return (y, m+1, 1)
```

### Stat Cards (6 total, 2 rows of 3)

Each card is a `Container` with:
- padding: 16, borderRadius: 14, bg: `#FFFFFF`, border: 1px `#E0E0E0`
- Column: [Row([Icon(color: primary), Text(title, size:12, color: subtitle)]), ValueText]

**Row 1:**
| Card | Title | Icon | Value Format | Color |
|------|-------|------|-------------|-------|
| Dinero Inicial | "Dinero Inicial" | `Icons.account_balance_wallet` | `RD$XX,XXX.XX` | default (black) |
| Total Gastado | "Total Gastado" | `Icons.shopping_cart` | `RD$XX,XXX.XX` | `#E53935` (error red) |
| Ahorro Total | "Ahorro Total" | `Icons.savings` | `RD$XX,XXX.XX` | `#43A047` (success green) |

**Row 2:**
| Card | Title | Icon | Value Format | Color |
|------|-------|------|-------------|-------|
| Dinero Disponible | "Dinero Disponible" | `Icons.check_circle` | `RD$XX,XXX.XX` | `#43A047` if â‰¥0, `#E53935` if <0 |
| Promedio Diario | "Promedio Diario" | `Icons.calendar_view_day` | `RD$XX,XXX.XX` | default |
| PrÃ©stamos Pend. | "Prestamos Pend." | `Icons.money_off` | `RD$XX,XXX.XX` | `#FB8C00` (warning orange) |

**Value text:** size: 20, weight: BOLD

### Dashboard Calculations (DashboardData)

```dart
class DashboardData {
  final int year, month, cycle;
  final String periodMode;
  final double salary;
  final double extraIncome;
  final double dineroInicial;       // = salary + extraIncome - periodSavings
  final double totalExpenses;       // sum of ALL expenses in period
  final double totalExpensesSalary; // sum of expenses where status != 'completed_savings'
  final double totalExpensesSavings;// totalExpenses - totalExpensesSalary
  final double totalFixed;          // sum of fixed payment amounts WHERE is_paid == true
  final double totalLoans;          // total unpaid loans (ALL periods, not filtered)
  final double periodSavings;       // last_quincenal_savings for this period
  final double totalSavings;        // latest total_saved for user
  final double dineroDisponible;    // = dineroInicial - totalExpensesSalary - totalFixed - totalLoans
  final double avgDaily;            // average of daily expense totals
  final int expenseCount;
  final int fixedCount;
  final List<RecentItem> recentExpenses;     // max 20 items
  final List<FixedPaymentWithStatus> fixedPayments;
  final List<Expense> rawExpenses;
  final Map<int, String> categoriesById;
  final Map<int, double> catTotals;          // category_id â†’ total amount
  final (String, String) quincenaRange;
}
```

### Recent Expenses List

Combines **actual expenses** (up to 12) + **paid fixed payments** whose due date â‰¤ today.

For each `RecentItem`:
- **Type `expense`:** Normal row with edit/delete buttons
  - Background: `#F5F5F5`
  - Amount color: `#E53935` (red)
  - Shows: description, date + category string, amount
  - Buttons: Edit (pencil, blue) + Delete (trash, red)

- **Type `fixed_due`:** Fixed payment that is paid and due â‰¤ today
  - Background: `#FFF8E1` (light yellow)
  - Amount color: `#43A047` (green) when paid
  - Description format: `"Pago fijo: <name>"` or `"Pago fijo pagado: <name>"` if no fixed date
  - Shows calendar icon instead of edit/delete
  - Category text: `"Pago fijo"`

**IMPORTANT RULE for including fixed payments in recent list:**
- If `due_day <= 0` (no fixed date): include ONLY if `is_paid == true`, use today's date
- If `due_day > 0` and `due_date <= today`: include ONLY if `is_paid == true`
- Sort all items by date descending
- Take first 20

---

## 10. SCREEN 2: INCOME (INGRESOS)

### Layout: ResponsiveRow with 2 panels

**Left panel (7/12 width): Salary section**
- Title "Salario" (size 18, weight 600)
- TextField: "Salario base {mode_label} RD$" (hint: "25000"), width 260
- Button: "Guardar" (icon: save, bgcolor: primary blue)
- Subtitle: "Salario variable por quincena" (size 14, subtitle color)
- TextField: "Salario esta quincena (Q{c} {mm}/{yyyy}) RD$" (hint: "Opcional: monto solo para esta quincena"), width 320
- Buttons row: "Guardar quincena" (primary) + "Usar base" (outlined, resets override)
- Note text: In mensual mode, quincena salary fields are disabled
- Help text at bottom explaining the mode

**Right panel (5/12 width): Add income**
- Title "Agregar ingreso" (size 16, weight 600)
- TextField: "Monto RD$" (hint: "5000"), width 200
- TextField: "Descripcion" (hint: "Freelance"), width 300
- TextField: "Fecha" with calendar picker button, pre-filled today, width 180
- Button: "Agregar" (icon: add, bgcolor: success green)

**Below panels: Divider + "Ingresos extras" list**
- Bordered container with ListView
- Each income row: description (bold), date (subtitle), amount (green, bold), edit + delete buttons

### Validation rules:
- Salary: must be >= 0, numeric
- Income: amount > 0, description required, date valid YYYY-MM-DD format
- After save, clear fields and refresh

---

## 11. SCREEN 3: NEW EXPENSE (NUEVO GASTO)

### Layout: Simple form
- Title "Registrar gasto" (size 18, weight 600)
- TextField: "Monto RD$" (hint: "500"), width 260, number keyboard
- TextField: "DescripciÃ³n" (hint: "Supermercado"), width 320
- TextField: "Fecha" + calendar picker, pre-filled today, width 200
- Dropdown: "CategorÃ­a" â€” populated from categories
- Dropdown: "Descontar de" â€” options: "Sueldo del perÃ­odo" (value: "sueldo"), "Ahorro total" (value: "ahorro"), default: "sueldo"
- Button: "Guardar gasto" (icon: save, bgcolor: primary)

### Business logic on save:
1. Validate all fields filled, amount > 0, date valid
2. If source == "ahorro":
   - Call `withdrawSavings(amount)` â€” if returns false â†’ show "Fondos insuficientes en ahorro." error
   - If withdraw succeeds but expense create fails â†’ rollback by adding savings back
3. Create expense with status `completed_savings` if ahorro, `completed_salary` if sueldo
4. **After successful save:** Clear ALL fields (amount="", description="", date=today, category=null, source="sueldo")
5. Refresh dashboard

---

## 12. SCREEN 4: FIXED PAYMENTS (PAGOS FIJOS)

### Layout:
- Title "Pagos fijos" (size 18, weight 600)
- **Fixed payments list** (scrollable, bordered container, expand)
- Divider
- Title "Agregar pago fijo" (size 16, weight 600)
- Form fields + save button

### Add form:
- TextField: "Nombre" (hint: "Netflix"), width 260
- TextField: "Monto RD$" (hint: "270"), width 200, number
- TextField: "Fecha (dia del mes)" (hint: "1-31"), width 170, number
  - DISABLED when checkbox is checked
- Checkbox: "Sin fecha fija (marcar pagado manualmente)" â€” default unchecked
- Dropdown: "CategorÃ­a (opc.)" â€” optional category
- Button: "Guardar" (icon: save, bgcolor: primary)

### Fixed payment list item:
Each row shows:
- Name (bold), payment type + due info (subtitle)
  - If no fixed date: "Pago manual Sin fecha fija"
  - If fixed date: "Fecha {due_date}" (ISO string)
- Status badge (Container with border_radius 6, colored background):
  - `"PAGADO"` â€” green (`#43A047`)
  - `"PENDIENTE"` â€” orange (`#FB8C00`)
  - `"NO PAGADO"` â€” red (`#E53935`) â€” only for overdue + not paid
- Amount (bold), red if overdue and unpaid
- Action buttons:
  - **Toggle paid/unpaid button** (only shown if no_fixed_date OR is_overdue):
    - No fixed date: check/undo icon
    - Overdue: check(green)/remove(red) icon
  - Edit (pencil, blue)
  - Delete (trash, red)

### Status logic:
```
if no_fixed_date:
    status_text = paid ? "PAGADO" : "PENDIENTE"
    status_color = paid ? green : orange
elif is_overdue && !paid:
    status_text = "NO PAGADO"
    status_color = red
else:
    status_text = paid ? "PAGADO" : "PENDIENTE"
    status_color = paid ? green : orange
```

---

## 13. SCREEN 5: LOANS (PRÃ‰STAMOS)

### Layout:
- Title "Dinero prestado" (size 18, weight 600)
- Loans list (scrollable, bordered)
- Divider
- Title "Nuevo prestamo" (size 16, weight 600)
- Add form

### Add form:
- TextField: "Persona" (hint: "Nombre"), width 260
- TextField: "Monto RD$" (hint: "500"), width 200, number
- TextField: "Motivo (opc.)" (hint: "gasolina"), width 320
- TextField: "Fecha" + calendar picker, pre-filled today, width 200
- Dropdown: "Descontar de..." â€” options:
  - "No descontar" (value: "ninguno") â€” default
  - "Descontar como gasto" (value: "gasto")
  - "Descontar del ahorro" (value: "ahorro")
- Button: "Guardar" (icon: save, bgcolor: primary)

### Deduction logic on save:
- If `"ahorro"`: Call `withdrawSavings(amount)`, fail if insufficient
- If `"gasto"`: Auto-create an expense with description `"Prestamo a {person}"`, category = "Otros" or "Prestamos" (first match), or last category as fallback

### Loan list item:
Each row shows:
- Person name (bold)
- Subtitle: `"{date}  Â·  {description}{deduction_label}"`
  - deduction_label: `" Â· Desc. gasto"` | `" Â· Desc. ahorro"` | `""` (for ninguno)
- Status badge: "PAGADO" (green) or "PENDIENTE" (orange)
- Amount (bold)
- Actions: Mark paid button (only if not paid), Edit, Delete

### Shows both paid and unpaid loans, sorted by: `is_paid ASC, date DESC`

---

## 14. SCREEN 6: SAVINGS (AHORRO)

### Layout:
- Title "Ahorro" (size 18, weight 600)
- **ResponsiveRow with 2 panels** (6/12 each):

**Left panel: "Ahorro de este perÃ­odo"**
- Label showing current period savings: `"Actual: RD$X,XXX.XX"` (size 12, subtitle)
- TextField: "Depositar en este perÃ­odo RD$" + "Depositar" button (green)

**Right panel: "Ahorro total"**
- Label: `"Disponible: RD$X,XXX.XX"` (size 12, subtitle)
- TextField: "Retirar del ahorro total RD$" + "Retirar" button (orange)
- TextField: "Aporte extra al ahorro total RD$" + "Aportar extra" button (primary blue)
- Note: "Este aporte suma al ahorro total y no descuenta del salario del perÃ­odo."

**Below: Divider + "Metas de ahorro" list + "Agregar meta" form**

### Savings goal list item:
Each row shows:
- Name (bold) + amount text `"RD$X / RD$Y"` (subtitle) + Edit/Delete buttons
- ProgressBar: value = min(totalSavings / targetAmount, 1.0)
  - Color: green if < 100%, primary if = 100%
  - Background: `#E0E0E0`
- Text: `"{pct}% completado"` â€” green if â‰¥ 100%, subtitle color otherwise

### Add goal form:
- TextField: "Nombre meta" (hint: "Viaje"), width 260
- TextField: "Meta RD$" (hint: "100000"), width 200, number
- Button: "Crear meta" (icon: flag, bgcolor: primary)

---

## 15. SCREEN 7: SETTINGS (CONFIGURACIÃ“N)

### Layout (scrollable column):
1. **Title** "ConfiguraciÃ³n" (size 18) + subtitle text
2. **Divider**
3. **"General" section**
   - Dropdown: "Frecuencia de reporte y salario" â€” "Quincenal" | "Mensual"
   - Switch: "ExportaciÃ³n automÃ¡tica al cerrar perÃ­odo"
   - Switch: "Incluir versiones beta en actualizaciones"
   - TextField: "DÃ­a cobro quincena 1" (hint: "1-31"), width 170
   - TextField: "DÃ­a cobro quincena 2" (hint: "1-31"), width 170
   - TextField: "DÃ­a cobro mensual" (hint: "1-31"), width 170
   - Help text explaining the days
   - Button: "Guardar configuraciÃ³n" (icon: save, primary)
   - Button: "Buscar actualizaciÃ³n" (outlined, icon: system_update, green color)
4. **Divider**
5. **"Respaldo y restauraciÃ³n" section**
   - Buttons: "Crear respaldo" (filled, primary) + "Restaurar Ãºltimo respaldo" (outlined)
   - Help text
6. **Divider**
7. **"CategorÃ­as" section**
   - TextField + "Agregar categorÃ­a" button (green)
   - Categories list (bordered container, scrollable)

### Category list item:
Each row: category name (text, expand) + Edit button (pencil, blue) + Delete button (trash, red)
- Edit opens rename dialog
- Delete validates usage first

### Validation on save general:
- Q1 and Q2 days must be different
- All days must be 1-31
- After save, reload entire UI

---

## 16. DIALOGS & MODALS

### Edit Expense Dialog
```
Title: "Editar gasto" (bold, primary color)
Fields:
  - Monto RD$ (pre-filled)
  - DescripciÃ³n (pre-filled)
  - Fecha + calendar picker (pre-filled)
  - CategorÃ­a dropdown (pre-selected)
Actions: [Cancelar] [Guardar]
```

### Edit Fixed Payment Dialog
```
Title: "Editar pago fijo"
Fields:
  - Nombre (pre-filled)
  - Monto RD$ (pre-filled)
  - DÃ­a (pre-filled, disabled if no_fixed_date)
  - Checkbox "Sin fecha fija" (pre-filled)
  - CategorÃ­a dropdown (pre-selected)
Actions: [Cancelar] [Guardar]
```

### Edit Loan Dialog
```
Title: "Editar prÃ©stamo"
Fields:
  - Persona (pre-filled)
  - Monto RD$ (pre-filled)
  - Motivo (pre-filled)
  - Descontar de dropdown (pre-selected)
Actions: [Cancelar] [Guardar]
```

### Edit Income Dialog
```
Title: "Editar ingreso"
Fields:
  - Monto RD$ (pre-filled)
  - DescripciÃ³n (pre-filled)
  - Fecha + calendar picker (pre-filled)
Actions: [Cancelar] [Guardar]
```

### Edit Savings Goal Dialog
```
Title: "Editar meta"
Fields:
  - Nombre meta (pre-filled)
  - Meta RD$ (pre-filled)
Actions: [Cancelar] [Guardar]
```

### Custom Quincena Dialog
```
Title: "Calendario de quincena"
Content:
  - Info text: "Quincena: Q{c} {Month} {year}"
  - Status text: "Rango personalizado activo âœ“" (green) or "Usando rango estÃ¡ndar" (gray)
  - Help text
  - TextField "Fecha inicio" + calendar picker (pre-filled with current range start)
  - TextField "Fecha fin" + calendar picker (pre-filled with current range end)
Actions: [Cerrar] [Restablecer] [Guardar]
```

### Rename Category Dialog
```
Title: "Renombrar categorÃ­a"
Fields:
  - Nuevo nombre (pre-filled with current name)
Actions: [Cancelar] [Guardar]
```

### Pie Chart Dialog
```
Title: "Gastos por categorÃ­a"
Content: Container 820x520 centered with PieChart + Legend
Actions: [Cerrar]
```

### Period Close Alert Dialog
```
Title: "Cierre de perÃ­odo" (modal)
Content:
  - "PerÃ­odo anterior ({label}) terminÃ³."
  - "Â¿Deseas generar el reporte PDF?"
Actions: [No] [Generar PDF]
```

### All dialogs follow this style:
- Title: `FontWeight.bold`, color `#1565C0`
- Primary action buttons: `FilledButton`, bgcolor `#1565C0`, icon `Icons.save`
- Cancel buttons: `TextButton`
- Actions alignment: `MainAxisAlignment.end`
- Content width: ~340

---

## 17. PDF REPORT GENERATION

Use the `pdf` package (`dart:pdf`). Replicate the existing PDF layout:

### PDF Structure:
1. **Header bar:** Full-width blue rectangle (color: RGB 21, 101, 192), height ~28pt
   - Logo image at left (x=10, y=4, h=20)
   - White text "RBP  -  Rivas Budget Planning" (Helvetica Bold 18, white)

2. **Period label** (centered, size 10)
3. **Generated date** (centered, size 10): `"Generado: DD/MM/YYYY HH:MM"`

4. **Section: "Resumen Financiero"** (blue bar header)
   - Key-value pairs: Salario, Ingresos extras, Ahorro total, Dinero inicial, Total gastos, Pagos fijos, Prestamos pend., Dinero disponible (bold value)

5. **Section: "Gastos"** (if any)
   - Table: Fecha | Descripcion | Categoria | Monto
   - Header row: light blue bg (#E3F2FD), bold font
   - Data rows: bordered cells

6. **Section: "Pagos Fijos"** (if any)
   - Table: Nombre | Fecha | Monto

7. **Section: "Prestamos Pendientes"** (if any, only unpaid)
   - Table: Persona | Descripcion | Monto

8. **Footer:** "RBP - Rivas Budget Planning | Generado automaticamente" (italic, size 8, gray)

### File naming:
- Quincenal: `reporte_{year}_{month:02d}_Q{cycle}.pdf`
- Mensual: `reporte_{year}_{month:02d}_M.pdf`

---

## 18. CSV EXPORT

Simple CSV with header row + expense data.

```csv
Fecha,Descripcion,Categoria,Monto
2026-02-15,Supermercado,"Comida",1500.00
```

### File naming:
- Quincenal: `gastos_{year}_{month:02d}_Q{cycle}.csv`
- Mensual: `gastos_{year}_{month:02d}_M.csv`

Encoding: UTF-8 with BOM (`utf-8-sig` equivalent in Dart).

---

## 19. BACKUP & RESTORE SYSTEM

### BackupService
```dart
class BackupService {
  final String dbPath;
  final String backupDir;

  Future<bool> createBackup();
  // Copies finanzas.db â†’ backups/finanzas_backup_{YYYYMMdd_HHmmss}.db

  Future<String?> getLatestBackup();
  // Returns path of most recent backup file, or null

  Future<bool> restoreBackup(String backupPath);
  // Copies backup file over finanzas.db
  // IMPORTANT: close DB connection before restoring, reopen after

  Future<void> cleanupOldBackups({int keepCount = 10});
  // Delete all backups except the {keepCount} most recent
}
```

On mobile, store backups in `getApplicationDocumentsDirectory()/backups/`.

---

## 20. PERIOD LOGIC (QUINCENAL/MENSUAL)

This is the most complex business logic. Port it exactly.

### Quincenal Paydays
Default: day1=1, day2=16. User-configurable.

### `getQuincenaRange(year, month, cycle)`:
```
1. Check for custom quincena first. If exists, return it.
2. Get paydays (d1, d2) from settings.
3. CASE A: d1 < d2 (normal â€” e.g., d1=1, d2=16):
   - Q1 range: date(y, m, d1) â†’ date(y, m, d2-1)
   - Q2 range: date(y, m, d2) â†’ date(next_y, next_m, d1) - 1 day
4. CASE B: d1 >= d2 (crossed â€” e.g., d1=30, d2=15):
   - Q1 range: date(prev_y, prev_m, d1) â†’ date(y, m, d2-1)
   - Q2 range: date(y, m, d2) â†’ date(y, m, d1-1)
```

All days are clamped to the last day of the respective month using `min(day, lastDayOfMonth)`.

### Monthly period:
```
getMonthRangeByPayday(year, month):
  start = date(y, m, payday)
  end = date(next_y, next_m, payday) - 1 day
```

### Cycle detection for a given date:
```
getCycleForDate(date):
  if mensual â†’ 1
  else:
    (startQ1, endQ1) = getQuincenaRange(date.year, date.month, 1)
    if startQ1 <= date <= endQ1 â†’ 1
    else â†’ 2
```

### Period label formatting:
```
_qlabel_smart(data):
  Extract start_day and end_day from quincena_range
  Quincenal: "{startDay}-{endDay} {MonthAbbr} {year}  (Q{cycle})"
  Mensual:   "{startDay}-{endDay} {MonthAbbr} {year}  (Mensual)"
```

Month abbreviations: `Ene, Feb, Mar, Abr, May, Jun, Jul, Ago, Sep, Oct, Nov, Dic`

---

## 21. THEME, COLORS, TYPOGRAPHY & APP VISUAL STYLE

### Color Palette
```dart
const kPrimary    = Color(0xFF1565C0);  // Blue â€” main accent
const kPrimaryL   = Color(0xFFE3F2FD);  // Light blue â€” table headers
const kCardBg     = Color(0xFFFFFFFF);  // White â€” card backgrounds
const kCardBorder = Color(0xFFE0E0E0);  // Light gray â€” card borders
const kSubtitle   = Color(0xFF757575);  // Gray â€” secondary text
const kSuccess    = Color(0xFF43A047);  // Green â€” positive values
const kError      = Color(0xFFE53935);  // Red â€” negative values, errors
const kWarn       = Color(0xFFFB8C00);  // Orange â€” warnings, pending
```

### Pie Chart Colors (in order):
```dart
const kPieColors = [
  Color(0xFF1565C0), Color(0xFF43A047), Color(0xFFE53935),
  Color(0xFFFB8C00), Color(0xFF8E24AA), Color(0xFF00897B),
  Color(0xFFF4511E), Color(0xFF3949AB), Color(0xFFC0CA33),
  Color(0xFF6D4C41),
];
```

### Typography
- Card titles: size 12, color subtitle
- Card values: size 20, FontWeight.bold
- Section headers: size 18, FontWeight.w600
- Subsection headers: size 16, FontWeight.w600
- Labels/subtitles: size 14, FontWeight.w500
- Help text: size 12, color subtitle
- Tiny help text: size 11, color subtitle
- Status badges: size 11, white, FontWeight.bold

### Card common style:
```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: kCardBg,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: kCardBorder, width: 1),
  ),
)
```

### List item common style:
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  decoration: BoxDecoration(
    color: Color(0xFFF5F5F5),  // or #FFF8E1 for fixed_due items
    borderRadius: BorderRadius.circular(8),
  ),
)
```

### SnackBar style:
- Success: bgcolor green (#43A047), text white
- Error: bgcolor red (#E53935), text white
- Special messages:
  - If error message is a required-fields message â†’ show "Favor llenar los campos requeridos."
  - If error message is an invalid-data message â†’ show "Hay datos invÃ¡lidos. Verifica los campos e intenta de nuevo."

### Material Design 3 â€” Theme Configuration:
```dart
// In app.dart
MaterialApp(
  title: 'RBP - Rivas Budget Planning',
  debugShowCheckedModeBanner: false,
  theme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Color(0xFF1565C0),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Color(0xFFFAFAFA),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF757575),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Color(0xFFE0E0E0)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      isDense: true,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Color(0xFF1565C0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
)
```

### Visual Design Principles:
1. **Clean and professional** â€” White cards on light gray background, no gradients
2. **Information density** â€” Dashboard shows 6 stat cards + recent list. No wasted space.
3. **Color-coded feedback** â€” Green = positive/success, Red = negative/error, Orange = warning/pending, Blue = primary action
4. **Consistent spacing** â€” 16px padding inside cards, 12px between list items, 8px between buttons
5. **Readable typography** â€” Bold values stand out, subtle labels provide context
6. **Familiar patterns** â€” Standard Material 3 components (TextField, DropdownButton, FilledButton, TabBar)
7. **Responsive** â€” Cards flow from 3-column grid (desktop) to stacked column (mobile). See Section 25.

### App Icon:
- Use existing `icon.png` asset
- Generate for all platforms using `flutter_launcher_icons`
- Round corners on Android (adaptive icon), square on Windows

### Splash Screen:
- White background
- Centered app icon (120x120)
- App name text below: "RBP" (primary blue, bold, size 28)
- Subtitle: "Rivas Budget Planning" (subtitle gray, size 14)

---

## 22. STATE MANAGEMENT

Use **Provider** pattern with `ChangeNotifier`.

### `FinanceProvider` (main provider)
```dart
class FinanceProvider extends ChangeNotifier {
  final FinanceService _service;
  
  // Current visible period
  int _viewYear;
  int _viewMonth;
  int _viewCycle;

  // Cached dashboard data
  DashboardData? _dashboardData;
  
  // Loading state
  bool _isLoading = false;

  // Methods that modify data should:
  // 1. Call service method
  // 2. Call refreshAll()
  // 3. notifyListeners()

  Future<void> refreshAll() async {
    _dashboardData = await _service.getDashboardData(
      year: _viewYear, month: _viewMonth, cycle: _viewCycle);
    notifyListeners();
  }

  // Navigation
  void previousPeriod() { ... update _viewYear/_viewMonth/_viewCycle ... refreshAll(); }
  void nextPeriod() { ... }
  void goToToday() { ... }
}
```

### Provider tree (in main.dart or app.dart):
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => FinanceProvider(financeService)),
  ],
  child: RBPApp(),
)
```

### Every screen reads from `context.watch<FinanceProvider>()` and calls action methods that trigger `notifyListeners()`.

---

## 23. LICENSE & ACTIVATION SYSTEM

> **IMPLEMENT IN PHASE 1 (Desktop only).** On Android and Web, skip license checks entirely â€” monetization is handled via ads + in-app purchases.

### Overview
The desktop (Windows) version uses an **offline machine-ID-based license system**. No server is required. The user receives a license key that is tied to their specific machine. This prevents casual piracy while keeping the system simple.

### How it works:
1. App generates a **Machine ID** (hardware fingerprint) unique to the user's computer
2. The developer (you, Jose) uses the Machine ID to generate a **License Key** offline using a secret salt
3. User enters the License Key in the app's activation screen
4. App validates the key by re-computing the expected key from Machine ID + secret salt
5. If valid, app stores the key securely and runs normally
6. On each launch, app checks stored key validity (no internet needed)

### Machine ID Generation (`license_service.dart`):
```dart
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LicenseService {
  // SECRET SALT â€” DO NOT SHARE OR COMMIT TO PUBLIC REPOS
  // Change this to your own unique string before building
  static const String _secretSalt = 'RBP_2025_RIVAS_BUDGET_PLANNING_SECRET_KEY_X7K9M2';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Generate a unique Machine ID from hardware info
  Future<String> getMachineId() async {
    final deviceInfo = DeviceInfoPlugin();
    String rawId = '';

    if (Platform.isWindows) {
      final windowsInfo = await deviceInfo.windowsInfo;
      // Combine multiple hardware identifiers for uniqueness
      rawId = '${windowsInfo.computerName}'
              '${windowsInfo.numberOfCores}'
              '${windowsInfo.systemMemoryInMegabytes}'
              '${windowsInfo.deviceId}';  // Windows device GUID
    }
    // For future platforms:
    // else if (Platform.isLinux) { ... }
    // else if (Platform.isMacOS) { ... }

    // Hash to produce a clean, fixed-length ID
    final bytes = utf8.encode(rawId);
    final hash = sha256.convert(bytes);
    // Return first 16 hex chars as the Machine ID (user-friendly)
    return hash.toString().substring(0, 16).toUpperCase();
  }

  /// Generate a license key from a Machine ID (DEVELOPER TOOL ONLY)
  /// This method is used by the developer to create keys for customers.
  /// In the shipping app, this method can be removed or hidden.
  static String generateLicenseKey(String machineId) {
    final input = '$machineId:$_secretSalt';
    final bytes = utf8.encode(input);
    final hash = sha256.convert(bytes);
    // Format: XXXX-XXXX-XXXX-XXXX (16 hex chars, uppercase)
    final raw = hash.toString().substring(0, 16).toUpperCase();
    return '${raw.substring(0, 4)}-${raw.substring(4, 8)}-${raw.substring(8, 12)}-${raw.substring(12, 16)}';
  }

  /// Validate a license key against the current machine
  Future<bool> validateKey(String licenseKey) async {
    final machineId = await getMachineId();
    final expectedKey = generateLicenseKey(machineId);
    return licenseKey.trim().toUpperCase() == expectedKey;
  }

  /// Store a validated license key securely
  Future<void> storeKey(String licenseKey) async {
    await _secureStorage.write(key: 'rbp_license_key', value: licenseKey.trim().toUpperCase());
    await _secureStorage.write(key: 'rbp_activation_date', value: DateTime.now().toIso8601String());
  }

  /// Check if the app is activated
  Future<bool> isActivated() async {
    final storedKey = await _secureStorage.read(key: 'rbp_license_key');
    if (storedKey == null || storedKey.isEmpty) return false;
    return await validateKey(storedKey);
  }

  /// Get stored license info for display
  Future<Map<String, String?>> getLicenseInfo() async {
    return {
      'key': await _secureStorage.read(key: 'rbp_license_key'),
      'activationDate': await _secureStorage.read(key: 'rbp_activation_date'),
      'machineId': await getMachineId(),
    };
  }

  /// Remove license (deactivate)
  Future<void> deactivate() async {
    await _secureStorage.delete(key: 'rbp_license_key');
    await _secureStorage.delete(key: 'rbp_activation_date');
  }
}
```

### Activation Screen (`activation_screen.dart`):
This screen is shown **ONLY on Windows desktop** when the app is not yet activated.

```
Layout:
  - Center column, max width 500px
  - App logo (80x80) at top
  - Title: "Activar RBP" (size 24, bold, primary blue)
  - Subtitle: "Ingresa tu clave de licencia para activar la aplicaciÃ³n." (size 14, subtitle gray)
  - Spacer (24px)
  - Card container:
    - Label: "Tu ID de mÃ¡quina:" (size 12, subtitle)
    - Machine ID display: Text in monospace font, bold, with copy button (IconButton: Icons.copy)
    - Spacer (16px)
    - Label: "Clave de licencia:" (size 12, subtitle)
    - TextField: hint "XXXX-XXXX-XXXX-XXXX", monospace font, uppercase, width 300
    - Spacer (16px)
    - FilledButton: "Activar" (primary blue, full width, icon: Icons.vpn_key)
    - Spacer (8px)
    - TextButton: "Continuar sin activar (modo de prueba)" (subtitle color)
  - Help text at bottom: "Contacta al desarrollador con tu ID de mÃ¡quina para obtener tu clave."
  - Contact info: Email or WhatsApp (configurable in constants.dart)
```

### Activation Flow:
```
App Launch â†’ Check Platform
  â”œâ”€â”€ Android/Web â†’ Skip license, go to HomeScreen
  â””â”€â”€ Windows Desktop:
      â”œâ”€â”€ LicenseService.isActivated() == true â†’ HomeScreen
      â””â”€â”€ LicenseService.isActivated() == false â†’ ActivationScreen
          â”œâ”€â”€ User enters key â†’ validateKey()
          â”‚   â”œâ”€â”€ Valid â†’ storeKey() â†’ SnackBar "Â¡Licencia activada!" â†’ HomeScreen
          â”‚   â””â”€â”€ Invalid â†’ SnackBar "Clave invÃ¡lida. Verifica e intenta de nuevo." (red)
          â””â”€â”€ User clicks "Continuar sin activar" â†’ HomeScreen (trial mode)
```

### Trial Mode (optional â€” configurable):
- If user skips activation, app runs with limitations:
  - Show a persistent banner at top: "VersiÃ³n de prueba â€” Activa tu licencia para acceso completo"
  - Limit to 15 expenses per period
  - Disable PDF/CSV export
  - Show reminder dialog every 3rd app launch
- Set `TRIAL_EXPENSE_LIMIT = 15` in `constants.dart`
- Set `TRIAL_REMINDER_INTERVAL = 3` in `constants.dart`

### Developer Key Generation Tool:
Create a separate Dart script `tools/generate_key.dart` (NOT included in the app bundle):
```dart
// Run with: dart run tools/generate_key.dart <MACHINE_ID>
import 'package:rbp_flutter/services/license_service.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart run tools/generate_key.dart <MACHINE_ID>');
    return;
  }
  final machineId = args[0].toUpperCase();
  final key = LicenseService.generateLicenseKey(machineId);
  print('Machine ID: $machineId');
  print('License Key: $key');
}
```

### License Constants (in `constants.dart`):
```dart
// License system
const kDeveloperContact = 'WhatsApp: +1-XXX-XXX-XXXX'; // Update with real contact
const kDeveloperEmail = 'soporte@rivasbudget.com';      // Update with real email
const kTrialExpenseLimit = 15;
const kTrialReminderInterval = 3;  // Show reminder every N launches
```

---

## 24. BUSINESS MODEL & REVENUE FLOW

### Business Model: FREEMIUM + DIRECT SALES

RBP uses a **hybrid monetization strategy** across platforms:

| Platform | Monetization Method | Details |
|----------|-------------------|---------|
| **Android** (Play Store) | Freemium + Ads + IAP | Free with ads, premium subscription removes ads and unlocks features |
| **Windows** (Desktop) | Direct license sale | One-time purchase, license key tied to machine |
| **Web** (Browser) | Freemium + IAP | Free with limited features, premium subscription |

### Revenue Streams:
1. **Desktop License Sales (immediate revenue)**
   - Price: **$9.99 USD** one-time purchase
   - Sold via: WhatsApp, PayPal, direct contact
   - Delivery: User sends Machine ID â†’ Developer sends License Key
   - No transaction fees (peer-to-peer payment)

2. **Android Subscription (recurring revenue)**
   - Monthly: **$3.99 USD/month**
   - Yearly: **$29.99 USD/year** (save 37%)
   - Via Google Play In-App Purchases
   - Google takes 15-30% commission

3. **Android Ads (passive revenue)**
   - Banner ads on Dashboard and Settings tabs
   - Interstitial ad every 5th expense save
   - Estimated: $0.50-2.00 per 1000 impressions (eCPM varies by region)

4. **Web Subscription (future, Phase 2)**
   - Same pricing as Android
   - Via Stripe or Google Play Billing for Web

### Free vs Premium Feature Matrix:

| Feature | Free (Android/Web) | Premium (Android/Web) | Desktop (Licensed) |
|---------|--------------------|-----------------------|---------------------|
| Dashboard | âœ… | âœ… | âœ… |
| Expense tracking | âœ… (max 50/month) | âœ… Unlimited | âœ… Unlimited |
| Categories | âœ… (max 3) | âœ… Unlimited | âœ… Unlimited |
| Fixed payments | âœ… | âœ… | âœ… |
| Loans | âœ… | âœ… | âœ… |
| Savings + Goals | âŒ | âœ… | âœ… |
| PDF/CSV export | âŒ | âœ… | âœ… |
| Custom quincena | âŒ | âœ… | âœ… |
| Cloud sync | âŒ | âœ… (Phase 2) | âŒ |
| Ads | âœ… Shown | âŒ No ads | âŒ No ads |
| Backup/Restore | âœ… Local only | âœ… Local + Cloud | âœ… Local |
| Period modes | âœ… Quincenal only | âœ… Both | âœ… Both |
| Priority support | âŒ | âœ… | âœ… |

### Business Flow Diagram:
```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                    USER DISCOVERS APP                    â”‚
â”‚        (Play Store / Direct download / Web URL)          â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”˜
             â”‚                  â”‚                  â”‚
     â”Œâ”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”  â”Œâ”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”  â”Œâ”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”
     â”‚   ANDROID     â”‚  â”‚   WINDOWS   â”‚  â”‚     WEB       â”‚
     â”‚  Play Store   â”‚  â”‚  Direct DL  â”‚  â”‚   Browser     â”‚
     â””â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”˜  â””â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”˜  â””â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”˜
             â”‚                  â”‚                  â”‚
     â”Œâ”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”  â”Œâ”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”  â”Œâ”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”
     â”‚ FREE TIER     â”‚  â”‚ TRIAL MODE  â”‚  â”‚ FREE TIER     â”‚
     â”‚ - Ads shown   â”‚  â”‚ - Limited   â”‚  â”‚ - Limited     â”‚
     â”‚ - Limited     â”‚  â”‚ - Reminder  â”‚  â”‚               â”‚
     â””â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”˜  â””â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”˜  â””â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”˜
             â”‚                  â”‚                  â”‚
     â”Œâ”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”  â”Œâ”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”  â”Œâ”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”
     â”‚ UPGRADE PATH  â”‚  â”‚ BUY LICENSE â”‚  â”‚ UPGRADE PATH  â”‚
     â”‚ $3.99/mo or   â”‚  â”‚ $9.99 once  â”‚  â”‚ $3.99/mo or   â”‚
     â”‚ $29.99/yr IAP â”‚  â”‚ via PayPal  â”‚  â”‚ $29.99/yr     â”‚
     â””â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”˜  â””â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”˜  â””â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”˜
             â”‚                  â”‚                  â”‚
     â”Œâ”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”
     â”‚              PREMIUM / LICENSED USER                â”‚
     â”‚  - No ads, all features, PDF/CSV, savings goals    â”‚
     â”‚  - Cloud sync (Phase 2), priority support          â”‚
     â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

### User Acquisition Strategy:
1. **Word of mouth** â€” Friends, family, co-workers in Dominican Republic
2. **Play Store organic** â€” Good reviews, screenshots, ASO (App Store Optimization)
3. **Social media** â€” Instagram/TikTok budgeting tips â†’ app link
4. **WhatsApp groups** â€” Share with Dominican community groups
5. **Direct sales** â€” Offer desktop version to people who prefer PC

### Pricing Justification:
- **$3.99/month** is accessible for Dominican market (â‰ˆ RD$240/month)
- **$29.99/year** saves â‰ˆ RD$1,400/year vs monthly
- **$9.99 desktop** is a one-time affordable purchase (â‰ˆ RD$600)
- Comparable apps charge $4.99-9.99/month internationally

### Implementation Priority:
1. **Phase 1:** Desktop license system (direct sales begin immediately)
2. **Phase 1.5:** Android free tier with ads (reach more users)
3. **Phase 2:** In-app purchases for premium (recurring revenue)
4. **Phase 2:** Web version with free tier
5. **Phase 3:** Cloud sync as premium-only feature (retention)

---

## 25. MULTI-PLATFORM ARCHITECTURE & DISTRIBUTION

### Platform Support Matrix:
| Platform | UI Mode | Database | License | Ads | IAP | Build Output |
|----------|---------|----------|---------|-----|-----|-------------|
| **Android** | Mobile (portrait mainly) | `sqflite` | N/A (ads/IAP) | âœ… | âœ… | APK / AAB |
| **Windows** | Desktop (landscape, resizable) | `sqflite_common_ffi` | Machine-ID key | âŒ | âŒ | EXE / MSIX |
| **Web** | Responsive (any size) | `sqflite_common_ffi_web` (IndexedDB) | N/A (ads/IAP) | âŒ (future) | âœ… (future) | JS bundle |

### Responsive Layout System:

Create `responsive_layout.dart`:
```dart
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1024) {
          return desktop;
        } else if (constraints.maxWidth >= 600) {
          return tablet ?? desktop;
        } else {
          return mobile;
        }
      },
    );
  }
}
```

### Breakpoints (`breakpoints.dart`):
```dart
class Breakpoints {
  static const double mobile = 0;      // 0-599px â€” phone
  static const double tablet = 600;    // 600-1023px â€” tablet, small laptop
  static const double desktop = 1024;  // 1024px+ â€” desktop, wide browser

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < tablet;
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet &&
      MediaQuery.of(context).size.width < desktop;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;
}
```

### Layout Adaptations Per Screen:

| Screen | Mobile (<600px) | Desktop (â‰¥1024px) |
|--------|----------------|-------------------|
| **Dashboard** | Stat cards stacked vertically (1 column) | 3 cards per row (2 rows) |
| **Income** | Salary form + income form stacked | Side by side (7/12 + 5/12) |
| **Expense** | Single column form | Centered form, max width 500px |
| **Fixed Payments** | List + form stacked | List (7/12) + form (5/12) side by side |
| **Loans** | List + form stacked | List (7/12) + form (5/12) side by side |
| **Savings** | Panels stacked + goals below | Panels side by side (6/12 each) + goals below |
| **Settings** | Single scrollable column | Two-column layout where applicable |
| **Navigation** | Bottom TabBar + hamburger | Top TabBar (horizontal tabs) |

### Tab Bar Adaptation:
```dart
// Mobile: Use BottomNavigationBar with 5 items (group some tabs)
// OR: Use a scrollable top TabBar that wraps
// Desktop: Full horizontal TabBar with all 7 tabs visible

Widget buildNavigation(BuildContext context) {
  if (Breakpoints.isMobile(context)) {
    // Use scrollable TabBar at top (all 7 tabs)
    // TabBar with isScrollable: true
    return TabBar(isScrollable: true, tabs: [...]);
  } else {
    // Full-width TabBar
    return TabBar(isScrollable: false, tabs: [...]);
  }
}
```

### Platform-Specific Code (`platform_config.dart`):
```dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class PlatformConfig {
  static bool get isWeb => kIsWeb;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isWindows => !kIsWeb && Platform.isWindows;
  static bool get isDesktop => !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Should show license activation (desktop only)
  static bool get requiresLicense => isWindows;

  /// Should show ads (Android free tier only)
  static bool get supportsAds => isAndroid;

  /// Should show in-app purchases
  static bool get supportsIAP => isAndroid || isWeb;

  /// Database factory based on platform
  static Future<Database> openPlatformDatabase(String path) async {
    if (kIsWeb) {
      // Use sqflite_common_ffi_web
      var factory = databaseFactoryFfiWeb;
      return factory.openDatabase(path);
    } else if (Platform.isWindows || Platform.isLinux) {
      // Use sqflite_common_ffi
      sqfliteFfiInit();
      var factory = databaseFactoryFfi;
      return factory.openDatabase(path);
    } else {
      // Android/iOS â€” use sqflite directly
      return openDatabase(path);
    }
  }
}
```

### `main.dart` â€” Platform-Aware Entry Point:
```dart
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';
import 'config/platform_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Platform-specific initialization
  if (PlatformConfig.isWindows) {
    // Initialize FFI for SQLite on desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Configure window
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = WindowOptions(
      size: Size(1280, 800),
      minimumSize: Size(900, 600),
      center: true,
      title: 'RBP - Rivas Budget Planning',
      titleBarStyle: TitleBarStyle.normal,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  if (PlatformConfig.isWeb) {
    // Initialize web database factory
    // databaseFactory = databaseFactoryFfiWeb;
  }

  runApp(const RBPApp());
}
```

### Windows Desktop Distribution:
1. **Direct download (.exe):**
   ```bash
   flutter build windows --release
   # Output: build/windows/x64/runner/Release/
   # Zip the Release folder â†’ distribute as .zip
   ```
   - Include a README.txt with activation instructions
   - User downloads, unzips, runs `rbp_flutter.exe`
   - SmartScreen warning expected â€” include note: "Windows puede mostrar una advertencia. Haz clic en 'MÃ¡s informaciÃ³n' â†’ 'Ejecutar de todas formas'"

2. **MSIX Package (Microsoft Store):**
   ```bash
   dart run msix:create
   # Output: build/windows/x64/runner/Release/rbp_flutter.msix
   ```
   - Signed MSIX avoids SmartScreen warnings
   - Can distribute directly or via Microsoft Store

### Android Distribution:
```bash
# Debug APK (testing)
flutter build apk --debug

# Release APK (direct distribution)
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Release AAB (Google Play Store)
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

**Android signing:** Create a keystore and configure `android/app/build.gradle` per Flutter docs.

### Web Distribution:
```bash
flutter build web --release
# Output: build/web/

# Deploy to Firebase Hosting:
firebase init hosting
firebase deploy --only hosting

# OR deploy to Vercel:
vercel --prod build/web
```

---

## 26. SCALABILITY ARCHITECTURE

### Architecture Principles:
1. **Offline-first** â€” App works 100% offline with local SQLite. Cloud sync is additive, never required.
2. **Repository pattern** â€” All data access goes through repositories. Swapping SQLite for Firestore requires changing only repository implementations, not business logic or UI.
3. **Service layer isolation** â€” `FinanceService` contains ALL business logic. UI never talks to repositories directly.
4. **Provider-based state** â€” `ChangeNotifier` + `Provider` for reactive UI. Easy to migrate to Riverpod or BLoC later if needed.
5. **Platform abstraction** â€” `PlatformConfig` encapsulates platform checks. Adding iOS/macOS/Linux is a config change, not a rewrite.

### Scalability Path:
```
Phase 1: Local-only (SQLite)
  â””â”€â”€ Single user, single device, all data local
  â””â”€â”€ Desktop license system
  â””â”€â”€ Android free tier with ads

Phase 2: Cloud-enabled (Firebase)
  â””â”€â”€ User accounts (Firebase Auth)
  â””â”€â”€ Cloud sync (Firestore)
  â””â”€â”€ Cross-device data sync
  â””â”€â”€ Premium subscriptions (IAP)
  â””â”€â”€ Analytics + Crashlytics

Phase 3: Multi-user & Advanced
  â””â”€â”€ Family/household accounts (shared budgets)
  â””â”€â”€ Bill reminders (push notifications)
  â””â”€â”€ Bank integration (if available in DR market)
  â””â”€â”€ Budget recommendations (ML-based)
  â””â”€â”€ Multi-currency support
  â””â”€â”€ iOS version (same codebase, flip the switch)
```

### Database Migration Strategy:
```dart
// In database_helper.dart
static const _databaseVersion = 1;  // Increment for each schema change

Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    // Example: Add a new column
    await db.execute('ALTER TABLE users ADD COLUMN premium INTEGER DEFAULT 0');
  }
  if (oldVersion < 3) {
    // Example: Add a new table
    await db.execute('CREATE TABLE IF NOT EXISTS ...');
  }
  // Always forward-compatible â€” never delete columns, only add
}
```

### Feature Flags (for gradual rollout):
```dart
class FeatureFlags {
  // Toggle features without code changes (Phase 2: use Firebase Remote Config)
  static const bool enableCloudSync = false;      // Phase 2
  static const bool enableAds = true;              // Phase 1.5
  static const bool enableIAP = false;             // Phase 2
  static const bool enableSavingsGoals = true;     // Phase 1
  static const bool enablePdfExport = true;        // Phase 1
  static const bool enableLicenseSystem = true;    // Phase 1 (desktop only)
  static const bool enableWebPlatform = true;      // Phase 1
  static const bool enableNotifications = false;   // Phase 2
  static const bool enableMultiCurrency = false;   // Phase 3
}
```

### Performance Considerations:
1. **Lazy loading** â€” Dashboard loads only current period data. Don't pre-fetch all periods.
2. **Pagination** â€” Recent expenses list: load 20, scroll to load more.
3. **Query optimization** â€” Use indexes on frequently-queried columns (`date`, `user_id`, `quincenal_cycle`).
4. **Cache invalidation** â€” `FinanceProvider.refreshAll()` reloads only dashboard data for current period. Individual tabs reload on focus.
5. **Image optimization** â€” Compress logo assets, use appropriate resolution per platform.
6. **SQLite indexes** (add in `_onCreate`):
```sql
CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date);
CREATE INDEX IF NOT EXISTS idx_expenses_user_cycle ON expenses(user_id, quincenal_cycle);
CREATE INDEX IF NOT EXISTS idx_fixed_payment_records_lookup ON fixed_payment_records(fixed_payment_id, year, month);
CREATE INDEX IF NOT EXISTS idx_savings_user_period ON savings(user_id, year, month, quincenal_cycle);
```

### Modular Architecture for Future Features:
```
Current modules (Phase 1):
  â”œâ”€â”€ Expenses module
  â”œâ”€â”€ Fixed Payments module
  â”œâ”€â”€ Loans module
  â”œâ”€â”€ Savings module
  â”œâ”€â”€ Income module
  â”œâ”€â”€ Reports module (PDF/CSV)
  â””â”€â”€ License module (desktop)

Future modules (plug-in):
  â”œâ”€â”€ Cloud Sync module â†’ add FirestoreRepository implementations
  â”œâ”€â”€ Ads module â†’ add AdWidget wrappers
  â”œâ”€â”€ IAP module â†’ add PurchaseService
  â”œâ”€â”€ Notifications module â†’ add NotificationService
  â””â”€â”€ Analytics module â†’ add AnalyticsService
```

Each module follows the same pattern:
- **Model** â†’ `lib/data/models/`
- **Repository** â†’ `lib/data/repositories/`
- **Service** â†’ `lib/services/`
- **UI** â†’ `lib/ui/screens/` + `lib/ui/widgets/`

---

## 27. FIREBASE INTEGRATION (Phase 2)

> **Do NOT implement in Phase 1. This section is for future reference.**

### Auth
- Email/password registration
- Google Sign-In
- Anonymous auth for free-tier users

### Firestore structure:
```
users/{uid}/
  profile: { name, email, created_at }
  categories/{catId}: { name, color, icon }
  expenses/{expId}: { amount, description, date, ... }
  fixed_payments/{fpId}: { name, amount, due_day, ... }
  loans/{loanId}: { person, amount, ... }
  savings/{savingsId}: { total_saved, ... }
  settings/{key}: { value }
```

### Sync strategy:
- Read from local SQLite first (offline-first)
- Push changes to Firestore in background
- On login, merge cloud data with local data (conflict resolution: latest timestamp wins)

---

## 28. ADMOB INTEGRATION (Phase 2)

> **Do NOT implement in Phase 1.**

### Ad placements:
1. **Banner ad** at bottom of Dashboard tab (320x50)
2. **Interstitial ad** after every 5th expense save
3. **Banner ad** at bottom of Settings tab

### Premium removes all ads.

### Test ad unit IDs (for development):
- Banner: `ca-app-pub-3940256099942544/6300978111`
- Interstitial: `ca-app-pub-3940256099942544/1033173712`

---

## 29. IN-APP PURCHASES (Phase 2)

> **Do NOT implement in Phase 1.**

### Products:
| SKU | Type | Price |
|-----|------|-------|
| `rbp_premium_monthly` | Subscription | $3.99/month |
| `rbp_premium_yearly` | Subscription | $29.99/year |

### Premium features:
- No ads
- Unlimited categories
- PDF/CSV export
- Cloud sync
- Savings goals
- Priority support

### Free tier limitations:
- Max 50 expenses per month
- Max 3 categories
- No PDF/CSV export
- Banner ads shown
- No cloud sync

---

## 30. TESTING STRATEGY

### Unit tests (required for Phase 1):

1. **`date_helpers_test.dart`**
   - Test `getQuincenaRange` for normal paydays (1, 16)
   - Test `getQuincenaRange` for custom paydays (15, 30)
   - Test `getQuincenaRange` for crossed paydays (25, 10)
   - Test `getCycleForDate` for various dates
   - Test prev/next quincena navigation
   - Test monthly period range

2. **`finance_service_test.dart`**
   - Test dashboard calculation with known data
   - Test expense source affecting savings vs salary totals
   - Test fixed payment period logic with due dates
   - Test loan deduction types
   - Test savings deposit, withdrawal (insufficient funds)
   - Test salary override precedence

3. **`database_test.dart`**
   - Test CRUD operations for each table
   - Test foreign key constraints
   - Test upsert behavior (INSERT OR REPLACE)
   - Test custom quincena storage/retrieval

### Widget tests (recommended):
- Test stat card renders correct values
- Test dashboard displays period label correctly
- Test form validation shows correct error messages
- Test navigation changes period correctly

---

## 31. BUILD & RELEASE (Multi-Platform)

### Android
```bash
# Debug
flutter run

# Release APK
flutter build apk --release

# Release AAB (for Play Store)
flutter build appbundle --release
```

### Windows (desktop)
```bash
flutter build windows --release
```

### Icon generation:
Use `flutter_launcher_icons` package with the existing `icon.png` asset.

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.0

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon.png"
```

---

## 32. IMPLEMENTATION ORDER & MILESTONES

> **Execution scope agreed with product owner (temporary):**
> Focus implementation and validation on **Windows desktop only** until release-quality parity is achieved.
> Android/Web milestones remain documented but are **deferred** for later phases.

### Milestone 1: Project Setup & Platform Config (Day 1)
- [x] Create Flutter project: `flutter create --platforms=android,windows,web rbp_flutter`
- [ ] Set up `pubspec.yaml` with ALL Phase 1 dependencies (see Section 2 for exact list) - **Parcial** (`flutter_secure_storage` removido temporalmente por toolchain C++ en Windows)
- [x] Create complete project folder structure (all directories from Section 3)
- [x] Add assets (`icon.png`, `Untitled.png`)
- [x] Configure Material 3 theme in `app.dart` (see Section 21)
- [x] Create `constants.dart` with all colors, defaults, license constants
- [x] Create `breakpoints.dart` and `platform_config.dart` (see Section 25)
- [x] Create `responsive_layout.dart` widget
- [x] Configure `window_manager` for Windows desktop (min size 900x600)
- [x] Implement platform-aware `main.dart` with SQLite FFI init for desktop/web

### Milestone 2: Database Layer (Days 2-3)
- [x] Create all Dart model classes (13 data models + `LicenseInfo`)
- [x] Implement `DatabaseHelper` with platform-aware database factory
- [x] Implement all CREATE TABLE statements + SQLite indexes (see Section 26)
- [x] Implement all 8 repositories with complete CRUD
- [x] Write unit tests for database operations

### Milestone 3: Business Logic (Days 4-6)
- [x] Implement `date_helpers.dart` (all period logic - see Section 20)
- [x] Write unit tests for date helpers (CRITICAL - many edge cases)
- [x] Implement `FinanceService` with ALL methods (see Section 7)
- [x] Implement `currency_formatter.dart` (`RD$` prefix, comma-separated)
- [x] Write unit tests for finance service calculations
- [x] Implement `BackupService`

### Milestone 4: License System (Day 7)
- [x] Implement `LicenseService` (see Section 23, full code provided) - **Completado con storage local por archivo JSON en lugar de `flutter_secure_storage`**
- [x] Implement `ActivationScreen` UI (see Section 23)
- [x] Implement trial mode with limitations
- [x] Create `tools/generate_key.dart` developer tool
- [x] Write unit tests for license key generation/validation
- [x] Integrate license check into app startup flow

### Milestone 5: State Management (Day 8)
- [x] Implement `FinanceProvider` with `ChangeNotifier` (see Section 22)
- [x] Set up `MultiProvider` tree in `app.dart`
- [x] Implement period navigation (prev/next/today) in provider
- [ ] Test provider updates trigger UI rebuilds

### Milestone 6: UI Screens Part 1 (Days 9-11)
- [x] Implement `home_screen.dart` - responsive tab scaffold (top tabs desktop, scrollable tabs mobile)
- [x] Implement `stat_card.dart` reusable widget
- [x] Implement `period_nav_bar.dart` widget
- [x] Implement `responsive_layout.dart` with breakpoints (see Section 25)
- [x] Implement Dashboard tab - responsive grid (3 cols desktop, 1 col mobile)
- [x] Implement Expense tab - centered form with responsive max-width
- [x] Implement Income tab - side-by-side desktop, stacked mobile

### Milestone 7: UI Screens Part 2 (Days 12-14)
- [x] Implement Fixed Payments tab (list + form, responsive layout)
- [x] Implement Loans tab (list + form + deduction logic)
- [x] Implement Savings tab (deposit/withdraw/extra + goals list)
- [x] Implement Settings tab (all settings + category management)
- [ ] Verify all screens adapt properly: mobile portrait, desktop landscape, web browser

### Milestone 8: Dialogs & Charts (Days 15-16)
- [x] Implement all 8 edit dialogs (see Section 16 for exact specs)
- [x] Implement pie chart widget with legend (`fl_chart`)
- [x] Implement chart dialog (820x520 on desktop, fullscreen on mobile)
- [x] Implement custom quincena dialog
- [x] Implement period close alert dialog

### Milestone 9: Reports & Export (Days 17-18)
- [ ] Implement PDF report generation matching existing layout (see Section 17) - **Parcial**
- [x] Implement CSV export with UTF-8 BOM (see Section 18)
- [x] Implement `share_plus` for mobile sharing
- [x] Implement `file_picker` for desktop save-as (export)
- [ ] Test export on Windows desktop (Android/Web deferred)

### Milestone 10: Multi-Platform Testing (Days 19-21)
- [ ] Run all unit tests on all platforms
- [ ] Manual testing on Android emulator (phone + tablet sizes)
- [ ] Manual testing on Windows desktop (1280x800 and 1920x1080)
- [ ] Manual testing on Web (Chrome, Firefox, Edge)
- [ ] Test license activation flow on Windows
- [ ] Test responsive layouts at all breakpoints
- [ ] Fix any visual discrepancies between platforms
- [ ] Performance optimization (lazy loading, query indexes)
- [ ] Error handling and edge cases

### Milestone 11: Release (Days 22-24)
- [ ] Generate app icons for all platforms (`flutter_launcher_icons`)
- [ ] Create Play Store listing assets (screenshots, description in Spanish)
- [ ] Build release AAB for Play Store
- [ ] Build release Windows EXE + MSIX package
- [ ] Build and deploy web version
- [ ] Create privacy policy (required for Play Store)
- [ ] Submit to Google Play Store
- [ ] Create distribution .zip for Windows with README
- [ ] Test license key generation for first customers

---

## CRITICAL RULES FOR IMPLEMENTATION

1. **Currency:** Always use `RD$` prefix, format with commas and 2 decimals: `RD$25,000.00`
2. **Language:** ALL UI text is in **Spanish**. Do not translate to English.
3. **Dates:** Always `YYYY-MM-DD` format in the database. Display as-is in the UI.
4. **Default user:** Auto-create user "Jose" if no users exist (ID = 1).
5. **Default categories:** `["Comida", "Combustible", "Uber/Taxi", "Subscripciones", "Varios/Snacks", "Otros"]` â€” created on first run if none exist.
6. **Soft delete for fixed payments:** Set `is_active = 0`, never actually delete the row.
7. **Savings withdrawal:** Must check balance before allowing. Return false if insufficient.
8. **Category deletion:** Must check usage in `expense_categories` AND `fixed_payments` tables. Block if in use.
9. **Period navigation must wrap correctly:** Q2 â†’ next month Q1, Q1 â†’ prev month Q2, January Q1 â†’ December of prev year Q2.
10. **Dashboard calculations:** `dinero_inicial = salary + extraIncome - periodSavings`. `dinero_disponible = dinero_inicial - totalExpensesSalary - totalFixed - totalLoans`.
11. **Fixed payments default status:** When `due_day > 0`, the `default_status` for `get_fixed_payment_record_status` is `"paid"`. When `due_day <= 0`, default is `"pending"`.
12. **SnackBar messages:** Normalize error messages as specified in Section 21.
13. **Form reset after save:** All "add" forms must clear their fields after successful save.
14. **The DB schema must be 100% compatible** with the Python app's existing database to support data migration.
15. **Multi-platform:** Use `PlatformConfig` class (Section 25) for ALL platform-specific logic. NEVER use `dart:io` `Platform` directly in UI code.
16. **License system:** Only enforce on Windows desktop. Android and Web use ads/IAP instead (Section 23).
17. **Responsive UI:** ALL screens must use `LayoutBuilder` or `MediaQuery` to adapt between mobile and desktop layouts (Section 25).
18. **SQLite platform init:** Initialize `sqfliteFfiInit()` + `databaseFactoryFfi` on Windows, `databaseFactoryFfiWeb` on Web, default `sqflite` on Android (Section 25).
19. **Package name:** `com.rivasbudget.rbp` on all platforms.
20. **Feature flags:** Use `FeatureFlags` class (Section 26) to toggle features without code changes.

---

## DATA MIGRATION HELPER

For users migrating from the desktop Python app, provide a way to import the existing `finanzas.db` file:

```dart
Future<void> importDatabase(String sourcePath) async {
  final dbDir = await getApplicationDocumentsDirectory();
  final targetPath = join(dbDir.path, 'finanzas.db');
  
  // Close current database
  await DatabaseHelper.instance.close();
  
  // Copy imported file
  final sourceFile = File(sourcePath);
  await sourceFile.copy(targetPath);
  
  // Reopen database
  await DatabaseHelper.instance.database;
}
```

This should be accessible from Settings as "Importar base de datos desde escritorio".

---

*End of migration plan. This document contains everything needed to build a complete, multi-platform Flutter replica of the RBP personal finance app â€” including the license system, business model, responsive UI for Android/Windows/Web, and scalability architecture.*
