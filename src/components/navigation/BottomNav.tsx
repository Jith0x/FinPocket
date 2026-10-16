import React from 'react';
import { useLanguage } from '../../contexts/LanguageContext';
import { Home, ArrowLeftRight, Clock, PiggyBank, User as UserIcon, Send } from 'lucide-react';

export type TabType = 'home' | 'payments' | 'history' | 'savings' | 'profile' | 'bills' | 'vault' | 'ai' | 'childcare' | 'budgets';

interface BottomNavProps {
  activeTab: TabType;
  onChangeTab: (tab: TabType) => void;
  onQuickPay: () => void;
}

export const BottomNav: React.FC<BottomNavProps> = ({ activeTab, onChangeTab, onQuickPay }) => {
  const { t } = useLanguage();

  return (
    <nav className="bottom-nav">
      <button
        className={`nav-item ${activeTab === 'home' ? 'active' : ''}`}
        onClick={() => onChangeTab('home')}
      >
        <Home size={20} />
        <span>{t.navHome}</span>
      </button>

      <button
        className={`nav-item ${activeTab === 'payments' ? 'active' : ''}`}
        onClick={() => onChangeTab('payments')}
      >
        <ArrowLeftRight size={20} />
        <span>{t.navPayments}</span>
      </button>

      {/* Floating Center Pay Button */}
      <button className="nav-pay-btn" onClick={onQuickPay} aria-label="Send Money">
        <Send size={20} />
      </button>

      <button
        className={`nav-item ${activeTab === 'savings' ? 'active' : ''}`}
        onClick={() => onChangeTab('savings')}
      >
        <PiggyBank size={20} />
        <span>{t.navSavings}</span>
      </button>

      <button
        className={`nav-item ${activeTab === 'profile' ? 'active' : ''}`}
        onClick={() => onChangeTab('profile')}
      >
        <UserIcon size={20} />
        <span>{t.navProfile}</span>
      </button>
    </nav>
  );
};
