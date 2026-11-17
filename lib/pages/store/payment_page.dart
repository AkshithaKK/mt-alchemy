import 'package:flutter/material.dart';

import '../../services/payment_service.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

/// Opens the payment screen and returns the provider result
/// (or null if the user backed out).
Future<PaymentResult?> openPayment(
  BuildContext context, {
  required double amount,
  required String description,
}) {
  return Navigator.of(context).push<PaymentResult>(
    MaterialPageRoute(
      builder: (_) => PaymentPage(amount: amount, description: description),
    ),
  );
}

class PaymentPage extends StatefulWidget {
  final double amount;
  final String description;

  const PaymentPage({super.key, required this.amount, required this.description});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _holder = TextEditingController();
  final _number = TextEditingController(text: '4242 4242 4242 4242');
  final _expiry = TextEditingController(text: '12/28');
  final _cvv = TextEditingController(text: '123');
  PaymentStatus _simulate = PaymentStatus.successful;
  bool _processing = false;

  @override
  void dispose() {
    _holder.dispose();
    _number.dispose();
    _expiry.dispose();
    _cvv.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _processing = true);
    final result = await paymentGateway.charge(
      amount: widget.amount,
      description: widget.description,
      card: CardDetails(_holder.text, _number.text, _expiry.text, _cvv.text),
      simulate: _simulate,
    );
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Secure Payment',
      maxWidth: 560,
      child: Panel(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.description, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 6),
              Text(
                money(widget.amount),
                style: const TextStyle(
                  color: navy,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _holder,
                decoration: const InputDecoration(
                  labelText: 'Name on card',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter the card holder name' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _number,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Card number',
                  prefixIcon: Icon(Icons.credit_card),
                ),
                validator: (v) {
                  final digits = (v ?? '').replaceAll(RegExp(r'\s'), '');
                  return RegExp(r'^\d{16}$').hasMatch(digits)
                      ? null
                      : 'Card number must have 16 digits';
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiry,
                      decoration: const InputDecoration(labelText: 'Expiry (MM/YY)'),
                      validator: (v) =>
                          RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$').hasMatch(v ?? '')
                              ? null
                              : 'Use MM/YY',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cvv,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'CVV'),
                      validator: (v) =>
                          RegExp(r'^\d{3}$').hasMatch(v ?? '') ? null : '3 digits',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: yellow.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TEST MODE: choose the provider response to simulate',
                      style: TextStyle(fontWeight: FontWeight.bold, color: navy),
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<PaymentStatus>(
                      segments: [
                        for (final s in PaymentStatus.values)
                          ButtonSegment(value: s, label: Text(s.label)),
                      ],
                      selected: {_simulate},
                      onSelectionChanged: (s) => setState(() => _simulate = s.first),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: navy,
                  padding: const EdgeInsets.all(18),
                ),
                onPressed: _processing ? null : _pay,
                icon: _processing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.lock_outline),
                label: Text(_processing ? 'Processing…' : 'Pay ${money(widget.amount)}'),
              ),
              const SizedBox(height: 10),
              const Text(
                'Demo gateway: no real card is charged.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black45, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
