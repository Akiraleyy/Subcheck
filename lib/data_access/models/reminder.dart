/// The three kinds of reminder SubCheck sends.
class ReminderType {
  /// 7 days before a payment: "Netflix renews in 7 days" (time to review).
  static const renewal = 'renewal';

  /// 1 day before a payment: "Netflix payment tomorrow".
  static const payment = 'payment';

  /// The day the user picked in "Review later".
  static const review = 'review';
}

/// LLD class: Reminder. One local notification that is planned for a date.
/// [title] and [body] are small additions so the text can be saved with it.
class Reminder {
  const Reminder({
    required this.id,
    required this.subscriptionId,
    required this.scheduledDate,
    required this.type,
    required this.isSent,
    required this.title,
    required this.body,
  });

  final String id;
  final String subscriptionId;
  final DateTime scheduledDate;
  final String type;
  final bool isSent;
  final String title;
  final String body;

  Reminder copyWith({bool? isSent}) => Reminder(
        id: id,
        subscriptionId: subscriptionId,
        scheduledDate: scheduledDate,
        type: type,
        isSent: isSent ?? this.isSent,
        title: title,
        body: body,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'subscriptionId': subscriptionId,
        'scheduledDate': scheduledDate.toIso8601String(),
        'type': type,
        'isSent': isSent,
        'title': title,
        'body': body,
      };

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      subscriptionId: json['subscriptionId'] as String,
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      type: json['type'] as String,
      isSent: json['isSent'] as bool? ?? false,
      title: json['title'] as String? ?? 'SubCheck',
      body: json['body'] as String? ?? '',
    );
  }
}
