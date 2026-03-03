import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

/// Helper to provide a custom CacheManager with a professional User-Agent
/// This helps avoid loading issues with CDNs that block default Dart user-agents
class ImageCacheHelper {
  static const String _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36';

  static final CacheManager customCacheManager = CacheManager(
    Config(
      'pivote_custom_cache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 200,
      repo: JsonCacheInfoRepository(databaseName: 'pivote_custom_cache'),
      fileService: HttpFileService(
        httpClient: _UserAgentClient(http.Client(), _userAgent),
      ),
    ),
  );
}

/// Simple HTTP client wrapper to inject the User-Agent
class _UserAgentClient extends http.BaseClient {
  final http.Client _inner;
  final String _userAgent;

  _UserAgentClient(this._inner, this._userAgent);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['user-agent'] = _userAgent;
    return _inner.send(request);
  }
}
