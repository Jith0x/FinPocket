import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../services/smart_bill_detector_service.dart';
import '../theme/app_theme.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  static Future<void> _confirmAndPay(BuildContext context, AppState state, RecurringPayment bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark bill as paid?'),
        content: Text('Mark "${bill.name}" of ₹${bill.amount.toStringAsFixed(0)} as paid?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Mark Paid'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final ok = await state.markBillPaid(bill.id);
    messenger.showSnackBar(
      ok
          ? SnackBar(backgroundColor: AppTheme.success, content: Text('"${bill.name}" marked as paid.'))
          : const SnackBar(
              backgroundColor: Color(0xFFEF4444),
              content: Text('Could not mark this bill as paid. Please try again.'),
            ),
    );
  }

  static Future<void> _deleteEmi(BuildContext context, AppState state, EMILoan emi) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete EMI / Loan?'),
        content: Text('Remove "${emi.loanName}" from your active EMIs?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      state.removeEmiLoan(emi.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${emi.loanName}" removed.')),
        );
      }
    }
  }

  static Future<void> _deleteBill(BuildContext context, AppState state, RecurringPayment bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Bill?'),
        content: Text('Remove "${bill.name}" from your recurring bills?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      state.removeBill(bill.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${bill.name}" removed.')),
        );
      }
    }
  }

  void _openAddModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AddBillOrEmiSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final totalMonthlyEmi = state.emis.fold(0.0, (sum, e) => sum + e.monthlyEMI);
    final totalMonthlyBills = state.bills.fold(0.0, (sum, b) => sum + b.amount);
    final totalMonthlyOutflow = totalMonthlyEmi + totalMonthlyBills;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills & EMI Manager'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () => _openAddModal(context),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Add / Detect', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        onPressed: () => _openAddModal(context),
        icon: const Icon(Icons.add),
        label: const Text('Add EMI / Bill', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP FINANCIAL SUMMARY CARD
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Monthly Obligations',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${state.emis.length + state.bills.length} ITEMS',
                          style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${totalMonthlyOutflow.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Active EMIs', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                              const SizedBox(height: 2),
                              Text('₹${totalMonthlyEmi.toStringAsFixed(0)}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Monthly Bills', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                              const SizedBox(height: 2),
                              Text('₹${totalMonthlyBills.toStringAsFixed(0)}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SECTION 1: ACTIVE EMIS & LOANS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('Active EMIs & Loans', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${state.emis.length}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryLight),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _openAddModal(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add EMI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (state.emis.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.cardDecoration(context),
                child: Column(
                  children: [
                    const Icon(Icons.account_balance_outlined, size: 36, color: Color(0xFF64748B)),
                    const SizedBox(height: 8),
                    const Text('No Active EMIs Tracked', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    const Text(
                      'Add your smartphone, car, or personal loan EMIs to get payment reminders.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _openAddModal(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add EMI / Scan SMS'),
                    ),
                  ],
                ),
              )
            else
              ...state.emis.map((emi) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: AppTheme.cardDecoration(context),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryLight.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.account_balance_outlined, color: AppTheme.primaryLight, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        emi.loanName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Due day: ${emi.dueDayOfMonth}th of every month',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => state.toggleEmiPaidStatus(emi.id),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (emi.isPaidThisMonth ? AppTheme.success : AppTheme.warning).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: (emi.isPaidThisMonth ? AppTheme.success : AppTheme.warning).withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    emi.isPaidThisMonth ? Icons.check_circle : Icons.schedule,
                                    size: 13,
                                    color: emi.isPaidThisMonth ? AppTheme.success : AppTheme.warning,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    emi.isPaidThisMonth ? 'Paid' : 'Due',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: emi.isPaidThisMonth ? AppTheme.success : AppTheme.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF94A3B8)),
                            onPressed: () => _deleteEmi(context, state, emi),
                            tooltip: 'Delete EMI',
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Monthly EMI', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                              const SizedBox(height: 2),
                              Text('₹${emi.monthlyEMI.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.primaryLight)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text('Tenure', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                              const SizedBox(height: 2),
                              Text('${emi.paidMonths}/${emi.totalTenureMonths} Mos',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Remaining Principal', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                              const SizedBox(height: 2),
                              Text('₹${emi.remainingAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 20),

            // SECTION 2: RECURRING BILLS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('Recurring Bills', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${state.bills.length}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryLight),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _openAddModal(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Bill', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (state.bills.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.cardDecoration(context),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 36, color: Color(0xFF64748B)),
                    const SizedBox(height: 8),
                    const Text('No Recurring Bills Added', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    const Text(
                      'Add electricity, Wi-Fi broadband, credit card bills or detect them directly from SMS.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _openAddModal(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Bill / Scan SMS'),
                    ),
                  ],
                ),
              )
            else
              ...state.bills.map((bill) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: AppTheme.cardDecoration(context),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getCategoryIcon(bill.category),
                          color: AppTheme.primaryLight,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(bill.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(
                              '₹${bill.amount.toStringAsFixed(0)} · Due on ${bill.dueDate.day}/${bill.dueDate.month}/${bill.dueDate.year}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                      bill.isPaidThisMonth
                          ? InkWell(
                              onTap: () => state.toggleBillPaidStatus(bill.id),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.success.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                                ),
                                child: const Text('Paid', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.success)),
                              ),
                            )
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _confirmAndPay(context, state, bill),
                              child: const Text('Pay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF94A3B8)),
                        onPressed: () => _deleteBill(context, state, bill),
                        tooltip: 'Delete Bill',
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  static IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('electric') || cat.contains('utility')) return Icons.bolt;
    if (cat.contains('broadband') || cat.contains('wifi') || cat.contains('airtel') || cat.contains('jio')) return Icons.wifi;
    if (cat.contains('credit') || cat.contains('card')) return Icons.credit_card;
    if (cat.contains('rent')) return Icons.home_outlined;
    if (cat.contains('water')) return Icons.water_drop_outlined;
    if (cat.contains('gas')) return Icons.local_fire_department_outlined;
    return Icons.receipt_long;
  }
}

