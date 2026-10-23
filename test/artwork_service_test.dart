import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody_tube/core/services/artwork_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory' ||
            methodCall.method == 'getTemporaryDirectory') {
          return '.';
        }
        return null;
      },
    );
  });

  group('ArtworkService Tests', () {
    test('getArtworkUri returns parsed URI for valid HTTP thumbnail', () async {
      final uri = await ArtworkService.getArtworkUri(
        thumbnailUrl: 'https://i.ytimg.com/vi/test/hqdefault.jpg',
        songId: 'test_song',
      );
      expect(uri, isNotNull);
      expect(
          uri.toString(), equals('https://i.ytimg.com/vi/test/hqdefault.jpg'));
    });

    test('getAppLogoFilePath resolves the bundled app logo for fallback art',
        () async {
      final logoPath = await ArtworkService.getAppLogoFilePath();
      expect(logoPath, isNotNull);
      expect(File(logoPath!).existsSync(), isTrue);

      final uri = await ArtworkService.getArtworkUri(
        thumbnailUrl: '',
        songId: 'empty_song',
      );
      expect(uri, isNotNull);
      expect(uri!.scheme, equals('file'));
      expect(File.fromUri(uri).existsSync(), isTrue);
    });

    test('getArtworkUri handles empty or null thumbnail gracefully', () async {
      final uri = await ArtworkService.getArtworkUri(
        thumbnailUrl: '',
        songId: 'empty_song',
      );
      expect(uri, isNotNull);
      expect(uri!.scheme, equals('file'));
    });

    test('getArtworkUri falls back for malformed HTTP artwork URLs', () async {
      final uri = await ArtworkService.getArtworkUri(
        thumbnailUrl: 'https://',
        songId: 'malformed_song',
      );
      expect(uri, isNotNull);
      expect(uri!.scheme, equals('file'));
      expect(File.fromUri(uri).existsSync(), isTrue);
    });
  });
}
