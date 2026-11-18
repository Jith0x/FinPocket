import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'bank_sms_parser_service.dart';

class DetectedBillItem {
  final String id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final String category;
  final bool isEmi;
  final String rawSnippet;

  DetectedBillItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.category,
    required this.isEmi,
    required this.rawSnippet,
  });
}

class SmartBillDetectorService {
  /// Scans device SMS for real pending utility, broadband, credit card bills & loan EMIs.
  static Future<List<DetectedBillItem>> scanForBillsAndEmis({
    List<Transaction>? localTransactions,
  }) async {
    final List<DetectedBillItem> detected = [];
    final seenKeys = <String>{};

    try {
      final rawSmsList = await BankSmsParserService.fetchRawSms(limit: 300);

      for (final msg in rawSmsList) {
        final address = (msg['address'] ?? '').toUpperCase();
        final body = (msg['body'] ?? '').trim();
        final bodyLower = body.toLowerCase();

        if (body.isEmpty) continue;

        // Skip standard OTPs, debit transaction confirmations (unless mentioning EMI/Bill due)
        if (bodyLower.contains('otp') || bodyLower.contains('verification code')) {
          continue;
        }

        // 1. Check for EMI / Loan due notifications
        final isEmiKeywords = bodyLower.contains('emi') ||
            bodyLower.contains('loan a/c') ||
            bodyLower.contains('loan account') ||
            bodyLower.contains('loan installment') ||
            bodyLower.contains('bajaj finserv') ||
            bodyLower.contains('bajaj finance') ||
            bodyLower.contains('home loan') ||
            bodyLower.contains('car loan') ||
            bodyLower.contains('personal loan');

        final isDueMentioned = bodyLower.contains('due on') ||
            bodyLower.contains('due date') ||
            bodyLower.contains('is due') ||
            bodyLower.contains('scheduled for') ||
            bodyLower.contains('auto debit of') ||
            bodyLower.contains('will be debited') ||
            bodyLower.contains('total amount due') ||
            bodyLower.contains('bill generated') ||
            bodyLower.contains('bill due');

        if (isEmiKeywords && isDueMentioned) {
          final amt = _extractAmount(body);
          if (amt != null && amt > 0) {
            final dueDate = _extractDueDate(body) ?? DateTime.now().add(const Duration(days: 7));
            final title = _extractLoanTitle(body, address);
            final key = '${title.toLowerCase()}_${amt.toInt()}';

            if (!seenKeys.contains(key)) {
              seenKeys.add(key);
              detected.add(DetectedBillItem(
                id: 'detected_emi_${DateTime.now().millisecondsSinceEpoch}_${detected.length}',
                title: title,
                amount: amt,
                dueDate: dueDate,
                category: 'EMI / Loan',
                isEmi: true,
                rawSnippet: body.length > 100 ? '${body.substring(0, 97)}...' : body,
              ));
            }
          }
          continue;
        }

        // 2. Check for Utility, Broadband, and Credit Card bills
        final isBillKeywords = bodyLower.contains('electricity') ||
            bodyLower.contains('bescom') ||
            bodyLower.contains('tneb') ||
            bodyLower.contains('msedcl') ||
            bodyLower.contains('broadband') ||
            bodyLower.contains('airtel') ||
            bodyLower.contains('jio') ||
            bodyLower.contains('act fibernet') ||
            bodyLower.contains('credit card') ||
            bodyLower.contains('card ending') ||
            bodyLower.contains('total amount due') ||
            bodyLower.contains('water bill') ||
            bodyLower.contains('piped gas') ||
            bodyLower.contains('bill of rs') ||
            bodyLower.contains('bill generated');

        if (isBillKeywords && (isDueMentioned || bodyLower.contains('amount due'))) {
          final amt = _extractAmount(body);
          if (amt != null && amt > 0) {
            final dueDate = _extractDueDate(body) ?? DateTime.now().add(const Duration(days: 5));
            final info = _extractBillTitleAndCategory(body, address);
            final key = '${info['title']!.toLowerCase()}_${amt.toInt()}';

            if (!seenKeys.contains(key)) {
              seenKeys.add(key);
              detected.add(DetectedBillItem(
                id: 'detected_bill_${DateTime.now().millisecondsSinceEpoch}_${detected.length}',
                title: info['title']!,
                amount: amt,
                dueDate: dueDate,
                category: info['category']!,
                isEmi: false,
                rawSnippet: body.length > 100 ? '${body.substring(0, 97)}...' : body,
              ));
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[SmartBillDetector] Scan error: $e');
    }

    // Also check local transactions if any explicitly represent EMI payments to suggest tracking
    if (localTransactions != null && localTransactions.isNotEmpty) {
      for (final tx in localTransactions) {
        if (tx.category == TransactionCategory.EMI && tx.amount > 0) {
          final title = tx.merchant ?? tx.receiver;
          final key = '${title.toLowerCase()}_${tx.amount.toInt()}';
          if (title.isNotEmpty && !seenKeys.contains(key)) {
            seenKeys.add(key);
            detected.add(DetectedBillItem(
              id: 'detected_tx_emi_${tx.id}',
              title: title,
              amount: tx.amount,
              dueDate: tx.date.add(const Duration(days: 30)),
              category: 'EMI / Loan',
              isEmi: true,
              rawSnippet: 'Found from your bank statement payment of ₹${tx.amount.toStringAsFixed(0)}',
            ));
          }
        }
      }
    }

    return detected;
  }

  static double? _extractAmount(String text) {
    // Matches Rs. 1,450 or INR 1450 or Rs 4500.00
    final patterns = [
      RegExp(r'(?:(?:total\s+amount\s+due|min(?:\.?|\s+amount)\s+due|emi(?:\s+amount)?|bill\s+amount|amount\s+due|of)\s*[:\-]?\s*(?:rs\.?|inr)?\s*)([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false),
      RegExp(r'(?:rs\.?|inr)\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false),
    ];

    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        final clean = m.group(1)?.replaceAll(',', '');
        final val = double.tryParse(clean ?? '');
        if (val != null && val > 0 && val < 10000000) {
          return val;
        }
      }
    }
    return null;
  }

  static DateTime? _extractDueDate(String text) {
    try {
      // Matches: due on 15-Nov-2024, due by 15/11/2024, due: 05-11-2024
      final regexDate = RegExp(
        r'(?:due\s+(?:on|by|date)[:\s]+)([0-9]{1,2})[-/\.]([0-9]{1,2}|[a-zA-Z]{3,9})(?:[-/\.]([0-9]{2,4}))?',
        caseSensitive: false,
      );
      final match = regexDate.firstMatch(text);
      if (match != null) {
        final day = int.tryParse(match.group(1) ?? '1') ?? 1;
        final monthStr = match.group(2) ?? '';
        final yearStr = match.group(3);

        int month = 1;
        final numericMonth = int.tryParse(monthStr);
        if (numericMonth != null) {
          month = numericMonth;
        } else {
          final mLower = monthStr.toLowerCase();
          const months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
          for (int i = 0; i < months.length; i++) {
            if (mLower.startsWith(months[i])) {
              month = i + 1;
              break;
            }
          }
        }

        int year = DateTime.now().year;
        if (yearStr != null) {
          final parsedYear = int.tryParse(yearStr);
          if (parsedYear != null) {
            year = parsedYear < 100 ? 2000 + parsedYear : parsedYear;
          }
        }

        final candidate = DateTime(year, month, day);
        if (candidate.isAfter(DateTime.now().subtract(const Duration(days: 30)))) {
          return candidate;
        }
      }
    } catch (_) {}
    return null;
  }

  static String _extractLoanTitle(String body, String address) {
    final lower = body.toLowerCase();
    if (lower.contains('bajaj finserv') || lower.contains('bajaj finance')) return 'Bajaj Finserv EMI';
    if (lower.contains('home loan')) return 'Home Loan EMI';
    if (lower.contains('car loan')) return 'Car Loan EMI';
    if (lower.contains('kreditbee')) return 'KreditBee Loan';
    if (lower.contains('zestmoney')) return 'ZestMoney EMI';
    if (lower.contains('tvs credit')) return 'TVS Credit Loan';
    if (address.contains('HDFC')) return 'HDFC Bank Loan EMI';
    if (address.contains('SBI')) return 'SBI Loan EMI';
    if (address.contains('ICICI')) return 'ICICI Bank Loan EMI';
    if (address.contains('AXIS')) return 'Axis Bank Loan EMI';
    if (address.contains('KOTAK')) return 'Kotak Loan EMI';
    return 'Bank Loan EMI';
  }

  static Map<String, String> _extractBillTitleAndCategory(String body, String address) {
    final lower = body.toLowerCase();
    if (lower.contains('bescom') || lower.contains('electricity') || lower.contains('tneb') || lower.contains('msedcl')) {
      return {'title': 'Electricity Bill', 'category': 'Utilities'};
    }
    if (lower.contains('airtel')) {
      return {'title': 'Airtel Broadband / Wi-Fi', 'category': 'Broadband'};
    }
    if (lower.contains('jio') || lower.contains('jiofiber')) {
      return {'title': 'JioFiber Bill', 'category': 'Broadband'};
    }
    if (lower.contains('act fibernet')) {
      return {'title': 'ACT Fibernet Bill', 'category': 'Broadband'};
    }
    if (lower.contains('credit card') || lower.contains('sbi card') || lower.contains('total amount due')) {
      return {'title': 'Credit Card Bill', 'category': 'Credit Card'};
    }
    if (lower.contains('gas')) {
      return {'title': 'Piped Gas Bill', 'category': 'Utilities'};
    }
    if (lower.contains('water')) {
      return {'title': 'Water Board Bill', 'category': 'Utilities'};
    }
    return {'title': 'Monthly Bill', 'category': 'Utilities'};
  }
}
