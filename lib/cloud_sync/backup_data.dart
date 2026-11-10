import '../data_access/models/payment_record.dart';
import '../data_access/models/review_record.dart';
import '../data_access/models/subscription.dart';

/// LLD class: BackupData. Everything that is uploaded to / downloaded from
/// the cloud: the user's subscriptions, review decisions and payment history.
/// (Reminders are not backed up; they are rebuilt from the subscriptions.)
class BackupData {
  const BackupData({
    required this.subscriptions,
    required this.reviewRecords,
    required this.paymentRecords,
    required this.createdAt,
  });

  final List<Subscription> subscriptions;
  final List<ReviewRecord> reviewRecords;
  final List<PaymentRecord> paymentRecords;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'createdAt': createdAt.toIso8601String(),
        'subscriptions': subscriptions.map((s) => s.toJson()).toList(),
        'reviewRecords': reviewRecords.map((r) => r.toJson()).toList(),
        'paymentRecords': paymentRecords.map((p) => p.toJson()).toList(),
      };

  factory BackupData.fromJson(Map<String, dynamic> json) {
    List<T> readList<T>(String key, T Function(Map<String, dynamic>) parse) {
      final raw = (json[key] as List<dynamic>?) ?? const [];
      return raw
          .map((row) => parse(Map<String, dynamic>.from(row as Map)))
          .toList();
    }

    return BackupData(
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      subscriptions: readList('subscriptions', Subscription.fromJson),
      reviewRecords: readList('reviewRecords', ReviewRecord.fromJson),
      paymentRecords: readList('paymentRecords', PaymentRecord.fromJson),
    );
  }
}
