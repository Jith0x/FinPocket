/**
 * FinPocket Comprehensive Security & Validation Utility
 * Enforces Banking-grade Password Policy, Disposable Email Detection,
 * and Privacy Masking.
 */

// Comprehensive blacklist of temporary and disposable email providers
const DISPOSABLE_EMAIL_DOMAINS = new Set([
  'mailinator.com',
  'tempmail.com',
  'temp-mail.org',
  '10minutemail.com',
  'guerrillamail.com',
  'guerrillamail.net',
  'guerrillamail.org',
  'throwawaymail.com',
  'yopmail.com',
  'sharklasers.com',
  'dispostable.com',
  'getairmail.com',
  'fakemailgenerator.com',
  'trashmail.com',
  'trashmail.net',
  'nada.ltd',
  'mohmal.com',
  'crazymailing.com',
  'inboxkitten.com',
  'fakeinbox.com',
  'burnermail.io',
  'mytemp.email',
  'emailondeck.com',
  'maildrop.cc',
  'generator.email',
  'tempail.com',
  'disposablemail.com',
  'dropmail.me',
  'getnada.com',
  'airmail.news',
  'armyspy.com',
  'cuvox.de',
  'dayrep.com',
  'fleckens.hu',
  'gustr.com',
  'jourrapide.com',
  'rhyta.com',
  'superrito.com',
  'teleworm.us',
  'tinypaste.com'
]);

// Top common insecure passwords blocked outright
const COMMON_WEAK_PASSWORDS = new Set([
  'password', 'password123', 'admin', 'admin123', '12345678', '123456789',
  'qwerty', 'qwerty123', 'welcome', 'welcome123', 'finpocket', 'finpocket123',
  'letmein', 'monkey', 'dragon', 'football', 'master', 'sunshine', 'iloveyou'
]);

export interface PasswordPolicyResult {
  isValid: boolean;
  score: number; // 0 to 4
  strengthLabel: 'Weak' | 'Fair' | 'Good' | 'Strong';
  errors: string[];
}

export function validatePasswordPolicy(password: string, userDetails?: { name?: string; email?: string }): PasswordPolicyResult {
  const errors: string[] = [];
  let score = 0;

  if (!password || typeof password !== 'string') {
    return {
      isValid: false,
      score: 0,
      strengthLabel: 'Weak',
      errors: ['Password is required.']
    };
  }

  // 1. Length Requirement (Min 8, Max 64)
  if (password.length < 8) {
    errors.push('Password must be at least 8 characters long.');
  } else if (password.length >= 12) {
    score += 1;
  }

  // 2. Character Complexity Checks
  const hasUpper = /[A-Z]/.test(password);
  const hasLower = /[a-z]/.test(password);
  const hasDigit = /[0-9]/.test(password);
  const hasSpecial = /[!@#$%^&*()_+\-=[\]{};':"\\|,.<>/?`~]/.test(password);

  if (!hasUpper) errors.push('Must contain at least one uppercase letter (A-Z).');
  if (!hasLower) errors.push('Must contain at least one lowercase letter (a-z).');
  if (!hasDigit) errors.push('Must contain at least one number (0-9).');
  if (!hasSpecial) errors.push('Must contain at least one special character (!@#$%^&*...).');

  const complexityCount = [hasUpper, hasLower, hasDigit, hasSpecial].filter(Boolean).length;
  if (complexityCount >= 3) score += 1;
  if (complexityCount === 4) score += 1;

  // 3. Common Password Rejection
  if (COMMON_WEAK_PASSWORDS.has(password.toLowerCase())) {
    errors.push('This password is too common and easily guessable.');
    score = 0;
  }

  // 4. Personal Information Disallowance
  if (userDetails?.name && userDetails.name.length > 3) {
    const nameParts = userDetails.name.toLowerCase().split(/\s+/);
    for (const part of nameParts) {
      if (part.length >= 3 && password.toLowerCase().includes(part)) {
        errors.push('Password cannot contain parts of your name.');
        break;
      }
    }
  }

  if (userDetails?.email && userDetails.email.includes('@')) {
    const emailPrefix = userDetails.email.split('@')[0].toLowerCase();
    if (emailPrefix.length >= 3 && password.toLowerCase().includes(emailPrefix)) {
      errors.push('Password cannot contain your email username.');
    }
  }

  if (errors.length === 0 && score >= 2) score += 1;
  score = Math.min(4, Math.max(score, errors.length === 0 ? 3 : 1));

  const strengthLabel: 'Weak' | 'Fair' | 'Good' | 'Strong' =
    score >= 4 ? 'Strong' : score >= 3 ? 'Good' : score >= 2 ? 'Fair' : 'Weak';

  return {
    isValid: errors.length === 0,
    score,
    strengthLabel,
    errors
  };
}

export function isDisposableEmail(email: string): boolean {
  if (!email || !email.includes('@')) return false;
  const domain = email.split('@')[1]?.toLowerCase().trim();
  if (!domain) return false;
  return DISPOSABLE_EMAIL_DOMAINS.has(domain);
}

export function maskPhoneNumber(phone?: string | null): string {
  if (!phone) return '';
  const cleaned = phone.replace(/\s+/g, '');
  if (cleaned.length <= 4) return '••••';
  const prefix = cleaned.startsWith('+') ? cleaned.slice(0, 3) : '';
  const lastFour = cleaned.slice(-4);
  return `${prefix} ******${lastFour}`;
}

export function maskName(fullName?: string | null): string {
  if (!fullName) return '';
  const parts = fullName.trim().split(/\s+/);
  return parts.map(part => {
    if (part.length <= 1) return part;
    return part[0] + '*'.repeat(Math.max(1, part.length - 1));
  }).join(' ');
}
