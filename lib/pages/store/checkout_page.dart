import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../services/firestore_service.dart';
import '../../services/payment_service.dart';
import '../../state/app_state.dart';
import '../../state/cart.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';
import 'order_pages.dart';
import 'payment_page.dart';
import 'store_pages.dart' show OrderTotals;

/// Checkout needs an account so orders and downloads belong to someone.
void startCheckout(BuildContext context) {
  final app = context.read<AppState>();
  if (!app.isLoggedIn) {
    showSnack(context, 'Please sign in or register to check out.');
    AppNav.go(context, 'Login');
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const CheckoutPage()),
  );
}

const countries = ['Malaysia', 'Singapore', 'Indonesia', 'Thailand', 'Other'];

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _postcode = TextEditingController();
  String _country = 'Malaysia';
  bool _shipToBilling = true;
  final _shipAddress = TextEditingController();
  final _shipCity = TextEditingController();
  final _shipPostcode = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _name = TextEditingController(text: app.name);
    _email = TextEditingController(text: app.email);
  }

  @override
  void dispose() {
    for (final c in [
      _name, _email, _phone, _address, _city, _state, _postcode,
      _shipAddress, _shipCity, _shipPostcode,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) =>
      v == null || v.trim().isEmpty ? 'Required' : null;

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    final cart = context.read<Cart>();
    final app = context.read<AppState>();

    final result = await openPayment(
      context,
      amount: cart.total,
      description: 'MT Alchemy store order (${cart.count} items)',
    );
    if (result == null || !mounted) return;

    setState(() => _busy = true);
    final billing = {
      'address': _address.text.trim(),
      'city': _city.text.trim(),
      'state': _state.text.trim(),
      'postcode': _postcode.text.trim(),
      'country': _country,
    };
    final shipping = !cart.hasPhysical
        ? null
        : _shipToBilling
            ? billing
            : {
                'address': _shipAddress.text.trim(),
                'city': _shipCity.text.trim(),
                'postcode': _shipPostcode.text.trim(),
                'country': _country,
              };

    final status = switch (result.status) {
      PaymentStatus.successful => cart.hasPhysical ? 'Paid' : 'Available',
      PaymentStatus.pending => 'Pending',
      PaymentStatus.failed => 'Cancelled',
    };

    final order = ShopOrder(
      orderNumber: newOrderNumber(),
      userId: app.uid,
      userEmail: app.email,
      items: [
        for (final i in cart.items)
          OrderItem(
            productId: i.product.id,
            title: i.product.title,
            type: i.product.type,
            price: i.product.price,
            qty: i.qty,
          ),
      ],
      subtotal: cart.subtotal,
      discount: cart.discount,
      shippingFee: cart.shipping,
      total: cart.total,
      customer: {
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
      },
      billing: billing,
      shipping: shipping,
      paymentStatus: result.status.label,
      paymentRef: result.reference,
      status: status,
    );

    try {
      final id = await Db.createOrder(order);
      if (result.status != PaymentStatus.failed) {
        for (final i in cart.items.where((i) => !i.product.isDigital)) {
          await Db.reduceStock(i.product.id, i.qty);
        }
        cart.clear();
      }
      if (!mounted) return;
      if (result.status == PaymentStatus.failed) {
        setState(() => _busy = false);
        showSnack(context, '${result.message} Your cart has been kept, please try again.');
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderDetailPage(orderId: id, justPlaced: true),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showSnack(context, 'Could not save the order: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<Cart>();
    final wide = MediaQuery.sizeOf(context).width > 900;

    final form = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('Customer information'),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Full name'),
            validator: _required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                    .hasMatch((v ?? '').trim())
                ? null
                : 'Enter a valid email',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone'),
            validator: (v) => RegExp(r'^[0-9+\-\s]{8,15}$').hasMatch((v ?? '').trim())
                ? null
                : 'Enter a valid phone number',
          ),
          const SectionTitle('Billing address'),
          TextFormField(
            controller: _address,
            decoration: const InputDecoration(labelText: 'Address'),
            validator: _required,
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _city,
                decoration: const InputDecoration(labelText: 'City'),
                validator: _required,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _state,
                decoration: const InputDecoration(labelText: 'State'),
                validator: _required,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _postcode,
                decoration: const InputDecoration(labelText: 'Postcode'),
                validator: (v) => RegExp(r'^\d{4,6}$').hasMatch((v ?? '').trim())
                    ? null
                    : '4 to 6 digits',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _country,
                decoration: const InputDecoration(labelText: 'Country'),
                items: [
                  for (final c in countries) DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => setState(() => _country = v ?? _country),
              ),
            ),
          ]),
          if (cart.hasPhysical) ...[
            const SectionTitle('Shipping'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ship to my billing address'),
              value: _shipToBilling,
              onChanged: (v) => setState(() => _shipToBilling = v),
            ),
            if (!_shipToBilling) ...[
              TextFormField(
                controller: _shipAddress,
                decoration: const InputDecoration(labelText: 'Shipping address'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _shipCity,
                    decoration: const InputDecoration(labelText: 'City'),
                    validator: _required,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _shipPostcode,
                    decoration: const InputDecoration(labelText: 'Postcode'),
                    validator: _required,
                  ),
                ),
              ]),
            ],
          ],
        ],
      ),
    );

    final summary = Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('Order summary'),
          for (final i in cart.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Expanded(child: Text('${i.qty} × ${i.product.title}')),
                Text(money(i.lineTotal)),
              ]),
            ),
          const Divider(),
          OrderTotals(cart: cart),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: navy,
              padding: const EdgeInsets.all(18),
            ),
            onPressed: _busy || cart.isEmpty ? null : _placeOrder,
            icon: const Icon(Icons.payment),
            label: const Text('Continue to Payment'),
          ),
        ],
      ),
    );

    return PageScaffold(
      title: 'Checkout',
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: Panel(child: form)),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: summary),
              ],
            )
          : Column(children: [Panel(child: form), const SizedBox(height: 16), summary]),
    );
  }
}
