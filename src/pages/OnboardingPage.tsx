import React, { useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { useLanguage } from '../contexts/LanguageContext';
import { Shield, Sparkles, TrendingUp, Lock, FileText, ArrowRight, Check } from 'lucide-react';

interface OnboardingPageProps {
  onComplete: () => void;
}

const steps = [
  {
    icon: Sparkles,
    title: 'Your Money. Your Control.',
    desc: 'Store, manage, and track all your money with military-grade financial security in one unified mobile wallet.',
    color: '#14b8a6',
  },
  {
    icon: TrendingUp,
    title: 'Track Every Transaction.',
    desc: 'Instant UPI payments, real-time transaction categorisation, and intelligent long-term monthly analytics.',
    color: '#0ea5e9',
  },
  {
    icon: Lock,
    title: 'Build Your Emergency Fund.',
    desc: 'Grow a locked emergency buffer that safeguards your financial future from unplanned expenses.',
    color: '#8b5cf6',
  },
  {
    icon: Shield,
    title: 'Understand Your Spending.',
    desc: 'Personalized AI financial insights, health scores, and smart daily saving suggestions tailored for you.',
    color: '#10b981',
  },
  {
    icon: FileText,
    title: 'Secure Your Important Documents.',
    desc: 'Encrypted document vault for Aadhaar, PAN, Driving Licence, and Passport with automated expiry reminders.',
    color: '#f59e0b',
  },
];

export const OnboardingPage: React.FC<OnboardingPageProps> = ({ onComplete }) => {
  const { register, loginWithGoogle, loginWithMeta } = useAuth();
  const { availableLanguages, language, setLanguage } = useLanguage();

  const [currentStep, setCurrentStep] = useState<number>(0);
  const [showRegisterForm, setShowRegisterForm] = useState<boolean>(false);

  const [fullName, setFullName] = useState('Jithendra Sureddy');
  const [email, setEmail] = useState('jithendra@finpocket.com');
  const [phone, setPhone] = useState('+91 98765 43210');
  const [password, setPassword] = useState('Finpocket@123');
  const [pin, setPin] = useState('1234');
  const [error, setError] = useState<string | null>(null);

  const handleNext = () => {
    if (currentStep < steps.length - 1) {
      setCurrentStep(prev => prev + 1);
    } else {
      setShowRegisterForm(true);
    }
  };

  const handleRegisterSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!fullName.trim() || !email.trim() || !pin.trim()) {
      setError('Please fill in all required fields.');
      return;
    }
    if (pin.length !== 4) {
      setError('PIN must be exactly 4 digits.');
      return;
    }

    const success = await register(fullName, email, phone, password, pin);
    if (success) {
      onComplete();
    }
  };

  const StepIcon = steps[currentStep].icon;

  return (
    <div
      style={{
        minHeight: '100vh',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'space-between',
        padding: '24px 20px',
        background: 'linear-gradient(160deg, #0b1120 0%, #111e38 50%, #0b1120 100%)',
        color: '#f8fafc',
      }}
    >
      {/* Top Language Switcher */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <div
            style={{
              width: '32px',
              height: '32px',
              borderRadius: '8px',
              background: 'linear-gradient(135deg, #14b8a6, #0ea5e9)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontWeight: 800,
              fontSize: '16px',
            }}
          >
            FP
          </div>
          <span style={{ fontWeight: 800, fontSize: '16px', letterSpacing: '-0.3px' }}>FinPocket</span>
        </div>

        <select
          value={language}
          onChange={e => setLanguage(e.target.value as any)}
          style={{
            background: 'rgba(30, 41, 59, 0.8)',
            color: '#94a3b8',
            border: '1px solid rgba(148, 163, 184, 0.2)',
            borderRadius: '12px',
            padding: '4px 8px',
            fontSize: '12px',
            outline: 'none',
          }}
        >
          {availableLanguages.map(l => (
            <option key={l.code} value={l.code}>
              {l.nativeName}
            </option>
          ))}
        </select>
      </div>

      {!showRegisterForm ? (
        <div style={{ textAlign: 'center', margin: '40px 0' }} className="animate-fade">
          <div
            style={{
              width: '90px',
              height: '90px',
              borderRadius: '50%',
              background: `rgba(20, 184, 166, 0.15)`,
              color: steps[currentStep].color,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              margin: '0 auto 28px auto',
              boxShadow: `0 0 40px rgba(20, 184, 166, 0.3)`,
            }}
          >
            <StepIcon size={46} />
          </div>

          <h2 style={{ fontSize: '24px', fontWeight: 800, margin: '0 0 12px 0', lineHeight: '1.3' }}>
            {steps[currentStep].title}
          </h2>

          <p style={{ fontSize: '14px', color: '#94a3b8', lineHeight: '1.6', maxWidth: '320px', margin: '0 auto' }}>
            {steps[currentStep].desc}
          </p>

          {/* Dots Indicator */}
          <div style={{ display: 'flex', justifyContent: 'center', gap: '8px', marginTop: '36px' }}>
            {steps.map((_, i) => (
              <div
                key={i}
                style={{
                  width: i === currentStep ? '24px' : '8px',
                  height: '8px',
                  borderRadius: '4px',
                  backgroundColor: i === currentStep ? '#14b8a6' : 'rgba(148, 163, 184, 0.3)',
                  transition: 'all 0.3s ease',
                }}
              />
            ))}
          </div>
        </div>
      ) : (
        <div className="animate-fade" style={{ margin: '20px 0' }}>
          <h2 style={{ fontSize: '22px', fontWeight: 800, margin: '0 0 6px 0' }}>Create Your Account</h2>
          <p style={{ fontSize: '13px', color: '#94a3b8', margin: '0 0 20px 0' }}>
            Setup your secure FinPocket credentials and PIN.
          </p>

          {error && (
            <div style={{ background: 'rgba(239, 68, 68, 0.2)', color: '#ef4444', padding: '10px', borderRadius: '10px', fontSize: '12px', marginBottom: '14px' }}>
              {error}
            </div>
          )}

          <form onSubmit={handleRegisterSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
            <div>
              <label style={{ display: 'block', fontSize: '12px', color: '#94a3b8', marginBottom: '4px' }}>Full Name</label>
              <input className="fp-input" value={fullName} onChange={e => setFullName(e.target.value)} required />
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '12px', color: '#94a3b8', marginBottom: '4px' }}>Email Address</label>
              <input type="email" className="fp-input" value={email} onChange={e => setEmail(e.target.value)} required />
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '12px', color: '#94a3b8', marginBottom: '4px' }}>Mobile Number</label>
              <input className="fp-input" value={phone} onChange={e => setPhone(e.target.value)} />
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '12px', color: '#94a3b8', marginBottom: '4px' }}>Create 4-Digit Security PIN</label>
              <input
                type="password"
                maxLength={4}
                className="fp-input"
                style={{ letterSpacing: '8px', fontSize: '18px', textAlign: 'center' }}
                value={pin}
                onChange={e => setPin(e.target.value)}
                placeholder="••••"
                required
              />
            </div>

            <button type="submit" className="btn-primary" style={{ marginTop: '12px' }}>
              <Check size={18} />
              <span>Complete Setup & Enter FinPocket</span>
            </button>

            {/* SSO Options: Google & Meta */}
            <div style={{ marginTop: '16px', textAlign: 'center' }}>
              <div style={{ display: 'flex', alignItems: 'center', margin: '14px 0', gap: '8px' }}>
                <div style={{ flex: 1, height: '1px', background: 'rgba(148, 163, 184, 0.2)' }} />
                <span style={{ fontSize: '11px', color: '#94a3b8' }}>Or continue with SSO</span>
                <div style={{ flex: 1, height: '1px', background: 'rgba(148, 163, 184, 0.2)' }} />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
                <button
                  type="button"
                  onClick={async () => {
                    const ok = await loginWithGoogle();
                    if (ok) onComplete();
                  }}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '8px',
                    padding: '10px',
                    borderRadius: '12px',
                    background: 'rgba(30, 41, 59, 0.8)',
                    border: '1px solid rgba(148, 163, 184, 0.25)',
                    color: '#f8fafc',
                    fontSize: '12px',
                    fontWeight: 600,
                    cursor: 'pointer',
                  }}
                >
                  <span style={{ fontSize: '16px' }}>🇬</span>
                  <span>Google</span>
                </button>

                <button
                  type="button"
                  onClick={async () => {
                    const ok = await loginWithMeta();
                    if (ok) onComplete();
                  }}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '8px',
                    padding: '10px',
                    borderRadius: '12px',
                    background: 'rgba(24, 119, 242, 0.15)',
                    border: '1px solid rgba(24, 119, 242, 0.4)',
                    color: '#60a5fa',
                    fontSize: '12px',
                    fontWeight: 600,
                    cursor: 'pointer',
                  }}
                >
                  <span style={{ fontSize: '16px', fontWeight: 'bold' }}>f</span>
                  <span>Meta SSO</span>
                </button>
              </div>
            </div>
          </form>
        </div>
      )}

      {!showRegisterForm ? (
        <div style={{ display: 'flex', gap: '12px' }}>
          <button
            onClick={() => setShowRegisterForm(true)}
            style={{
              background: 'none',
              border: 'none',
              color: '#94a3b8',
              fontSize: '14px',
              fontWeight: 600,
              cursor: 'pointer',
              padding: '12px',
            }}
          >
            Skip
          </button>
          <button className="btn-primary" onClick={handleNext} style={{ flex: 1 }}>
            <span>{currentStep === steps.length - 1 ? 'Get Started' : 'Next'}</span>
            <ArrowRight size={16} />
          </button>
        </div>
      ) : null}
    </div>
  );
};
