import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../services/firestore_service.dart';
import '../../state/cart.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';
import 'checkout_page.dart';

/// Store catalogue with Digital / Physical filters.
class StoreCatalogue extends StatefulWidget {
  const StoreCatalogue({super.key});

  @override
  State<StoreCatalogue> createState() => _StoreCatalogueState();
}

class _StoreCatalogueState extends State<StoreCatalogue> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          spacing: 10,
          children: [
            for (final f in const ['All', 'Digital', 'Physical'])
              ChoiceChip(
                label: Text(f == 'All' ? 'All products' : '$f products'),
                selected: _filter == f,
                onSelected: (_) => setState(() => _filter = f),
              ),
          ],
        ),
        const SizedBox(height: 24),
        StreamView<List<Product>>(
          stream: Db.publishedProducts(),
          builder: (context, products) {
            final shown = products
                .where((p) => _filter == 'All' || p.type == _filter)
                .toList();
            if (shown.isEmpty) {
              return const EmptyState(
                icon: Icons.storefront_outlined,
                title: 'No products yet',
                message: 'Products added in the admin portal will appear here.',
              );
            }
            return Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [for (final p in shown) ProductCard(product: p)],
            );
          },
        ),
      ],
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  void _open(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)),
      );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _open(context),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconArt(icon: product.icon, color: product.color),
                const SizedBox(height: 14),
                Row(
                  children: [
                    StatusChip(product.type),
                    const SizedBox(width: 8),
                    if (!product.inStock) const StatusChip('Out of stock'),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  product.title,
                  style: const TextStyle(
                    color: navy,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 12),
                Text(
                  money(product.price),
                  style: const TextStyle(
                    color: navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _open(context),
                        child: const Text('Details'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: navy),
                        onPressed: product.inStock
                            ? () {
                                context.read<Cart>().add(product);
                                showSnack(context, '${product.title} added to cart');
                              }
                            : null,
                        child: const Text('Add'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final wide = MediaQuery.sizeOf(context).width > 800;
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 8, children: [
          StatusChip(p.type),
          StatusChip(p.inStock ? 'Available' : 'Out of stock'),
        ]),
        const SizedBox(height: 12),
        Text(p.title,
            style: const TextStyle(
                color: navy, fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(p.category, style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 16),
        Text(p.description, style: const TextStyle(height: 1.6)),
        const SizedBox(height: 16),
        Text(money(p.price),
            style: const TextStyle(
                color: navy, fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        if (p.isDigital)
          const _InfoLine(
            icon: Icons.download_outlined,
            text: 'Digital download. After payment it appears in '
                'Dashboard > My Digital Products, linked to your account.',
          )
        else ...[
          _InfoLine(icon: Icons.inventory_outlined, text: '${p.stock} in stock'),
          _InfoLine(
            icon: Icons.local_shipping_outlined,
            text: 'Ships in Malaysia, flat ${money(Cart.shippingFlatRate)}. '
                'Weight ${p.weightKg} kg.',
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Quantity'),
            IconButton(
              onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text('$_qty', style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              onPressed: p.isDigital || _qty < p.stock
                  ? () => setState(() => _qty++)
                  : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: navy),
              onPressed: p.inStock
                  ? () {
                      context.read<Cart>().add(p, _qty);
                      showSnack(context, 'Added $_qty × ${p.title} to cart');
                    }
                  : null,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Add to Cart'),
            ),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CartScreen()),
              ),
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('View cart'),
            ),
          ],
        ),
      ],
    );

    return PageScaffold(
      title: 'Product Detail',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Panel(
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: IconArt(icon: p.icon, color: p.color, height: 320)),
                      const SizedBox(width: 30),
                      Expanded(child: info),
                    ],
                  )
                : Column(children: [
                    IconArt(icon: p.icon, color: p.color, height: 200),
                    const SizedBox(height: 20),
                    info,
                  ]),
          ),
          const SizedBox(height: 24),
          const SectionTitle('Related products'),
          StreamView<List<Product>>(
            stream: Db.publishedProducts(),
            builder: (context, all) {
              final related = all
                  .where((x) => x.id != p.id && x.type == p.type)
                  .take(3)
                  .toList();
              return Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [for (final r in related) ProductCard(product: r)],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: navy),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
        ],
      ),
    );
  }
}

/// Cart contents and totals. Used both as a top-level page and a pushed screen.
class CartView extends StatelessWidget {
  final VoidCallback onShop;

  const CartView({super.key, required this.onShop});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<Cart>();
    if (cart.isEmpty) {
      return EmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'Your cart is empty',
        message: 'Explore the store to find workbooks, journals and learning kits.',
        action: FilledButton(onPressed: onShop, child: const Text('Browse Store')),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in cart.items)
          Card(
            child: ListTile(
              leading: Icon(item.product.icon, color: item.product.color, size: 32),
              title: Text(item.product.title),
              subtitle: Text('${item.product.type} • ${money(item.product.price)} each'),
              trailing: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Decrease',
                    onPressed: () =>
                        cart.setQty(item.product.id, item.qty - 1),
                    icon: const Icon(Icons.remove),
                  ),
                  Text('${item.qty}'),
                  IconButton(
                    tooltip: 'Increase',
                    onPressed: () =>
                        cart.setQty(item.product.id, item.qty + 1),
                    icon: const Icon(Icons.add),
                  ),
                  const SizedBox(width: 8),
                  Text(money(item.lineTotal),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    tooltip: 'Remove item',
                    onPressed: () => cart.remove(item.product.id),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Panel(child: OrderTotals(cart: cart)),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 12,
          runSpacing: 10,
          children: [
            OutlinedButton(onPressed: onShop, child: const Text('Continue Shopping')),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: navy),
              onPressed: () => startCheckout(context),
              icon: const Icon(Icons.lock_outline),
              label: const Text('Proceed to Checkout'),
            ),
          ],
        ),
      ],
    );
  }
}

class OrderTotals extends StatelessWidget {
  final Cart cart;

  const OrderTotals({super.key, required this.cart});

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String value, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(child: Text(label)),
              Text(value,
                  style: TextStyle(
                    fontWeight: bold ? FontWeight.w800 : FontWeight.normal,
                    fontSize: bold ? 18 : 14,
                    color: navy,
                  )),
            ],
          ),
        );
    return Column(
      children: [
        row('Subtotal', money(cart.subtotal)),
        row(
          cart.discount > 0 ? 'Discount (10% over RM150)' : 'Discount',
          '- ${money(cart.discount)}',
        ),
        row('Shipping', cart.hasPhysical ? money(cart.shipping) : 'Not required'),
        const Divider(),
        row('Total', money(cart.total), bold: true),
      ],
    );
  }
}

/// Cart opened from a product page.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Shopping Cart',
      maxWidth: 850,
      child: CartView(onShop: () => AppNav.go(context, 'Store')),
    );
  }
}
