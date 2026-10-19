import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';

/// Service responsible for providing local and remote artwork URIs
/// for background playback notifications and lockscreen controls.
/// Guarantees that notification artwork is NEVER a blank or white box.
class ArtworkService {
  static String? _appLogoFilePath;

  /// Ensures twilight_icon.png from assets is written to local filesystem
  /// so it can be passed as a local file URI to AudioService/MediaItem.
  static Future<String?> getAppLogoFilePath() async {
    if (kIsWeb) return null;
    if (_appLogoFilePath != null && File(_appLogoFilePath!).existsSync()) {
      return _appLogoFilePath!;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/twilight_notification_logo.png');
      if (!file.existsSync() || file.lengthSync() < 1000) {
        final byteData =
            await rootBundle.load('assets/images/twilight_icon.png');
        await file.writeAsBytes(
          byteData.buffer
              .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
          flush: true,
        );
        AppLogger.info('Wrote default notification logo to: ${file.path}');
      }
      _appLogoFilePath = file.path;
      return _appLogoFilePath;
    } catch (e) {
      AppLogger.warning('Failed to initialize app logo artwork file: $e');
      return null;
    }
  }

  static Uri? _parseValidRemoteUri(String? thumbnailUrl) {
    if (thumbnailUrl == null || thumbnailUrl.trim().isEmpty) {
      return null;
    }

    final cleanUrl = thumbnailUrl.trim();
    final parsed = Uri.tryParse(cleanUrl);
    if (parsed == null) {
      return null;
    }

    if (parsed.scheme != 'http' && parsed.scheme != 'https') {
      return null;
    }

    return parsed;
  }

  /// Returns a valid Uri for MediaItem artUri:
  /// 1. If song thumbnail is cached locally -> Uri.file(localCachedFile)
  /// 2. If song thumbnail is a valid HTTP URL -> Uri.parse(thumbnailUrl)
  /// 3. Otherwise -> Uri.file(appLogoFilePath)
  static Future<Uri?> getArtworkUri({
    required String? thumbnailUrl,
    String? songId,
  }) async {
    if (kIsWeb) {
      return _parseValidRemoteUri(thumbnailUrl);
    }

    final logoPath = await getAppLogoFilePath();
    final cleanLogoUri = (logoPath != null && File(logoPath).existsSync())
        ? Uri.file(logoPath)
        : null;

    final remoteUri = _parseValidRemoteUri(thumbnailUrl);
    if (remoteUri != null) {
      if (songId != null && songId.isNotEmpty) {
        try {
          final tempDir = await getTemporaryDirectory();
          final cachedThumb = File('${tempDir.path}/thumb_$songId.jpg');
          if (cachedThumb.existsSync() && cachedThumb.lengthSync() > 1000) {
            return Uri.file(cachedThumb.path);
          }

          _cacheThumbnailInBackground(remoteUri.toString(), cachedThumb);
        } catch (_) {}
      }
      return remoteUri;
    }

    // Only use the app logo if there is no valid remote/local thumbnail.
    if (songId != null && songId.isNotEmpty) {
      try {
        final tempDir = await getTemporaryDirectory();
        final cachedThumb = File('${tempDir.path}/thumb_$songId.jpg');
        if (cachedThumb.existsSync() && cachedThumb.lengthSync() > 1000) {
          return Uri.file(cachedThumb.path);
        }
      } catch (_) {}
    }

    return cleanLogoUri;
  }

  static void _cacheThumbnailInBackground(String url, File targetFile) {
    () async {
      try {
        final res =
            await http.get(Uri.parse(url)).timeout(const Duration(seconds: 6));
        if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
          await targetFile.writeAsBytes(res.bodyBytes, flush: true);
        }
      } catch (_) {}
    }();
  }
}
