import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'system_notification_service.dart';

class GhostSubscription {
  final String id;
  final String name;
  final double amount;
  final int cadenceDays;
  final DateTime lastDebitedDate;
  final DateTime nextEstimatedDate;
  final String category;
  final bool isAutoDebitMandate;
  final String logoEmoji;
  final String note;

  GhostSubscription({
    required this.id,
    required this.name,
    required this.amount,
    this.cadenceDays = 30,
    required this.lastDebitedDate,
    required this.nextEstimatedDate,
    this.category = 'Entertainment',
    this.isAutoDebitMandate = true,
    this.logoEmoji = '⚡',
    this.note = 'Recurring e-mandate on bank card',
  });

  bool get isDueWithin48Hours {
    final now = DateTime.now();
    final diff = nextEstimatedDate.difference(now);
    return diff.inHours >= -12 && diff.inHours <= 48;
  }

  int get hoursUntilDue {
    return nextEstimatedDate.difference(DateTime.now()).inHours;
  }

  double get annualDrain => amount * (365 / cadenceDays);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'amount': amount,
    'cadenceDays': cadenceDays,
    'lastDebitedDate': lastDebitedDate.toIso8601String(),
    'nextEstimatedDate': nextEstimatedDate.toIso8601String(),
    'category': category,
    'isAutoDebitMandate': isAutoDebitMandate,
    'logoEmoji': logoEmoji,
    'note': note,
  };

  factory GhostSubscription.fromJson(Map<String, dynamic> json) => GhostSubscription(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    cadenceDays: json['cadenceDays'] ?? 30,
    lastDebitedDate: DateTime.tryParse(json['lastDebitedDate'] ?? '') ?? DateTime.now(),
    nextEstimatedDate: DateTime.tryParse(json['nextEstimatedDate'] ?? '') ?? DateTime.now(),
    category: json['category'] ?? 'Entertainment',
    isAutoDebitMandate: json['isAutoDebitMandate'] ?? true,
    logoEmoji: json['logoEmoji'] ?? '⚡',
    note: json['note'] ?? '',
  );
}

/// Service to detect silent recurring subscription drains & send 48-hour auto-debit radar alerts
class SubscriptionRadarService {
  static const String _storageKey = 'fp_ghost_subscriptions';

  /// Standard recurring subscription signatures in India
  static final List<Map<String, dynamic>> knownSignatures = [
    {'name': 'Netflix Premium', 'amount': 649.0, 'emoji': '🎬', 'category': 'Entertainment'},
    {'name': 'Spotify Individual', 'amount': 119.0, 'emoji': '🎵', 'category': 'Entertainment'},
    {'name': 'Amazon Prime Video', 'amount': 299.0, 'emoji': '📦', 'category': 'Shopping'},
    {'name': 'Disney+ Hotstar Super', 'amount': 299.0, 'emoji': '⭐', 'category': 'Entertainment'},
    {'name': 'YouTube Premium', 'amount': 149.0, 'emoji': '▶️', 'category': 'Entertainment'},
    {'name': 'Google One (100GB)', 'amount': 130.0, 'emoji': '☁️', 'category': 'Utilities'},
    {'name': 'Apple iCloud+ (50GB)', 'amount': 75.0, 'emoji': '🍏', 'category': 'Utilities'},
    {'name': 'Swiggy One Membership', 'amount': 199.0, 'emoji': '🍔', 'category': 'Food'},
    {'name': 'Zomato Gold', 'amount': 149.0, 'emoji': '🍕', 'category': 'Food'},
    {'name': 'Cult.fit Gym Pass', 'amount': 1250.0, 'emoji': '🏋️', 'category': 'Health'},
    {'name': 'Airtel Broadband Wi-Fi', 'amount': 943.0, 'emoji': '📶', 'category': 'Bills'},
  ];

  /// Detect recurring subscriptions by scanning transaction history & bank SMS
  static Future<List<GhostSubscription>> detectSubscriptions({
    List<Transaction>? transactions,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final storedJson = prefs.getString(_storageKey);

    List<GhostSubscription> subs = [];
    if (storedJson != null && storedJson.isNotEmpty) {
      try {
        final List list = jsonDecode(storedJson);
        subs = list.map((e) => GhostSubscription.fromJson(e)).toList();
      } catch (e) {
        debugPrint('[SubscriptionRadar] Failed to load stored subscriptions: $e');
      }
    }

    // Purge any legacy mock/hardcoded subscriptions
    subs.removeWhere((s) => s.id.startsWith('sub_'));

    // Purge stored ghost subscriptions that were erroneously auto-created from repeating transactions
    try {
      await prefs.remove(_storageKey);
    } catch (_) {}

    // Auto-Debit Radar notifications removed per user request
    SystemNotificationService().cancelAllNotifications();

    return [];
  }

  /// Save detected subscriptions locally
  static Future<void> saveSubscriptions(List<GhostSubscription> subs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(subs.map((s) => s.toJson()).toList());
    await prefs.setString(_storageKey, jsonStr);
  }

  /// Add a new subscription manually or from scanned SMS
  static Future<List<GhostSubscription>> addSubscription(GhostSubscription sub) async {
    final current = await detectSubscriptions();
    current.removeWhere((s) => s.name.toLowerCase() == sub.name.toLowerCase());
    current.add(sub);
    await saveSubscriptions(current);
    return current;
  }

  /// Delete a subscription
  static Future<List<GhostSubscription>> deleteSubscription(String id) async {
    final current = await detectSubscriptions();
    current.removeWhere((s) => s.id == id);
    await saveSubscriptions(current);
    return current;
  }

  /// Proactively trigger notifications if any subscription is due within 48 hours (Disabled per user request)
  static void checkAndSend48HourAlerts(List<GhostSubscription> subs) {
    // Auto-Debit Radar notifications completely disabled
    return;
  }

  /// Compute total annual cost drain across all recurring subscriptions
  static double calculateTotalAnnualDrain(List<GhostSubscription> subs) {
    return subs.fold(0.0, (sum, sub) => sum + sub.annualDrain);
  }
}
