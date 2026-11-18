import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../services/bank_sms_parser_service.dart';
import '../services/local_transaction_storage_service.dart';

/// "Connect Bank Account" flow — mirrors verified bank SMS on-device.
///
/// FinPocket first verifies that this phone receives SMS alerts from the
/// chosen bank (on-device sender-ID check), then mirrors those transactions
/// and balances with zero credentials and 100% privacy.
class ConnectBankModal extends StatefulWidget {
  const ConnectBankModal({super.key});

  @override
  State<ConnectBankModal> createState() => _ConnectBankModalState();
}

class _ConnectBankModalState extends State<ConnectBankModal> {
  static const List<Map<String, dynamic>> _banks = [
    {'code': 'HDFC', 'label': 'HDFC Bank', 'emoji': '🏦', 'sms': ['HDFCBK', 'HDFC']},
    {'code': 'SBIN', 'label': 'State Bank of India', 'emoji': '🏛️', 'sms': ['SBIIN', 'SBIPSG', 'SBI']},
    {'code': 'ICIC', 'label': 'ICICI Bank', 'emoji': '🏢', 'sms': ['ICICIB', 'ICICI']},
    {'code': 'UTIB', 'label': 'Axis Bank', 'emoji': '🏬', 'sms': ['AXISBK', 'AXIS']},
    {'code': 'INDB', 'label': 'Indian Bank', 'emoji': '🏦', 'sms': ['INDBNK', 'INDIAN BANK']},
    {'code': 'KKBK', 'label': 'Kotak Mahindra Bank', 'emoji': '🔰', 'sms': ['KOTAKB', 'KOTAK']},
    {'code': 'PNBS', 'label': 'Punjab National Bank', 'emoji': '🏦', 'sms': ['PNBSMS', 'PNB']},
    {'code': 'CNRB', 'label': 'Canara Bank', 'emoji': '🏛️', 'sms': ['CANBNK', 'CANARA']},
    {'code': 'BARB', 'label': 'Bank of Baroda', 'emoji': '🏢', 'sms': ['BOBMSG', 'BARB', 'BOB']},
    {'code': 'UBIN', 'label': 'Union Bank of India', 'emoji': '🏬', 'sms': ['UBIN', 'UNIONBANK']},
    {'code': 'BKID', 'label': 'Bank of India', 'emoji': '🏦', 'sms': ['BOIIND', 'BOI']},
    {'code': 'IDFB', 'label': 'IDFC First Bank', 'emoji': '💠', 'sms': ['IDFCFB', 'IDFC']},
    {'code': 'YESB', 'label': 'Yes Bank', 'emoji': '🔶', 'sms': ['YESBNK', 'YESBANK']},
    {'code': 'INDUS', 'label': 'IndusInd Bank', 'emoji': '🔷', 'sms': ['INDUSB', 'INDUS']},
    {'code': 'FDRL', 'label': 'Federal Bank', 'emoji': '🟡', 'sms': ['FEDBNK', 'FEDERAL']},
    {'code': 'IBKL', 'label': 'IDBI Bank', 'emoji': '🔷', 'sms': ['IDBIIB', 'IDBI']},
    {'code': 'PAYT', 'label': 'Paytm Payments Bank', 'emoji': '📱', 'sms': ['PAYTMB', 'PAYTM']},
    {'code': 'KVBL', 'label': 'Karur Vysya Bank', 'emoji': '🏛️', 'sms': ['KVBANK', 'KVBSMS', 'KVBLBK', 'KVBBANK', 'KVB', 'KVBL', 'KARUR VYSYA']},
    {'code': 'CBIN', 'label': 'Central Bank of India', 'emoji': '🏦', 'sms': ['CBISMS', 'CENTBK', 'CBIN', 'CENTRAL BANK']},
    {'code': 'IOBA', 'label': 'Indian Overseas Bank', 'emoji': '🌊', 'sms': ['IOBCHN', 'IOBBNK', 'IOBSMS', 'IOBA', 'INDIAN OVERSEAS']},
    {'code': 'UCBA', 'label': 'UCO Bank', 'emoji': '🏛️', 'sms': ['UCOBNK', 'UCOSMS', 'UCBA', 'UCO BANK']},
    {'code': 'SIBL', 'label': 'South Indian Bank', 'emoji': '🌴', 'sms': ['SIBLTD', 'SIBBNK', 'SIBSMS', 'SIB', 'SOUTH INDIAN BANK']},
    {'code': 'MAHB', 'label': 'Bank of Maharashtra', 'emoji': '🏢', 'sms': ['MAHABK', 'BOMBNK', 'MAHB', 'BANK OF MAHARASHTRA']},
    {'code': 'PSIB', 'label': 'Punjab & Sind Bank', 'emoji': '🏦', 'sms': ['PSBBNK', 'PSBSMS', 'PSIB', 'PUNJAB & SIND']},
    {'code': 'RATN', 'label': 'RBL Bank', 'emoji': '🔷', 'sms': ['RBLBNK', 'RATNAK', 'RBLSMS', 'RATN', 'RBL BANK']},
    {'code': 'BDBL', 'label': 'Bandhan Bank', 'emoji': '🤝', 'sms': ['BNDHAN', 'BNDHN', 'BDBLBK', 'BDBL', 'BANDHAN BANK']},
    {'code': 'CIUB', 'label': 'City Union Bank', 'emoji': '🏛️', 'sms': ['CUBBNK', 'CUBSMS', 'CIUB', 'CITY UNION']},
    {'code': 'AUBL', 'label': 'AU Small Finance Bank', 'emoji': '🔶', 'sms': ['AUBANK', 'AUBSMS', 'AUBL', 'AU SMALL']},
    {'code': 'ESFB', 'label': 'Equitas Small Finance Bank', 'emoji': '🔷', 'sms': ['EQITAS', 'EQSMS', 'ESFB', 'EQUITAS']},
    {'code': 'AIRP', 'label': 'Airtel Payments Bank', 'emoji': '📱', 'sms': ['AIRBNK', 'AIRPAY', 'AIRP', 'AIRTEL']},
    {'code': 'IPPB', 'label': 'India Post Payments Bank', 'emoji': '📮', 'sms': ['IPPBMS', 'IPPBBK', 'IPPB', 'INDIA POST']},
    {
      'code': 'OTHER',
      'label': 'My bank isn\u2019t listed',
      'emoji': '🔎',
      'sms': <String>[],
    },
  ];

