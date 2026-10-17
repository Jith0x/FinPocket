import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finpocket_app/config/app_config.dart';
import 'package:finpocket_app/providers/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('User Pay Spending Limit & Allocation Tests', () {
    test('setUserPayBudget sets income, spend limit and calculates surplus correctly', () async {
      SharedPreferences.setMockInitialValues({});
      AppConfig.environment = AppEnvironment.test;
      final state = AppState();

      // Initially null
      expect(state.userPayIncome, isNull);
      expect(state.userPaySpendLimit, isNull);
      expect(state.surplusForOtherSections, 0.0);

      // Set ₹50,000 monthly pay with ₹20,000 spending limit
      await state.setUserPayBudget(income: 50000.0, spendLimit: 20000.0);

      expect(state.userPayIncome, 50000.0);
      expect(state.userPaySpendLimit, 20000.0);
      // Surplus to transfer to savings / other sections should be 50,000 - 20,000 = 30,000
      expect(state.surplusForOtherSections, 30000.0);

      // Verify persistence in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('finpocket_user_pay_income_v1'), 50000.0);
      expect(prefs.getDouble('finpocket_user_pay_spend_limit_v1'), 20000.0);
    });

    test('wouldExceedPaySpendLimit flags transactions that breach limit', () async {
      SharedPreferences.setMockInitialValues({});
      AppConfig.environment = AppEnvironment.test;
      final state = AppState();

      await state.setUserPayBudget(income: 40000.0, spendLimit: 15000.0);

      // Within limit
      expect(state.wouldExceedPaySpendLimit(5000.0), isFalse);
      expect(state.wouldExceedPaySpendLimit(15000.0), isFalse);

      // Exceeds limit
      expect(state.wouldExceedPaySpendLimit(15001.0), isTrue);
      expect(state.wouldExceedPaySpendLimit(25000.0), isTrue);
    });

    test('clearUserPayBudget clears state and preferences', () async {
      SharedPreferences.setMockInitialValues({
        'finpocket_user_pay_income_v1': 60000.0,
        'finpocket_user_pay_spend_limit_v1': 25000.0,
      });
      AppConfig.environment = AppEnvironment.test;
      final state = AppState();

      await state.setUserPayBudget(income: 60000.0, spendLimit: 25000.0);
      expect(state.userPaySpendLimit, 25000.0);

      await state.clearUserPayBudget();
      expect(state.userPayIncome, isNull);
      expect(state.userPaySpendLimit, isNull);
      expect(state.surplusForOtherSections, 0.0);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('finpocket_user_pay_income_v1'), isNull);
      expect(prefs.getDouble('finpocket_user_pay_spend_limit_v1'), isNull);
    });
  });
}
