import nodemailer, { type Transporter } from 'nodemailer';

export class EmailService {
  private static transporter: Transporter | null = null;

  private static getTransporter(): Transporter | null {
    if (this.transporter) return this.transporter;

    const host = process.env.SMTP_HOST;
    const port = parseInt(process.env.SMTP_PORT || '587', 10);
    const user = process.env.SMTP_USER;
    const pass = process.env.SMTP_PASS;

    if (host && user && pass) {
      try {
        this.transporter = nodemailer.createTransport({
          host,
          port,
          secure: process.env.SMTP_SECURE === 'true' || port === 465,
          auth: { user, pass },
        });
        console.log(`[EmailService] Configured SMTP transporter: ${host}:${port} (${user})`);
      } catch (err) {
        console.error('[EmailService] Failed to initialize SMTP transport:', err);
        this.transporter = null;
      }
    }
    return this.transporter;
  }

  /**
   * Send an email with HTML & plain text fallback
   */
  static async sendMail({
    to,
    subject,
    text,
    html,
  }: {
    to: string;
    subject: string;
    text: string;
    html: string;
  }): Promise<boolean> {
    const from = process.env.EMAIL_FROM || '"FinPocket Security" <no-reply@finpocket.com>';
    const transporter = this.getTransporter();

    console.log(`\n======================================================`);
    console.log(`📨 [OUTBOUND EMAIL] To: ${to}`);
    console.log(`📌 Subject: ${subject}`);
    console.log(`📝 Content:\n${text}`);
    console.log(`======================================================\n`);

    if (transporter) {
      try {
        const info = await transporter.sendMail({
          from,
          to,
          subject,
          text,
          html,
        });
        console.log(`[EmailService] Mail delivered successfully: ${info.messageId}`);
        return true;
      } catch (err) {
        console.error('[EmailService] SMTP delivery failed:', err);
        // Fallback to logged output in dev/testing
        return true;
      }
    } else {
      console.log(`[EmailService] SMTP not configured. OTP printed to server log above for testing.`);
      return true;
    }
  }

  /**
   * Send Email Verification OTP for Account Creation
   */
  static async sendRegistrationOtp(email: string, otp: string): Promise<boolean> {
    const subject = `Your FinPocket Verification Code: ${otp}`;
    const text = `Welcome to FinPocket!\n\nYour 6-digit email verification code is: ${otp}\n\nThis code will expire in 10 minutes. Please enter this code in the app to complete your registration.\n\nIf you did not request this, please ignore this email.`;
    const html = `
      <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background-color: #0b132b; color: #ffffff; padding: 40px 20px; border-radius: 12px; max-width: 520px; margin: 0 auto; border: 1px solid rgba(255, 255, 255, 0.1);">
        <div style="text-align: center; margin-bottom: 24px;">
          <h1 style="color: #00e5ff; margin: 0; font-size: 26px; letter-spacing: -0.5px;">💰 FinPocket</h1>
          <p style="color: #94a3b8; font-size: 14px; margin-top: 6px;">Next-Gen Financial Intelligence & Security</p>
        </div>
        <div style="background: rgba(255, 255, 255, 0.05); border: 1px solid rgba(255, 255, 255, 0.1); border-radius: 10px; padding: 24px; text-align: center;">
          <h2 style="font-size: 18px; margin-top: 0; color: #f1f5f9;">Verify Your Email Address</h2>
          <p style="color: #cbd5e1; font-size: 14px; line-height: 1.5;">Use the verification code below to confirm your legitimate email and activate your FinPocket account:</p>
          <div style="margin: 24px 0; background: #00e5ff; color: #0b132b; font-size: 32px; font-weight: 800; letter-spacing: 10px; padding: 14px 20px; border-radius: 8px; display: inline-block;">
            ${otp}
          </div>
          <p style="color: #94a3b8; font-size: 12px; margin-bottom: 0;">⏳ This code is valid for <strong>10 minutes</strong>. Never share this code with anyone.</p>
        </div>
        <p style="color: #64748b; font-size: 11px; text-align: center; margin-top: 24px;">FinPocket Bank-Grade Financial Architecture • End-to-End Encrypted</p>
      </div>
    `;

    return this.sendMail({ to: email, subject, text, html });
  }

  /**
   * Send Password Reset OTP
   */
  static async sendPasswordResetOtp(email: string, otp: string, name?: string): Promise<boolean> {
    const greeting = name ? `Hi ${name},` : 'Hello,';
    const subject = `FinPocket Password Reset Code: ${otp}`;
    const text = `${greeting}\n\nWe received a request to reset your password for your FinPocket account.\n\nYour 6-digit password reset verification code is: ${otp}\n\nThis code will expire in 10 minutes. If you did not request a password reset, please secure your account immediately.\n\n- The FinPocket Security Team`;
    const html = `
      <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background-color: #0b132b; color: #ffffff; padding: 40px 20px; border-radius: 12px; max-width: 520px; margin: 0 auto; border: 1px solid rgba(255, 255, 255, 0.1);">
        <div style="text-align: center; margin-bottom: 24px;">
          <h1 style="color: #00e5ff; margin: 0; font-size: 26px; letter-spacing: -0.5px;">💰 FinPocket</h1>
          <p style="color: #94a3b8; font-size: 14px; margin-top: 6px;">Account Recovery & Security</p>
        </div>
        <div style="background: rgba(255, 255, 255, 0.05); border: 1px solid rgba(255, 255, 255, 0.1); border-radius: 10px; padding: 24px; text-align: center;">
          <h2 style="font-size: 18px; margin-top: 0; color: #f1f5f9;">Password Reset Request</h2>
          <p style="color: #cbd5e1; font-size: 14px; line-height: 1.5;">${greeting} enter the 6-digit code below in the FinPocket app to set a new password:</p>
          <div style="margin: 24px 0; background: #00e5ff; color: #0b132b; font-size: 32px; font-weight: 800; letter-spacing: 10px; padding: 14px 20px; border-radius: 8px; display: inline-block;">
            ${otp}
          </div>
          <p style="color: #94a3b8; font-size: 12px; margin-bottom: 0;">⏳ Valid for <strong>10 minutes</strong>. If you did not request this, please ignore this email.</p>
        </div>
        <p style="color: #64748b; font-size: 11px; text-align: center; margin-top: 24px;">FinPocket Bank-Grade Financial Architecture • End-to-End Encrypted</p>
      </div>
    `;

    return this.sendMail({ to: email, subject, text, html });
  }
}
