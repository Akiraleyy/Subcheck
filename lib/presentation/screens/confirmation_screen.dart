import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data_access/models/enums.dart';
import '../../theme.dart';
import '../../utils/helpers.dart';
import '../controllers/subscription_controller.dart';
import '../widgets/common.dart';
import 'subscription_details_screen.dart';

/// Figure 3. Confirmation, shown right after a subscription is saved.
class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({super.key, required this.subscriptionId});

  final String subscriptionId;

  @override
  Widget build(BuildContext context) {
    final s =
        context.read<SubscriptionController>().getSubscription(subscriptionId);
    if (s == null) return const Scaffold();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                    color: AppColors.lime, shape: BoxShape.circle),
                child:
                    const Icon(Icons.check, color: AppColors.purple, size: 30),
              ),
              const SizedBox(height: 14),
              Text('${s.name} added',
                  style: TextStyle(
                      color: context.ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text('Next payment ${DateFormat.yMMMd().format(s.nextPaymentDate)}',
                  style: TextStyle(color: context.muted)),
              Text('${peso(s.yourShare)} / ${s.billingCycle.unit}',
                  style: TextStyle(color: context.muted)),
              const Spacer(),

              // Done: back to the Home Dashboard.
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Done'),
              ),
              const SizedBox(height: 10),

              // View Subscription: Home first, then the details screen on top.
              SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: context.surfaceTint,
                    foregroundColor: context.ink,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final navigator = Navigator.of(context);
                    navigator.popUntil((route) => route.isFirst);
                    navigator.push(MaterialPageRoute(
                      builder: (_) =>
                          SubscriptionDetailsScreen(subscriptionId: s.id),
                    ));
                  },
                  child: const Text('View Subscription',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}