import 'enums.dart';

/// LLD class: Subscription. One subscription the user is tracking.
class Subscription {
  const Subscription({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.billingCycle,
    required this.nextPaymentDate,
    this.logoPath,
    this.isShared = false,
    this.numberOfPeople = 1,
    this.status = SubscriptionStatus.active,
  });

  final String id;
  final String name;
  final Category category;

  /// The full price of the subscription (not the user's share).
  final double price;
  final BillingCycle billingCycle;
  final DateTime nextPaymentDate;

  /// Path of the logo image on the phone, or null if none was uploaded.
  final String? logoPath;
  final bool isShared;

  /// How many people split the cost, including the user. 1 when not shared.
  final int numberOfPeople;
  final SubscriptionStatus status;

  bool get isActive => status == SubscriptionStatus.active;

  /// Returns a copy with some fields changed (records are never edited in place).
  Subscription copyWith({
    String? name,
    Category? category,
    double? price,
    BillingCycle? billingCycle,
    DateTime? nextPaymentDate,
    String? logoPath,
    bool clearLogo = false,
    bool? isShared,
    int? numberOfPeople,
    SubscriptionStatus? status,
  }) {
    return Subscription(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      billingCycle: billingCycle ?? this.billingCycle,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      logoPath: clearLogo ? null : (logoPath ?? this.logoPath),
      isShared: isShared ?? this.isShared,
      numberOfPeople: numberOfPeople ?? this.numberOfPeople,
      status: status ?? this.status,
    );
  }

  // ---- saving and loading (turns the object into plain text-friendly data) ----

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'price': price,
        'billingCycle': billingCycle.name,
        'nextPaymentDate': nextPaymentDate.toIso8601String(),
        'logoPath': logoPath,
        'isShared': isShared,
        'numberOfPeople': numberOfPeople,
        'status': status.name,
      };

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      name: json['name'] as String,
      category: Category.values.byName(json['category'] as String),
      price: (json['price'] as num).toDouble(),
      billingCycle: BillingCycle.values.byName(json['billingCycle'] as String),
      nextPaymentDate: DateTime.parse(json['nextPaymentDate'] as String),
      logoPath: json['logoPath'] as String?,
      isShared: json['isShared'] as bool? ?? false,
      numberOfPeople: json['numberOfPeople'] as int? ?? 1,
      status: SubscriptionStatus.values
          .byName(json['status'] as String? ?? SubscriptionStatus.active.name),
    );
  }
}
