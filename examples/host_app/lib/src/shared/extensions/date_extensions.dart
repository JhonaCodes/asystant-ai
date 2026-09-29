part of 'extensions.dart';

/// Dates in neutral Spanish, without the intl package.
extension BotanicaDate on DateTime {
  static const _months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  /// "28 sep 2026".
  String get shortDate {
    final local = toLocal();
    return '${local.day} ${_months[local.month - 1]} ${local.year}';
  }
}
