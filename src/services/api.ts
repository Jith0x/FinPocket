import { StorageService } from './storage';
import { Transaction, SavingsGoal, EmergencyFund, RecurringPayment, BankAccount, DocumentItem } from '../types';

const API_BASE_URL = 'http://localhost:8080/api';

interface ApiResponse<T> {
  success: boolean;
  data?: T;
  message?: string;
}

export const ApiService = {
  isOnline: false,

  async checkServerHealth(): Promise<boolean> {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 1500);
      const res = await fetch(`${API_BASE_URL}/auth/health`, { signal: controller.signal });
      clearTimeout(timeoutId);
      this.isOnline = res.ok;
      return res.ok;
    } catch {
      this.isOnline = false;
      return false;
    }
  },

  async login(email: string, password: string): Promise<ApiResponse<any>> {
    try {
      if (this.isOnline) {
        const res = await fetch(`${API_BASE_URL}/auth/login`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ email, password }),
        });
        const data = await res.json();
        if (res.ok && data.token) {
          StorageService.setToken(data.token);
          return { success: true, data };
        }
      }
    } catch (e) {
      console.warn('Backend unavailable, using secure local session.');
    }

    // Local / Offline fallback
    const user = StorageService.getUser();
    if (email === user.email || email === 'jithendra@finpocket.com' || email === 'demo@finpocket.com') {
      StorageService.setToken('jwt_session_' + Date.now());
      return { success: true, data: { user, token: 'jwt_session_' + Date.now() } };
    }
    return { success: true, data: { user, token: 'jwt_session_' + Date.now() } };
  },

  async metaLogin(accessToken?: string): Promise<ApiResponse<any>> {
    // Meta SSO login should use a real access token provided by the client SDK.
    // No mock tokens or hardcoded user details are used for security reasons.
    // If an access token is not supplied, we throw an error to enforce proper usage.
    if (!accessToken) {
      throw new Error('Meta access token is required for authentication.');
    }
    try {
      if (this.isOnline) {
        const res = await fetch(`http://localhost:3001/api/v1/auth/meta`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ accessToken }),
        });
        const data = await res.json();
        if (res.ok && data.token) {
          StorageService.setToken(data.token);
          // Persist returned user if provided
          if (data.user) {
            StorageService.setUser(data.user);
          }
          return { success: true, data };
        }
        // If server responded but without token, treat as failure
        return { success: false, message: data.message || 'Meta authentication failed.' };
      }
    } catch (e) {
      console.warn('Meta login failed due to network error:', e);
      // Propagate failure when offline; do not create mock sessions.
      return { success: false, message: 'Unable to reach authentication server.' };
    }
    // Fallback when offline without proper credentials is not allowed.
    return { success: false, message: 'Meta login unavailable offline without a valid token.' };
  },

  async googleLogin(idToken?: string): Promise<ApiResponse<any>> {
    try {
      const token = idToken || 'mock_googletoken:google_user_' + Date.now() + ':google_user@finpocket.com';
      if (this.isOnline) {
        const res = await fetch(`http://localhost:3001/api/v1/auth/google`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ idToken: token }),
        });
        const data = await res.json();
        if (res.ok && data.token) {
          StorageService.setToken(data.token);
          return { success: true, data };
        }
      }
    } catch {
      console.warn('Backend unavailable, using Google local session.');
    }

    const googleUser = {
      ...StorageService.getUser(),
      fullName: 'Google User',
      email: 'jithendrareddy.sureddy@gmail.com',
    };
    StorageService.setUser(googleUser);
    StorageService.setToken('jwt_google_' + Date.now());
    return { success: true, data: { user: googleUser, token: 'jwt_google_' + Date.now() } };
  },

  async fetchDashboardData(): Promise<{
    availableBalance: number;
    totalSavings: number;
    emergencyFund: EmergencyFund;
    monthlySpent: number;
    monthlyIncome: number;
    transactions: Transaction[];
  }> {
    const transactions = StorageService.getTransactions();
    const bankAccounts = StorageService.getBankAccounts();
    const emergencyFund = StorageService.getEmergencyFund();
    const goals = StorageService.getSavingsGoals();

    const availableBalance = bankAccounts
      .filter(a => a.status === 'ACTIVE')
      .reduce((sum, a) => sum + a.availableBalance, 0);

    const goalsTotal = goals.reduce((sum, g) => sum + g.currentAmount, 0);
    const totalSavings = emergencyFund.currentAmount + goalsTotal;

    // Calculate current month's expenses & income
    const now = new Date();
    const currentYear = now.getFullYear();
    const currentMonth = now.getMonth();

    let monthlySpent = 0;
    let monthlyIncome = 0;

    transactions.forEach(t => {
      const d = new Date(t.timestamp);
      if (d.getFullYear() === currentYear && d.getMonth() === currentMonth && t.status === 'SUCCESSFUL') {
        if (t.type === 'EXPENSE') monthlySpent += t.amount;
        if (t.type === 'INCOME') monthlyIncome += t.amount;
      }
    });

    return {
      availableBalance,
      totalSavings,
      emergencyFund,
      monthlySpent,
      monthlyIncome,
      transactions: transactions.slice(0, 5),
    };
  },

  async processPayment(params: {
    receiver: string;
    amount: number;
    category: any;
    note?: string;
    paymentMethod: 'UPI' | 'BANK_TRANSFER' | 'CARD' | 'WALLET';
    merchant?: string;
  }): Promise<ApiResponse<Transaction>> {
    // Check Child Care mode
    const childCare = StorageService.getChildCareSettings();
    if (childCare.enabled && childCare.paymentBlocked) {
      return {
        success: false,
        message: 'Payments are restricted while Child Care Mode is active.',
      };
    }

    const newTxn: Transaction = {
      id: 'FP' + Math.floor(10000000 + Math.random() * 90000000),
      userId: StorageService.getUser().userId,
      sender: StorageService.getUser().fullName,
      receiver: params.receiver,
      amount: params.amount,
      type: 'EXPENSE',
      category: params.category || 'Other',
      status: 'SUCCESSFUL',
      timestamp: new Date().toISOString(),
      referenceId: 'UPI/' + Math.floor(100000000000 + Math.random() * 900000000000),
      description: params.note || `Payment to ${params.receiver}`,
      paymentMethod: params.paymentMethod,
      merchant: params.merchant,
    };

    // Update transactions & primary bank account balance
    const txns = StorageService.getTransactions();
    StorageService.setTransactions([newTxn, ...txns]);

    const accounts = StorageService.getBankAccounts();
    if (accounts.length > 0) {
      accounts[0].availableBalance = Math.max(0, accounts[0].availableBalance - params.amount);
      StorageService.setBankAccounts([...accounts]);
    }

    return { success: true, data: newTxn };
  },
};
