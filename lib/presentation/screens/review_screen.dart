import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../theme.dart';
import '../../utils/helpers.dart';
import '../controllers/review_controller.dart';
import '../data_refresh.dart';
import '../widgets/common.dart';
import 'subscription_review_screen.dart';

/// Figure 4. Review: subscriptions with upcoming renewal dates.
class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<DataRefresh>();
    final list = context.read<ReviewController>().getReviewList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text('Review',
            style: TextStyle(
                color: context.ink, fontSize: 22, fontWeight: FontWeight.w900)),
        Text('Subscriptions to review before renewal',
            style: TextStyle(color: context.muted, fontSize: 13)),
        const SizedBox(height: 16),

        if (list.isEmpty) ...[
          const SizedBox(height: 60),
          Icon(Icons.task_alt, size: 56, color: context.muted),
          const SizedBox(height: 12),
          Center(
            child: Text('Nothing to review right now',
                style: TextStyle(
                    color: context.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text('Subscriptions show up here a week before they renew.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.muted)),
          ),
        ],

        for (final s in list)
          SubTile(
            subscription: s,
            subtitle: DateFormat.yMMMMd().format(s.nextPaymentDate),
            amount: peso(s.yourShare),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      SubscriptionReviewScreen(subscriptionId: s.id)),
            ),
          ),
      ],
    );
  }
}
