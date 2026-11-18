import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Dots showing how many digits of a PIN have been entered.
class PinDots extends StatelessWidget {
  final int length;
  final int filled;

  const PinDots({super.key, required this.length, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final isFilled = filled > index;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? const Color(0xFF14B8A6) : Colors.transparent,
            border: Border.all(
              color: isFilled ? const Color(0xFF14B8A6) : const Color(0xFF64748B),
              width: 2,
            ),
          ),
        );
      }),
    );
  }
}

/// The 1–9 / 0 / backspace / clear keypad shared by PIN dialogs.
class PinKeypad extends StatelessWidget {
  final void Function(String digit) onDigit;
  final VoidCallback onDelete;
  final VoidCallback? onClear;
  final bool enabled;

  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onDelete,
    this.onClear,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        if (index == 9) {
          return InkWell(
            onTap: enabled ? onClear : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x22FFFFFF)),
              ),
              alignment: Alignment.center,
              child: const Text(
                'CLR',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
              ),
            ),
          );
        }
        if (index == 10) {
          return _keyButton('0', enabled ? () => onDigit('0') : null);
        }
        if (index == 11) {
          return InkWell(
            onTap: enabled ? onDelete : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x22FFFFFF)),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.backspace_outlined, color: Colors.white70, size: 20),
            ),
          );
        }
        final digit = (index + 1).toString();
        return _keyButton(digit, enabled ? () => onDigit(digit) : null);
      },
    );
  }

  Widget _keyButton(String text, VoidCallback? onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x22FFFFFF)),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// PIN / Password Dialog supporting variable length (minimum 6 digits,
/// user choice of how many digits they keep).
class PinDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final FutureOr<bool> Function(String pin) onValidate;
  final VoidCallback onSuccess;
  final int minLength;
  final int maxLength;
  final int? length;
  final bool showDemoHint;
  final Widget? footer;

  const PinDialog({
    super.key,
    this.title = 'Enter Security Password',
    this.subtitle = 'Enter Shield Password (minimum 6 digits)',
    required this.onValidate,
    required this.onSuccess,
    this.minLength = 6,
    this.maxLength = 32,
    this.length,
    this.showDemoHint = false,
    this.footer,
  });

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  String _enteredPin = '';
  String? _error;
  bool _checking = false;

  int get _minAllowed => widget.length ?? widget.minLength;
  int get _maxAllowed => widget.length ?? widget.maxLength;

  void _handleDigit(String digit) {
    if (_checking || _enteredPin.length >= _maxAllowed) return;
    setState(() {
      _enteredPin += digit;
      _error = null;
    });

    // If a fixed length was explicitly passed (e.g. legacy 4-digit), auto submit at that length.
    if (widget.length != null && _enteredPin.length == widget.length) {
      _submitPin();
    }
  }

  void _handleDelete() {
    if (_checking || _enteredPin.isEmpty) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _error = null;
    });
  }

  void _handleClear() {
    if (_checking || _enteredPin.isEmpty) return;
    setState(() {
      _enteredPin = '';
      _error = null;
    });
  }

  Future<void> _submitPin() async {
    if (_enteredPin.length < _minAllowed) {
      setState(() => _error = 'Password must be at least $_minAllowed digits.');
      return;
    }

    final pin = _enteredPin;
    setState(() => _checking = true);

    bool ok = false;
    try {
      ok = await widget.onValidate(pin);
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(() => _checking = false);

    if (ok) {
      Navigator.of(context).pop();
      widget.onSuccess();
    } else {
      setState(() {
        _error = 'Incorrect Password. Try again.';
        _enteredPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasMinDigits = _enteredPin.length >= _minAllowed;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: const Color(0xFF0F172A),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF14B8A6).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_outlined, color: Color(0xFF14B8A6), size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 18),

              // Dynamic dots or masked bullets
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasMinDigits ? const Color(0xFF14B8A6) : const Color(0x22FFFFFF),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _enteredPin.isEmpty
                          ? '• • • • • • • •'
                          : '● ' * _enteredPin.length,
                      style: TextStyle(
                        fontSize: 20,
                        letterSpacing: 2,
                        color: _enteredPin.isEmpty
                            ? const Color(0xFF64748B)
                            : const Color(0xFF14B8A6),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_enteredPin.length} digits entered (minimum $_minAllowed)',
                      style: TextStyle(
                        fontSize: 11,
                        color: hasMinDigits ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 16),

              PinKeypad(
                onDigit: _handleDigit,
                onDelete: _handleDelete,
                onClear: _handleClear,
                enabled: !_checking,
              ),

              const SizedBox(height: 16),

              // Confirm button for user-chosen digit length
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasMinDigits
                        ? const Color(0xFF14B8A6)
                        : const Color(0xFF1E293B),
                    foregroundColor: hasMinDigits ? Colors.white : const Color(0xFF64748B),
                    elevation: hasMinDigits ? 2 : 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: (_checking || !hasMinDigits) ? null : _submitPin,
                  child: _checking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          hasMinDigits
                              ? 'Confirm Password (${_enteredPin.length} digits)'
                              : 'Enter at least $_minAllowed digits',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                ),
              ),

              const SizedBox(height: 8),

              if (widget.footer != null) widget.footer!,
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog allowing user to set or update their Shield Password (minimum 8 digits, user choice of length).
class SetPinDialog extends StatefulWidget {
  final VoidCallback? onUpdated;

  const SetPinDialog({super.key, this.onUpdated});

  @override
  State<SetPinDialog> createState() => _SetPinDialogState();
}

class _SetPinDialogState extends State<SetPinDialog> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _obscurePin = true;
  bool _obscureConfirm = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();

    if (pin.length < 6) {
      setState(() => _error = 'Password must be at least 6 digits.');
      return;
    }
    if (!RegExp(r'^\d+$').hasMatch(pin)) {
      setState(() => _error = 'Password must contain only numbers.');
      return;
    }
    if (pin != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ApiService.updatePin(pin);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Shield Password updated (${pin.length} digits).'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      widget.onUpdated?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Failed to update password: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFF0F172A),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Color(0xFF14B8A6), size: 24),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Set Shield Password',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose your security password (minimum 6 digits, choose as many digits as you want).',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _pinController,
                obscureText: _obscurePin,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'New Password (min 6 digits)',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
                    onPressed: () => setState(() => _obscurePin = !_obscurePin),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B8A6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _saving ? null : _handleSave,
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
