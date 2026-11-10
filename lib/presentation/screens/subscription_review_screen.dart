import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data_access/models/enums.dart';
import '../../data_access/models/subscription.dart';
import '../../theme.dart';
import '../../utils/helpers.dart';
import '../controllers/review_controller.dart';
import '../controllers/subscription_controller.dart';
import '../data_refresh.dart';
import '../widgets/common.dart';
import 'subscription_details_screen.dart';

/// Figure 5. Subscription Review: Keep / Review later / Stop tracking.
class SubscriptionReviewScreen extends StatelessWidget {
  const SubscriptionReviewScreen({super.key, required this.subscriptionId});

  final String subscriptionId;

  @override
  Widget build(BuildContext context) {
    context.watch<DataRefresh>();
    final s =
        context.read<SubscriptionController>().getSubscription(subscriptionId);
    if (s == null) return const Scaffold();
    final daysLeft = daysBetween(DateTime.now(), s.nextPaymentDate);

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription Review')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            // Header card with a "Details >" link
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.cardBorder)),
              child: Row(children: [
                SubLogo(path: s.logoPath),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name,
                          style: TextStyle(
                              color: context.ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                      Text(
                        '${peso(s.yourShare)} / ${s.billingCycle.unit} · Next '
                        'payment ${daysLeft <= 0 ? 'today' : 'in $daysLeft day${daysLeft == 1 ? '' : 's'}'}',
                        style: TextStyle(color: context.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            SubscriptionDetailsScreen(subscriptionId: s.id)),
                  ),
                  child: Text('Details >',
                      style: TextStyle(
                          color: context.ink, fontWeight: FontWeight.w700)),
                ),
              ]),
            ),

            const SizedBox(height: 16),
            Text('Do you still want to keep it?',
                style: TextStyle(color: context.muted)),
            const SizedBox(height: 12),

            // Keep
            _ActionButton(
              background: AppColors.lime,
              foreground: AppColors.purple,
              title: 'Keep',
              subtitle: 'Continue tracking this subscription',
              onTap: () async {
                final navigator = Navigator.of(context);
                await context.read<ReviewController>().keep(s.id);
                if (!context.mounted) return;
                showSnack(context, '${s.name} kept.');
                navigator.pop();
              },
            ),

            // Review later
            _ActionButton(
              background: AppColors.purple,
              foreground: Colors.white,
              titleColor: AppColors.lime,
              title: 'Review later',
              subtitle: 'Ask again in a few days',
              onTap: () => _reviewLater(context, s, daysLeft),
            ),

            // Cancel and stop tracking
            _ActionButton(
              background: AppColors.red,
              foreground: Colors.white,
              title: 'Cancel and stop tracking',
              subtitle: 'Remove from dashboard',
              onTap: () => _stopTracking(context, s),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _stopTracking(BuildContext context, Subscription s) async {
    final controller = context.read<ReviewController>();
    final navigator = Navigator.of(context);
    final confirmed = await confirmDialog(
      context,
      title: 'Stop tracking ${s.name}?',
      message: 'SubCheck will stop tracking and reminding you about it. This '
          'does not cancel the subscription itself, so cancel it with '
          '${s.name} before the next payment.',
      confirmLabel: 'Stop tracking',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await controller.stopTracking(s.id);
    if (!context.mounted) return;
    showSnack(context, 'Stopped tracking ${s.name}.');
    navigator.pop();
  }

  /// Figure 6. Review Later: a bottom sheet to choose when to be reminded.
  Future<void> _reviewLater(
      BuildContext context, Subscription s, int daysLeft) async {
    final controller = context.read<ReviewController>();
    final navigator = Navigator.of(context);
    final days = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ReviewLaterSheet(
        options: controller.getReminderOptions(),
        daysUntilPayment: daysLeft,
      ),
    );
    if (days == null || !context.mounted) return;
    await controller.reviewLater(s.id, days);
    if (!context.mounted) return;
    showSnack(context,
        "We'll remind you again in $days day${days == 1 ? '' : 's'}.");
    navigator.pop();
  }
}

/// One of the three big coloured buttons.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.background,
    required this.foreground,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
  });

  final Color background;
  final Color foreground;
  final Color? titleColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: titleColor ?? foreground,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        color: foreground.withValues(alpha: 0.85),
                        fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The "Remind me again in..." bottom sheet. Only days BEFORE the next
/// payment can be chosen; the others are greyed out.
class _ReviewLaterSheet extends StatefulWidget {
  const _ReviewLaterSheet(
      {required this.options, required this.daysUntilPayment});

  final List<int> options;
  final int daysUntilPayment;

  @override
  State<_ReviewLaterSheet> createState() => _ReviewLaterSheetState();
}

class _ReviewLaterSheetState extends State<_ReviewLaterSheet> {
  late List<int> _allowed;
  int? _selected;

  @override
  void initState() {
    super.initState();
    _allowed =
        widget.options.where((d) => d < widget.daysUntilPayment).toList();
    // Start with "In 3 days" like the design, if it is allowed.
    _selected = _allowed.contains(3)
        ? 3
        : (_allowed.isEmpty ? null : _allowed.last);
  }

  String _label(int days) => days == 1 ? 'Tomorrow' : 'In $days days';

  @override
  Widget build(BuildContext context) {
    final until = widget.daysUntilPayment;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: context.cardBorder,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Remind me again in...',
                style: TextStyle(
                    color: context.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 17)),
            const SizedBox(height: 4),
            Text(
              _allowed.isEmpty
                  ? 'Your payment is too close to be reminded again. Please keep it or stop tracking it.'
                  : 'Your next payment is in $until day${until == 1 ? '' : 's'} — pick a day before then.',
              style: TextStyle(color: context.muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            for (final days in widget.options)
              _row(context, days, enabled: _allowed.contains(days)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _selected == null
                  ? null
                  : () => Navigator.pop(context, _selected),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, int days, {required bool enabled}) {
    final on = enabled && _selected == days;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? () => setState(() => _selected = days) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: on ? context.surfaceTint : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: on ? context.ink : context.cardBorder),
          ),
          child: Row(children: [
            Expanded(
              child: Text(
                _label(days),
                style: TextStyle(
                  color: enabled ? context.ink : context.muted,
                  fontWeight: on ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
            Icon(on ? Icons.radio_button_checked : Icons.radio_button_off,
                color: enabled ? context.ink : context.muted, size: 20),
          ]),
        ),
      ),
    );
  }
}
