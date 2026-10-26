import 'package:flutter_test/flutter_test.dart';
import 'package:pivote/features/video/data/models/channel.dart';

void main() {
  group('ClearKey & ESPN Channel Parsing', () {
    test('parses ESPN flow channel with base64url clearkey and headers', () {
      final json = {
        "name": "ESPN",
        "type": "CLEARKEY",
        "icono": "https://i.postimg.cc/T5YBc3cB/ESPN-1-Argentina.png",
        "drm_license_uri":
            "kid:0Hn_o3V-gzVhH8SL5rpH_w,k:BQWdHLIbZwilXpwm-zji8w",
        "original_url":
            "https://cdn-token.app.flow.com.ar/cdntoken/v2/generator?path=manifest.mpd",
        "headers": {
          "Origin": "https://portal.app.flow.com.ar",
          "Referer": "https://portal.app.flow.com.ar/",
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
        }
      };

      final channel = Channel.fromJson(json);

      expect(channel.name, equals('ESPN'));
      expect(channel.type, equals('dash'));
      expect(channel.logoUrl,
          contains('https://i.postimg.cc/T5YBc3cB/ESPN-1-Argentina.png'));
      expect(channel.streamUrl.length, equals(1));

      final stream = channel.streamUrl.first;
      expect(
          stream.url,
          equals(
              'https://cdn-token.app.flow.com.ar/cdntoken/v2/generator?path=manifest.mpd'));
      expect(stream.hasDrm, isTrue);
      expect(stream.clearkeys, isNotNull);
      expect(stream.clearkeys!.length, equals(1));

      // Check normalized hex keys (32 hex characters)
      final kidHex = stream.clearkeys!.keys.first;
      final keyHex = stream.clearkeys!.values.first;
      expect(kidHex.length, equals(32));
      expect(keyHex.length, equals(32));

      // Verify headers
      expect(stream.headers, isNotNull);
      expect(
          stream.headers!['Origin'], equals('https://portal.app.flow.com.ar'));
      expect(stream.headers!['Referer'],
          equals('https://portal.app.flow.com.ar/'));
      expect(stream.headers!['User-Agent'],
          equals('Mozilla/5.0 (Windows NT 10.0; Win64; x64)'));

      // Check stream type
      expect(channel.getStreamType(stream.url), equals(StreamType.dash));
      expect(stream.isDash, isTrue);
    });

    test('parses legacy Firestore format with k1/k2', () {
      final json = {
        "id": "espn_legacy",
        "name": "ESPN 2",
        "logoUrl": ["https://logo.png"],
        "streamUrl": [
          {
            "url": "https://example.com/manifest.mpd",
            "k1": "d079ffa3757e833561611fc4b6ba47ff",
            "k2": "050559dcb21b6708a55e9c26fb38e2f3"
          }
        ]
      };

      final channel = Channel.fromJson(json);
      expect(channel.streamUrl.first.hasDrm, isTrue);
      expect(channel.streamUrl.first.k1,
          equals("d079ffa3757e833561611fc4b6ba47ff"));
      expect(
          channel.streamUrl.first
              .effectiveClearkeys!["d079ffa3757e833561611fc4b6ba47ff"],
          equals("050559dcb21b6708a55e9c26fb38e2f3"));
    });
  });
}
