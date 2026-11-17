import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../services/firestore_service.dart';
import '../../services/pdf_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

/// Order confirmation (right after paying) and order detail (from My Orders).
class OrderDetailPage extends StatelessWidget {
  final String orderId;
  final bool justPlaced;

  const OrderDetailPage({super.key, required this.orderId, this.justPlaced = false});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: justPlaced ? 'Order Confirmation' : 'Order Details',
      maxWidth: 800,
      child: StreamView<ShopOrder?>(
        stream: Db.order(orderId),
        builder: (context, order) {
          if (order == null) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Order not found',
              message: 'This order may have been removed.',
            );
          }
          final digital = order.items.where((i) => i.type == 'Digital').toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (justPlaced)
                Panel(
                  color: success.withValues(alpha: 0.08),
                  child: Column(children: [
                    Icon(
                      order.isPaid ? Icons.check_circle : Icons.hourglass_top,
                      color: order.isPaid ? success : const Color(0xFF9C6B10),
                      size: 56,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      order.isPaid
                          ? 'Thank you for your order.'
                          : 'Your payment is pending confirmation.',
                      style: const TextStyle(
                          color: navy, fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                  ]),
                ),
              const SizedBox(height: 16),
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text('Order #${order.orderNumber}',
                            style: const TextStyle(
                                color: navy,
                                fontSize: 20,
                                fontWeight: FontWeight.w800)),
                      ),
                      StatusChip(order.status),
                    ]),
                    const SizedBox(height: 6),
                    Text('Placed ${shortDate(order.createdAt)} • '
                        'Payment ${order.paymentStatus} (${order.paymentRef})'),
                    const Divider(height: 28),
                    for (final i in order.items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(children: [
                          Expanded(child: Text('${i.qty} × ${i.title} (${i.type})')),
                          Text(money(i.lineTotal)),
                        ]),
                      ),
                    const Divider(),
                    _line('Subtotal', money(order.subtotal)),
                    _line('Discount', '- ${money(order.discount)}'),
                    _line('Shipping', money(order.shippingFee)),
                    _line('Amount paid', money(order.total), bold: true),
                    if (order.shipping != null) ...[
                      const Divider(height: 28),
                      const Text('Shipping to',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text([
                        order.shipping!['address'],
                        order.shipping!['city'],
                        order.shipping!['postcode'],
                        order.shipping!['country'],
                      ].where((x) => x != null && '$x'.isNotEmpty).join(', ')),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (order.hasPhysical) OrderTracker(order: order),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  if (digital.isNotEmpty && order.isPaid)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: navy),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const DigitalLibraryPage()),
                      ),
                      icon: const Icon(Icons.download),
                      label: const Text('Download Product'),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyOrdersPage()),
                    ),
                    icon: const Icon(Icons.local_shipping_outlined),
                    label: Text(order.hasPhysical ? 'Track Order' : 'My Orders'),
                  ),
                  TextButton(
                    onPressed: () => AppNav.go(context, 'Store'),
                    child: const Text('Back to Store'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _line(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Expanded(child: Text(label)),
          Text(value,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.normal)),
        ]),
      );
}

/// Visual step tracker for physical orders.
class OrderTracker extends StatelessWidget {
  final ShopOrder order;

  const OrderTracker({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final flow = order.flow;
    final current = flow.indexOf(order.status);
    return Panel(
      child: Wrap(
        spacing: 6,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (var i = 0; i < flow.length; i++) ...[
            Chip(
              avatar: Icon(
                i <= current ? Icons.check_circle : Icons.radio_button_unchecked,
                color: i <= current ? success : Colors.black38,
                size: 18,
              ),
              label: Text(flow[i]),
            ),
            if (i < flow.length - 1)
              const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ],
      ),
    );
  }
}

class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return PageScaffold(
      title: 'My Orders',
      maxWidth: 900,
      child: !app.isLoggedIn
          ? const SignInRequired(message: 'Sign in to see your orders.')
          : StreamView<List<ShopOrder>>(
              stream: Db.ordersForUser(app.uid),
              builder: (context, orders) {
                if (orders.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No orders yet',
                    message: 'Your purchases will appear here.',
                    action: FilledButton(
                      onPressed: () => AppNav.go(context, 'Store'),
                      child: const Text('Visit the store'),
                    ),
                  );
                }
                return Panel(
                  padding: const EdgeInsets.all(8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      showCheckboxColumn: false,
                      columns: const [
                        DataColumn(label: Text('Order')),
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Items')),
                        DataColumn(label: Text('Amount')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: [
                        for (final o in orders)
                          DataRow(
                            onSelectChanged: (_) => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => OrderDetailPage(orderId: o.id),
                              ),
                            ),
                            cells: [
                              DataCell(Text('#${o.orderNumber}')),
                              DataCell(Text(shortDate(o.createdAt))),
                              DataCell(Text('${o.items.length}')),
                              DataCell(Text(money(o.total))),
                              DataCell(StatusChip(o.status)),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// Digital products the user has paid for. Access is checked against
/// successful orders, so there are no public download links.
class DigitalLibraryPage extends StatelessWidget {
  const DigitalLibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return PageScaffold(
      title: 'My Digital Products',
      maxWidth: 900,
      child: !app.isLoggedIn
          ? const SignInRequired(message: 'Sign in to access your downloads.')
          : StreamView<List<ShopOrder>>(
              stream: Db.ordersForUser(app.uid),
              builder: (context, orders) {
                final owned = <String, (OrderItem, ShopOrder)>{};
                for (final o in orders.where((o) => o.isPaid)) {
                  for (final i in o.items.where((i) => i.type == 'Digital')) {
                    owned.putIfAbsent(i.productId, () => (i, o));
                  }
                }
                if (owned.isEmpty) {
                  return EmptyState(
                    icon: Icons.cloud_download_outlined,
                    title: 'No digital products yet',
                    message: 'Digital items appear here once payment is successful.',
                    action: FilledButton(
                      onPressed: () => AppNav.go(context, 'Store'),
                      child: const Text('Browse digital products'),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final entry in owned.values)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.picture_as_pdf, color: danger, size: 34),
                          title: Text(entry.$1.title,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Purchased ${shortDate(entry.$2.createdAt)} '
                              '• Order #${entry.$2.orderNumber}'),
                          trailing: FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: navy),
                            onPressed: () => PdfService.digitalProduct(
                              title: entry.$1.title,
                              description:
                                  'Thank you for your purchase. Work through each '
                                  'reflection at your own pace.',
                              buyer: app.name,
                              orderNumber: entry.$2.orderNumber,
                            ),
                            icon: const Icon(Icons.download),
                            label: const Text('Download'),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}
