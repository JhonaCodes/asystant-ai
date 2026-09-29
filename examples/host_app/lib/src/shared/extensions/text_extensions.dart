part of 'extensions.dart';

/// Text compared the way people type it: lowercase, without accents.
extension BotanicaText on String {
  static const _plain = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };

  String get searchKey => toLowerCase()
      .split('')
      .map((character) => _plain[character] ?? character)
      .join()
      .trim();
}
