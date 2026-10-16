import {
  initialUser,
  initialBankAccounts,
  initialTransactions,
  initialEmergencyFund,
  initialSavingsGoals,
  initialAutoSaveRules,
  initialRecurringPayments,
  initialEMILoans,
  initialDocuments,
  initialSessions,
  initialBudgets,
} from './mockData';
import {
  User,
  BankAccount,
  Transaction,
  EmergencyFund,
  SavingsGoal,
  AutoSaveRule,
  RecurringPayment,
  EMILoan,
  DocumentItem,
  ChildCareSettings,
  UserSession,
  Budget,
} from '../types';

const STORAGE_KEYS = {
  USER: 'finpocket_user',
  TOKEN: 'finpocket_token',
  ACCOUNTS: 'finpocket_bank_accounts',
  TRANSACTIONS: 'finpocket_transactions',
  EMERGENCY_FUND: 'finpocket_emergency_fund',
  SAVINGS_GOALS: 'finpocket_savings_goals',
  AUTOSAVE_RULES: 'finpocket_autosave_rules',
  BILLS: 'finpocket_recurring_bills',
  EMIS: 'finpocket_emi_loans',
  DOCUMENTS: 'finpocket_documents',
  BUDGETS: 'finpocket_budgets',
  CHILD_CARE: 'finpocket_child_care',
  SESSIONS: 'finpocket_sessions',
  THEME: 'finpocket_theme',
  LANG: 'finpocket_language',
};

const defaultChildCareSettings: ChildCareSettings = {
  enabled: false,
  paymentBlocked: true,
  hideBalances: true,
  hideTransactionHistory: true,
  hideBankDetails: true,
  spendingLimit: 0,
  parentPinHash: '1234',
};

