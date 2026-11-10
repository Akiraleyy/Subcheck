import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data_access/models/subscription.dart';
import '../../subscription_management/cost_calculator.dart';
import '../../theme.dart';

/// Display helper: the user's share of a subscription's price. It reuses
/// CostCalculator so the maths lives in one place.
extension SubscriptionDisplay on Subscription {
  double get yourShare => const CostCalculator().getUserShare(this);
}

/// Draws the dashed rounded border used by the logo placeholder in the design.
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter(this.color, this.radius);

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, Radius.circular(radius)));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 4), paint);
        distance += 8;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

/// The service logo, or the dashed image placeholder when there is none.
class SubLogo extends StatelessWidget {
  const SubLogo({super.key, this.path, this.size = 40});

  final String? path;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = path;
    final hasImage = !kIsWeb && p != null && File(p).existsSync();
    return SizedBox(
      width: size,
      height: size,
      child: hasImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(File(p), fit: BoxFit.cover),
            )
          : CustomPaint(
              painter: _DashedBorderPainter(context.ink, 10),
              child: Center(
                child: Icon(Icons.image_outlined,
                    size: size * 0.45, color: context.ink),
              ),
            ),
    );
  }
}

/// A rounded row used in lists: logo, name, subtitle and amount.
class SubTile extends StatelessWidget {
  const SubTile({
    super.key,
    required this.subscription,
    required this.subtitle,
    required this.amount,
    this.onTap,
  });

  final Subscription subscription;
  final String subtitle;
  final String amount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.cardBorder),
            ),
            child: Row(
              children: [
                SubLogo(path: subscription.logoPath),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(subscription.name,
                          style: TextStyle(
                              color: context.ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                      Text(subtitle,
                          style: TextStyle(color: context.muted, fontSize: 13)),
                    ],
                  ),
                ),
                Text(amount,
                    style: TextStyle(
                        color: context.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 8),
        child: Text(text,
            style: TextStyle(
                color: context.ink, fontWeight: FontWeight.w800, fontSize: 15)),
      );
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(text,
            style: TextStyle(
                color: context.ink, fontWeight: FontWeight.w700, fontSize: 13)),
      );
}

/// A dropdown styled like the text fields (used for Category and Billing cycle).
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          items: [
            for (final item in items)
              DropdownMenuItem<T>(value: item, child: Text(labelOf(item))),
          ],
          onChanged: (picked) {
            if (picked != null) onChanged(picked);
          },
        ),
      ),
    );
  }
}

/// Shows a short message at the bottom of the screen.
void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ));
}

/// A Cancel / Confirm pop-up. Returns true if the user confirmed.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(confirmLabel,
              style: TextStyle(color: destructive ? AppColors.red : null)),
        ),
      ],
    ),
  );
  return result ?? false;
}
