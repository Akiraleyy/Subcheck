/// LLD class: ValidationError. One problem found in a form.
class ValidationError {
  const ValidationError({
    required this.code,
    required this.field,
    required this.message,
  });

  /// A short machine-readable reason, e.g. "required".
  final String code;

  /// Which form field has the problem: name, price, nextPaymentDate, numberOfPeople.
  final String field;

  /// The text shown under the field.
  final String message;
}

/// LLD class: ValidationResult. The outcome of checking a subscription.
class ValidationResult {
  const ValidationResult(this.errors);

  final List<ValidationError> errors;

  bool get valid => errors.isEmpty;
}

/// Thrown if somebody tries to save a subscription that failed validation.
class ValidationException implements Exception {
  ValidationException(this.result);

  final ValidationResult result;

  @override
  String toString() => result.errors.map((e) => e.message).join(' ');
}
