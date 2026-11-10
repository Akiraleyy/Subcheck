import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/helpers.dart';

/// Keeps a copy of the logo the user picked.
///
/// The gallery picker hands back a temporary file that the phone may delete
/// later, so the image is copied into the app's own folder. The saved
/// subscription stores the path of that copy (Subscription.logoPath).
class LogoStore {
  /// Returns the path of the saved copy. If copying is not possible (for
  /// example when running in a web browser) the original path is returned.
  Future<String?> save(String? sourcePath) async {
    if (sourcePath == null || kIsWeb) return sourcePath;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dot = sourcePath.lastIndexOf('.');
      final extension = dot == -1 ? '' : sourcePath.substring(dot);
      final destination = '${dir.path}/logo_${newUuid()}$extension';
      await File(sourcePath).copy(destination);
      return destination;
    } catch (_) {
      return sourcePath;
    }
  }
}
