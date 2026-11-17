import 'dart:math';

/// The three outcomes a payment provider can return.
enum PaymentStatus { successful, failed, pending }

extension PaymentStatusLabel on PaymentStatus {
  String get label => switch (this) {
        PaymentStatus.successful => 'Successful',
        PaymentStatus.failed => 'Failed',
        PaymentStatus.pending => 'Pending',
      };
}

class PaymentResult {
  final PaymentStatus status;
  final String reference;
  final String message;

  const PaymentResult(this.status, this.reference, this.message);
}

class CardDetails {
  final String holder;
  final String number;
  final String expiry;
  final String cvv;

  const CardDetails(this.holder, this.number, this.expiry, this.cvv);
}

/// Contract every payment provider must follow.
/// To go live, implement this with a real provider (for example a Stripe or
/// Billplz client) and swap it in [paymentGateway]. No page code changes.
abstract class PaymentGateway {
  Future<PaymentResult> charge({
    required double amount,
    required String description,
    required CardDetails card,
    PaymentStatus? simulate,
  });
}

/// Test-mode gateway used for the demo. No money moves.
/// [simulate] lets the tester choose the outcome so every state can be shown.
class MockPaymentGateway implements PaymentGateway {
  @override
  Future<PaymentResult> charge({
    required double amount,
    required String description,
    required CardDetails card,
    PaymentStatus? simulate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    final ref = 'TXN${Random().nextInt(899999) + 100000}';
    final status = simulate ?? PaymentStatus.successful;
    final message = switch (status) {
      PaymentStatus.successful => 'Payment approved.',
      PaymentStatus.failed => 'The card was declined. No charge was made.',
      PaymentStatus.pending => 'Payment is awaiting bank confirmation.',
    };
    return PaymentResult(status, ref, message);
  }
}

final PaymentGateway paymentGateway = MockPaymentGateway();