  static String _lastSelectedBankCode = 'INDB';
  late String _bankCode;
  bool _isConnecting = false;
  String? _error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _bankCode = _lastSelectedBankCode;
  }

  Map<String, dynamic> get _selectedBank => _banks.firstWhere(
        (b) => b['code'] == _bankCode,
        orElse: () => _banks.first,
      );

  /// On-device SMS mirror, verified before any claim is made:
  ///  1. READ_SMS permission is requested.
  ///  2. The inbox is checked for SMS that really come from this bank's sender IDs.
  ///  3. Real transactions and balance are imported on-device.
  Future<void> _mirrorFromSms(Map<String, dynamic> bank) async {
    setState(() {
      _isConnecting = true;
      _error = null;
      _notice = null;
    });

    final label = bank['label'] as String;
    final senderKeys =
        (bank['sms'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
            const <String>[];
    final isOther = bank['code'] == 'OTHER';

    var permitted = await BankSmsParserService.hasSmsPermission();
    if (!permitted) {
      permitted = await BankSmsParserService.requestSmsPermission();
    }
    if (!mounted) return;
    if (!permitted) {
      setState(() {
        _isConnecting = false;
        _error =
            'SMS access is required to read your bank\u2019s messages. '
            'FinPocket reads them only on this phone — grant the permission to continue.';
      });
      return;
    }

    setState(() => _notice = 'Checking this phone for messages from $label\u2026');
    final evidence = await BankSmsParserService.countSmsForBank(label, senderKeys);
    if (!mounted) return;

    if (evidence == 0) {
      final msg = isOther
          ? 'No bank transaction messages were found on this device. You cannot link a bank account without active messages.'
          : 'No account or SMS messages found for $label on this device. You cannot link this bank because you do not have an account with $label on this phone.';
      setState(() {
        _isConnecting = false;
        _notice = null;
        _error = msg;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.bgCardDark
                : AppTheme.bgCardLight,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: AppTheme.danger, size: 24),
                SizedBox(width: 10),
                Text('Account Not Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              msg,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    final state = Provider.of<AppState>(context, listen: false);
    await LocalTransactionStorageService.setVaultConsent(true);
    await LocalTransactionStorageService.setSmsSyncConsent(true);
    final imported = await state.syncBankSmsTransactions(
      forceRequestPermission: true,
    );
    if (!mounted) return;
    setState(() => _isConnecting = false);

    if (imported > 0) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isOther
                ? 'Verified $evidence bank messages on this phone · '
                    '$imported transactions mirrored from bank SMS.'
                : 'Verified $evidence messages from $label on this phone · '
                    '$imported transactions mirrored from bank SMS.',
          ),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      setState(() {
        _notice =
            'Found $evidence message${evidence == 1 ? '' : 's'}'
            '${isOther ? ' from your bank' : ' from $label'} on this phone. '
            'New transaction messages will be imported automatically.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.bgCardDark : AppTheme.bgCardLight;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final mutedText =
        isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Bank Account'),
        backgroundColor: cardColor,
        foregroundColor: AppTheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const Icon(Icons.account_balance_wallet, size: 64, color: AppTheme.primary),
            const SizedBox(height: 16),
            const Text(
              'Connect your bank account',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'FinPocket securely reads official bank transaction alerts directly on this phone to mirror your real balances and transactions with zero credentials and 100% privacy.',
              style: TextStyle(fontSize: 13, color: mutedText, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select your bank',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _bankCode,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    isDense: false,
                    dropdownColor: cardColor,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                    items: [
                      for (final bank in _banks)
                        DropdownMenuItem(
                          value: bank['code'] as String,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(bank['emoji'] as String, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 10),
                              Text(
                                bank['label'] as String,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _bankCode = value;
                          _lastSelectedBankCode = value;
                          _error = null;
                          _notice = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.mark_email_read_outlined, size: 18, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              '${_selectedBank['label']} SMS Mirror',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _bankCode == 'OTHER'
                              ? 'FinPocket checks this phone for official bank transaction messages and mirrors your authentic balance and transactions on-device.'
                              : 'FinPocket verifies this phone receives official SMS alerts from ${_selectedBank['label']}, then mirrors your real balance and transactions on-device. Zero credentials, 100% private.',
                          style: TextStyle(fontSize: 11, color: mutedText, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.danger.withOpacity(0.35)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline, size: 20, color: AppTheme.danger),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: AppTheme.danger,
                                fontSize: 13,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_notice != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _notice!,
                      style: TextStyle(fontSize: 12, color: mutedText, height: 1.3),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            _isConnecting
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: () => _mirrorFromSms(_selectedBank),
                    icon: const Icon(Icons.mark_email_read_outlined, size: 20),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    label: const Text(
                      'Verify & Mirror from Bank SMS',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isConnecting
                  ? null
                  : () => Navigator.pop(context),
              child: const Text('Skip — I’ll do this later'),
            ),
          ],
        ),
      ),
    );
  }
}
