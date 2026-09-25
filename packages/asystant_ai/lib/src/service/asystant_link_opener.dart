import 'dart:async';

import 'package:url_launcher/url_launcher.dart';

/// Handles an explicitly tapped HTTP(S) link. Return false to show a failure.
typedef AsystantLinkCallback = FutureOr<bool> Function(Uri uri);

/// Opens user-activated links without granting model text platform capabilities.
///
/// Validation also applies to custom handlers. Embedded credentials and schemes
/// such as javascript, data and file never reach the host or platform launcher.
class AsystantLinkOpener {
  const AsystantLinkOpener({this.onOpenLink});

  final AsystantLinkCallback? onOpenLink;

  /// Validates and opens a link only when called from an explicit user action.
  /// Plugin or host-handler failures are returned, never thrown into the chat.
  Future<bool> open(String? destination) async {
    if (destination == null ||
        destination.length > 8192 ||
        RegExp(r'[\x00-\x20\x7f]').hasMatch(destination)) {
      return false;
    }
    final uri = Uri.tryParse(destination);
    if (uri == null ||
        !const {'https', 'http'}.contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return false;
    }

    try {
      final handler = onOpenLink;
      return await (handler == null
          ? launchUrl(uri, mode: .externalApplication)
          : handler(uri));
    } catch (_) {
      return false;
    }
  }
}
