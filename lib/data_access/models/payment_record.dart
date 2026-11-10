/// LLD class: PaymentRecord. One past payment, shown in green on the calendar.
class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.subscriptionId,
    required this.amount,
    required this.paymentDate,
    required this.isPaid,
  });

  final String id;
  final String subscriptionId;

  /// The amount the user paid (their share if the subscription is shared).
  final double amount;
  final DateTime paymentDate;
  final bool isPaid;

  Map<String, dynamic> toJson() => {
        'id': id,
        'subscriptionId': subscriptionId,
        'amount': amount,
        'paymentDate': paymentDate.toIso8601String(),
        'isPaid': isPaid,
      };

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: json['id'] as String,
      subscriptionId: json['subscriptionId'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(json['paymentDate'] as String),
      isPaid: json['isPaid'] as bool? ?? true,
    );
  }
}
