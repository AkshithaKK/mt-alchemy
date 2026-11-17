import 'package:flutter/material.dart';

import '../theme.dart';

/// Lets pushed pages jump back to a top-level page of the main website.
class AppNav {
  static void Function(String page)? _navigate;

  static void register(void Function(String page) navigate) =>
      _navigate = navigate;

  static void go(BuildContext context, String page) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    _navigate?.call(page);
  }
}

String money(double value) => 'RM ${value.toStringAsFixed(2)}';

String shortDate(DateTime? d) {
  if (d == null) return '-';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ));
}

/// Standard layout for pages pushed on top of the main website.
class PageScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final double maxWidth;
  final List<Widget>? actions;

  const PageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.maxWidth = 1100,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// White rounded panel used to group content.
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: navy,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip(this.status, {super.key});

  Color get _color {
    switch (status) {
      case 'Successful':
      case 'Paid':
      case 'Delivered':
      case 'Available':
      case 'Completed':
      case 'Published':
      case 'Active':
      case 'Closed':
        return success;
      case 'Failed':
      case 'Cancelled':
      case 'Archived':
      case 'Inactive':
        return danger;
      case 'Shipped':
      case 'Processing':
      case 'In Progress':
      case 'Contacted':
      case 'Consultation':
      case 'Proposal Sent':
        return blue;
      default:
        return const Color(0xFF9C6B10);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      child: Column(
        children: [
          Icon(icon, size: 60, color: yellow),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: navy,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, height: 1.5),
          ),
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    );
  }
}

/// Small statistic tile used on dashboards.
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: yellow),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: navy,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

/// Square icon tile shown in place of product/course images.
class IconArt extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double height;

  const IconArt({
    super.key,
    required this.icon,
    required this.color,
    this.height = 130,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, size: height * 0.42, color: color),
    );
  }
}

/// Shown when a signed-in role is required.
class SignInRequired extends StatelessWidget {
  final String message;

  const SignInRequired({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.lock_outline,
      title: 'Please sign in',
      message: message,
      action: FilledButton(
        onPressed: () => AppNav.go(context, 'Login'),
        child: const Text('Sign in'),
      ),
    );
  }
}

/// Wraps a Firestore stream with loading and error handling.
class StreamView<T> extends StatelessWidget {
  final Stream<T> stream;
  final Widget Function(BuildContext context, T data) builder;

  const StreamView({super.key, required this.stream, required this.builder});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Could not load data: ${snap.error}',
              style: const TextStyle(color: danger),
            ),
          );
        }
        // Only show the spinner until the first event arrives. After that a
        // null value is a real answer (e.g. "not enrolled yet"), not loading.
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return builder(context, snap.data as T);
      },
    );
  }
}
