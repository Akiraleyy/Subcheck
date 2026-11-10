import 'enums.dart';

/// LLD class: ReviewRecord. Remembers one review decision.
///
/// Two small additions to the LLD (see README, "Differences from the LLD"):
///  * [paymentDate] says which renewal the decision was about.
///  * [decision] is null for a MISSED review: the payment date passed and the
///    user never chose Keep. The calendar shows those in red.
class ReviewRecord {
  const ReviewRecord({
    required this.id,
    required this.subscriptionId,
    required this.decision,
    required this.reviewDate,
    required this.paymentDate,
    this.remindAgainDate,
  });

  final String id;
  final String subscriptionId;
  final ReviewDecision? decision;

  /// When the user made the decision.
  final DateTime reviewDate;

  /// Only for "Review later": the day the user asked to be reminded again.
  final DateTime? remindAgainDate;

  /// The renewal date this decision belongs to.
  final DateTime paymentDate;

  bool get isMissed => decision == null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'subscriptionId': subscriptionId,
        'decision': decision?.name,
        'reviewDate': reviewDate.toIso8601String(),
        'remindAgainDate': remindAgainDate?.toIso8601String(),
        'paymentDate': paymentDate.toIso8601String(),
      };

  factory ReviewRecord.fromJson(Map<String, dynamic> json) {
    final decision = json['decision'] as String?;
    final remind = json['remindAgainDate'] as String?;
    return ReviewRecord(
      id: json['id'] as String,
      subscriptionId: json['subscriptionId'] as String,
      decision: decision == null ? null : ReviewDecision.values.byName(decision),
      reviewDate: DateTime.parse(json['reviewDate'] as String),
      remindAgainDate: remind == null ? null : DateTime.parse(remind),
      paymentDate: DateTime.parse(json['paymentDate'] as String),
    );
  }
}
