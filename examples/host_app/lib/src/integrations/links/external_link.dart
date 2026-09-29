part of 'links.dart';

/// Opens https links in the browser; anything else is refused.
abstract final class ExternalLink {
  static Future<bool> open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https') {
      Log.w('Refused to open a non-https link');
      return false;
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