/// Modal Sheet allowing Smart SMS Detection and Manual Add for EMIs and Bills
class _AddBillOrEmiSheet extends StatefulWidget {
  const _AddBillOrEmiSheet();

  @override
  State<_AddBillOrEmiSheet> createState() => _AddBillOrEmiSheetState();
}

class _AddBillOrEmiSheetState extends State<_AddBillOrEmiSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Manual EMI controllers
  final _emiNameCtrl = TextEditingController();
  final _emiAmountCtrl = TextEditingController();
  final _emiRemainingCtrl = TextEditingController();
  final _emiTenureCtrl = TextEditingController(text: '12');
  final _emiDueDayCtrl = TextEditingController(text: '5');

  // Manual Bill controllers
  final _billNameCtrl = TextEditingController();
  final _billAmountCtrl = TextEditingController();
  String _billCategory = 'Utilities';
  DateTime _billDueDate = DateTime.now().add(const Duration(days: 7));

  // Smart Detection state
  bool _isScanning = false;
  List<DetectedBillItem> _detectedItems = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _triggerSmsScan();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emiNameCtrl.dispose();
    _emiAmountCtrl.dispose();
    _emiRemainingCtrl.dispose();
    _emiTenureCtrl.dispose();
    _emiDueDayCtrl.dispose();
    _billNameCtrl.dispose();
    _billAmountCtrl.dispose();
    super.dispose();
  }

  Future<void> _triggerSmsScan() async {
    setState(() {
      _isScanning = true;
    });

    final state = Provider.of<AppState>(context, listen: false);
    final items = await SmartBillDetectorService.scanForBillsAndEmis(
      localTransactions: state.transactions,
    );

    if (mounted) {
      setState(() {
        _detectedItems = items;
        _isScanning = false;
      });
    }
  }

  void _saveManualEmi(AppState state) {
    final name = _emiNameCtrl.text.trim();
    final emiAmt = double.tryParse(_emiAmountCtrl.text.trim()) ?? 0.0;
    final remaining = double.tryParse(_emiRemainingCtrl.text.trim()) ?? (emiAmt * 12);
    final tenure = int.tryParse(_emiTenureCtrl.text.trim()) ?? 12;
    final dueDay = int.tryParse(_emiDueDayCtrl.text.trim()) ?? 5;

    if (name.isEmpty || emiAmt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid loan name and EMI amount.')),
      );
      return;
    }

    final newEmi = EMILoan(
      id: 'emi_${DateTime.now().millisecondsSinceEpoch}',
      loanName: name,
      totalAmount: remaining,
      monthlyEMI: emiAmt,
      totalTenureMonths: tenure,
      paidMonths: 0,
      remainingAmount: remaining,
      interestRate: 10.5,
      nextDueDate: DateTime(DateTime.now().year, DateTime.now().month, dueDay.clamp(1, 28)),
    );

    state.addEmiLoan(newEmi);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: AppTheme.success, content: Text('Loan EMI "$name" added successfully!')),
    );
  }

  void _saveManualBill(AppState state) {
    final name = _billNameCtrl.text.trim();
    final amount = double.tryParse(_billAmountCtrl.text.trim()) ?? 0.0;

    if (name.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid bill name and amount.')),
      );
      return;
    }

    final newBill = RecurringPayment(
      id: 'bill_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      amount: amount,
      dueDate: _billDueDate,
      category: _billCategory,
      recurrence: 'MONTHLY',
    );

    state.addBill(newBill);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: AppTheme.success, content: Text('Bill "$name" added successfully!')),
    );
  }

  void _addDetectedItemDirectly(AppState state, DetectedBillItem item) {
    if (item.isEmi) {
      final newEmi = EMILoan(
        id: item.id,
        loanName: item.title,
        totalAmount: item.amount * 12,
        monthlyEMI: item.amount,
        totalTenureMonths: 12,
        paidMonths: 0,
        remainingAmount: item.amount * 12,
        interestRate: 10.5,
        nextDueDate: item.dueDate,
      );
      state.addEmiLoan(newEmi);
    } else {
      final newBill = RecurringPayment(
        id: item.id,
        name: item.title,
        amount: item.amount,
        dueDate: item.dueDate,
        category: item.category,
        recurrence: 'MONTHLY',
      );
      state.addBill(newBill);
    }

    setState(() {
      _detectedItems.removeWhere((i) => i.id == item.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.success,
        content: Text('Added "${item.title}" (₹${item.amount.toStringAsFixed(0)}) to your manager!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Obligation',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primary,
            labelColor: AppTheme.primaryLight,
            unselectedLabelColor: const Color(0xFF94A3B8),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(icon: Icon(Icons.auto_awesome, size: 18), text: 'Detect SMS'),
              Tab(icon: Icon(Icons.account_balance, size: 18), text: 'Add EMI'),
              Tab(icon: Icon(Icons.receipt, size: 18), text: 'Add Bill'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: SMART SMS DETECTION
                _buildSmsDetectionTab(state),

                // TAB 2: MANUAL EMI ADD
                _buildManualEmiTab(state),

                // TAB 3: MANUAL BILL ADD
                _buildManualBillTab(state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmsDetectionTab(AppState state) {
    if (_isScanning) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            SizedBox(height: 16),
            Text('Scanning SMS for bills & loan EMIs...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Detected from Messages',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              TextButton.icon(
                onPressed: _triggerSmsScan,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Re-scan', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'We detect real utility bills and loan EMIs from your bank & service SMS.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _detectedItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.mark_email_read_outlined, size: 48, color: Color(0xFF64748B)),
                        const SizedBox(height: 12),
                        const Text(
                          'No pending bill or EMI SMS found.',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'You can add your EMIs and recurring bills manually using the other tabs above.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                          onPressed: () => _tabController.animateTo(1),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Manually'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _detectedItems.length,
                    itemBuilder: (ctx, index) {
                      final item = _detectedItems[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      item.isEmi ? Icons.account_balance : Icons.receipt_long,
                                      color: AppTheme.primaryLight,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      item.title,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (item.isEmi ? Colors.orange : Colors.teal).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.isEmi ? 'EMI' : item.category,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: item.isEmi ? Colors.orangeAccent : Colors.tealAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.rawSnippet,
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '₹${item.amount.toStringAsFixed(0)}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                                    ),
                                    Text(
                                      'Due: ${item.dueDate.day}/${item.dueDate.month}/${item.dueDate.year}',
                                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                    ),
                                  ],
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.success,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => _addDetectedItemDirectly(state, item),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('+ Add Directly', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualEmiTab(AppState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Track New EMI or Loan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Enter your loan details to track monthly EMIs and tenure.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          const SizedBox(height: 16),
          _buildTextField(_emiNameCtrl, 'Loan / EMI Name (e.g. HDFC Home Loan, iPhone 16 EMI)', Icons.label_outline),
          const SizedBox(height: 12),
          _buildTextField(_emiAmountCtrl, 'Monthly EMI Amount (₹)', Icons.currency_rupee, keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          _buildTextField(_emiRemainingCtrl, 'Remaining Loan Amount (₹)', Icons.account_balance_wallet_outlined, keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(_emiTenureCtrl, 'Tenure (Months)', Icons.timelapse, keyboardType: TextInputType.number),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(_emiDueDayCtrl, 'Due Day (1-31)', Icons.calendar_today, keyboardType: TextInputType.number),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _saveManualEmi(state),
              child: const Text('Save EMI Loan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualBillTab(AppState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Recurring Bill', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Add electricity, broadband, credit card or rent bills.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          const SizedBox(height: 16),
          _buildTextField(_billNameCtrl, 'Bill Name (e.g. BESCOM Electricity, Airtel Wi-Fi)', Icons.label_outline),
          const SizedBox(height: 12),
          _buildTextField(_billAmountCtrl, 'Bill Amount (₹)', Icons.currency_rupee, keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _billCategory,
                dropdownColor: const Color(0xFF1E293B),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'Utilities', child: Text('Utilities (Electricity / Gas / Water)', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'Broadband', child: Text('Broadband / Wi-Fi / DTH', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'Credit Card', child: Text('Credit Card Bill', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'Rent', child: Text('House Rent', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'Insurance', child: Text('Insurance Premium', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'Other', child: Text('Other Recurring Bill', style: TextStyle(color: Colors.white))),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _billCategory = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _billDueDate,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() => _billDueDate = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, color: AppTheme.primaryLight, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Due Date: ${_billDueDate.day}/${_billDueDate.month}/${_billDueDate.year}',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                  const Text('Change', style: TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _saveManualBill(state),
              child: const Text('Save Bill', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.primaryLight, size: 20),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary),
        ),
      ),
    );
  }
}
