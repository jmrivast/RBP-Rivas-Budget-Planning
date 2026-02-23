class SqlTables {
  static const users = '''
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    email TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT 1
);
''';

  static const categories = '''
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
''';

  static const budgets = '''
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
''';

  static const expenses = '''
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
''';

  static const expenseCategories = '''
CREATE TABLE IF NOT EXISTS expense_categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    expense_id INTEGER NOT NULL,
    category_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id),
    UNIQUE(expense_id, category_id)
);
''';

  static const fixedPayments = '''
CREATE TABLE IF NOT EXISTS fixed_payments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    amount REAL NOT NULL,
    category_id INTEGER,
    due_day INTEGER NOT NULL,
    frequency TEXT DEFAULT 'monthly',
    is_active BOOLEAN DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (category_id) REFERENCES categories(id)
);
''';

  static const fixedPaymentRecords = '''
CREATE TABLE IF NOT EXISTS fixed_payment_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    fixed_payment_id INTEGER NOT NULL,
    expense_id INTEGER,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    quincenal_cycle INTEGER,
    status TEXT DEFAULT 'pending',
    paid_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (fixed_payment_id) REFERENCES fixed_payments(id),
    FOREIGN KEY (expense_id) REFERENCES expenses(id)
);
''';

  static const extraIncome = '''
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
''';

  static const savings = '''
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
''';

  static const backups = '''
CREATE TABLE IF NOT EXISTS backups (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    backup_file TEXT NOT NULL,
    backup_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
''';

  static const loans = '''
CREATE TABLE IF NOT EXISTS loans (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    person TEXT NOT NULL,
    amount REAL NOT NULL,
    description TEXT,
    date DATE NOT NULL,
    is_paid BOOLEAN DEFAULT 0,
    paid_date DATE,
    deduction_type TEXT DEFAULT 'ninguno',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
''';

  static const savingsGoals = '''
CREATE TABLE IF NOT EXISTS savings_goals (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    target_amount REAL NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
''';

  static const userSalary = '''
CREATE TABLE IF NOT EXISTS user_salary (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL UNIQUE,
    amount REAL NOT NULL DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
''';

  static const salaryOverrides = '''
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
''';

  static const userPeriodMode = '''
CREATE TABLE IF NOT EXISTS user_period_mode (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL UNIQUE,
    mode TEXT NOT NULL DEFAULT 'quincenal',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
''';

  static const userSettings = '''
CREATE TABLE IF NOT EXISTS user_settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    setting_key TEXT NOT NULL,
    setting_value TEXT NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    UNIQUE(user_id, setting_key)
);
''';

  static const customQuincena = '''
CREATE TABLE IF NOT EXISTS custom_quincena (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    cycle INTEGER NOT NULL,
    start_date TEXT NOT NULL,
    end_date TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    UNIQUE(user_id, year, month, cycle)
);
''';

  static const indexes = <String>[
    'CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date);',
    'CREATE INDEX IF NOT EXISTS idx_expenses_user_cycle ON expenses(user_id, quincenal_cycle);',
    'CREATE INDEX IF NOT EXISTS idx_fixed_payment_records_lookup ON fixed_payment_records(fixed_payment_id, year, month);',
    'CREATE INDEX IF NOT EXISTS idx_savings_user_period ON savings(user_id, year, month, quincenal_cycle);',
  ];

  static const createStatements = <String>[
    users,
    categories,
    budgets,
    expenses,
    expenseCategories,
    fixedPayments,
    fixedPaymentRecords,
    extraIncome,
    savings,
    backups,
    loans,
    savingsGoals,
    userSalary,
    salaryOverrides,
    userPeriodMode,
    userSettings,
    customQuincena,
  ];
}