export const StorageService = {
  initialize() {
    if (!localStorage.getItem(STORAGE_KEYS.USER)) {
      localStorage.setItem(STORAGE_KEYS.USER, JSON.stringify(initialUser));
      localStorage.setItem(STORAGE_KEYS.TOKEN, 'demo_jwt_token_finpocket_mobile_secure_2026');
    }
    if (!localStorage.getItem(STORAGE_KEYS.ACCOUNTS)) {
      localStorage.setItem(STORAGE_KEYS.ACCOUNTS, JSON.stringify(initialBankAccounts));
    }
    if (!localStorage.getItem(STORAGE_KEYS.TRANSACTIONS)) {
      localStorage.setItem(STORAGE_KEYS.TRANSACTIONS, JSON.stringify(initialTransactions));
    }
    if (!localStorage.getItem(STORAGE_KEYS.EMERGENCY_FUND)) {
      localStorage.setItem(STORAGE_KEYS.EMERGENCY_FUND, JSON.stringify(initialEmergencyFund));
    }
    if (!localStorage.getItem(STORAGE_KEYS.SAVINGS_GOALS)) {
      localStorage.setItem(STORAGE_KEYS.SAVINGS_GOALS, JSON.stringify(initialSavingsGoals));
    }
    if (!localStorage.getItem(STORAGE_KEYS.AUTOSAVE_RULES)) {
      localStorage.setItem(STORAGE_KEYS.AUTOSAVE_RULES, JSON.stringify(initialAutoSaveRules));
    }
    if (!localStorage.getItem(STORAGE_KEYS.BILLS)) {
      localStorage.setItem(STORAGE_KEYS.BILLS, JSON.stringify(initialRecurringPayments));
    }
    if (!localStorage.getItem(STORAGE_KEYS.EMIS)) {
      localStorage.setItem(STORAGE_KEYS.EMIS, JSON.stringify(initialEMILoans));
    }
    if (!localStorage.getItem(STORAGE_KEYS.DOCUMENTS)) {
      localStorage.setItem(STORAGE_KEYS.DOCUMENTS, JSON.stringify(initialDocuments));
    }
    if (!localStorage.getItem(STORAGE_KEYS.BUDGETS)) {
      localStorage.setItem(STORAGE_KEYS.BUDGETS, JSON.stringify(initialBudgets));
    }
    if (!localStorage.getItem(STORAGE_KEYS.CHILD_CARE)) {
      localStorage.setItem(STORAGE_KEYS.CHILD_CARE, JSON.stringify(defaultChildCareSettings));
    }
    if (!localStorage.getItem(STORAGE_KEYS.SESSIONS)) {
      localStorage.setItem(STORAGE_KEYS.SESSIONS, JSON.stringify(initialSessions));
    }
  },

  getUser(): User {
    const raw = localStorage.getItem(STORAGE_KEYS.USER);
    return raw ? JSON.parse(raw) : initialUser;
  },
  setUser(user: User) {
    localStorage.setItem(STORAGE_KEYS.USER, JSON.stringify(user));
  },

  getToken(): string | null {
    return localStorage.getItem(STORAGE_KEYS.TOKEN);
  },
  setToken(token: string) {
    localStorage.setItem(STORAGE_KEYS.TOKEN, token);
  },
  clearAuth() {
    localStorage.removeItem(STORAGE_KEYS.TOKEN);
    localStorage.removeItem(STORAGE_KEYS.USER);
  },

  getBankAccounts(): BankAccount[] {
    const raw = localStorage.getItem(STORAGE_KEYS.ACCOUNTS);
    return raw ? JSON.parse(raw) : initialBankAccounts;
  },
  setBankAccounts(accounts: BankAccount[]) {
    localStorage.setItem(STORAGE_KEYS.ACCOUNTS, JSON.stringify(accounts));
  },

  getTransactions(): Transaction[] {
    const raw = localStorage.getItem(STORAGE_KEYS.TRANSACTIONS);
    return raw ? JSON.parse(raw) : initialTransactions;
  },
  setTransactions(transactions: Transaction[]) {
    localStorage.setItem(STORAGE_KEYS.TRANSACTIONS, JSON.stringify(transactions));
  },

  getEmergencyFund(): EmergencyFund {
    const raw = localStorage.getItem(STORAGE_KEYS.EMERGENCY_FUND);
    return raw ? JSON.parse(raw) : initialEmergencyFund;
  },
  setEmergencyFund(fund: EmergencyFund) {
    localStorage.setItem(STORAGE_KEYS.EMERGENCY_FUND, JSON.stringify(fund));
  },

  getSavingsGoals(): SavingsGoal[] {
    const raw = localStorage.getItem(STORAGE_KEYS.SAVINGS_GOALS);
    return raw ? JSON.parse(raw) : initialSavingsGoals;
  },
  setSavingsGoals(goals: SavingsGoal[]) {
    localStorage.setItem(STORAGE_KEYS.SAVINGS_GOALS, JSON.stringify(goals));
  },

  getAutoSaveRules(): AutoSaveRule[] {
    const raw = localStorage.getItem(STORAGE_KEYS.AUTOSAVE_RULES);
    return raw ? JSON.parse(raw) : initialAutoSaveRules;
  },
  setAutoSaveRules(rules: AutoSaveRule[]) {
    localStorage.setItem(STORAGE_KEYS.AUTOSAVE_RULES, JSON.stringify(rules));
  },

  getBills(): RecurringPayment[] {
    const raw = localStorage.getItem(STORAGE_KEYS.BILLS);
    return raw ? JSON.parse(raw) : initialRecurringPayments;
  },
  setBills(bills: RecurringPayment[]) {
    localStorage.setItem(STORAGE_KEYS.BILLS, JSON.stringify(bills));
  },

  getEMIs(): EMILoan[] {
    const raw = localStorage.getItem(STORAGE_KEYS.EMIS);
    return raw ? JSON.parse(raw) : initialEMILoans;
  },
  setEMIs(emis: EMILoan[]) {
    localStorage.setItem(STORAGE_KEYS.EMIS, JSON.stringify(emis));
  },

  getBudgets(): Budget[] {
    const raw = localStorage.getItem(STORAGE_KEYS.BUDGETS);
    return raw ? JSON.parse(raw) : initialBudgets;
  },
  setBudgets(budgets: Budget[]) {
    localStorage.setItem(STORAGE_KEYS.BUDGETS, JSON.stringify(budgets));
  },

  getDocuments(): DocumentItem[] {
    const raw = localStorage.getItem(STORAGE_KEYS.DOCUMENTS);
    return raw ? JSON.parse(raw) : initialDocuments;
  },
  setDocuments(docs: DocumentItem[]) {
    localStorage.setItem(STORAGE_KEYS.DOCUMENTS, JSON.stringify(docs));
  },

  getChildCareSettings(): ChildCareSettings {
    const raw = localStorage.getItem(STORAGE_KEYS.CHILD_CARE);
    return raw ? JSON.parse(raw) : defaultChildCareSettings;
  },
  setChildCareSettings(settings: ChildCareSettings) {
    localStorage.setItem(STORAGE_KEYS.CHILD_CARE, JSON.stringify(settings));
  },

  getSessions(): UserSession[] {
    const raw = localStorage.getItem(STORAGE_KEYS.SESSIONS);
    return raw ? JSON.parse(raw) : initialSessions;
  },
  setSessions(sessions: UserSession[]) {
    localStorage.setItem(STORAGE_KEYS.SESSIONS, JSON.stringify(sessions));
  },
};
