import 'dart:async';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:lightify/utilities/spotify/spotify_service.dart';

class SpotifyHttpClient extends http.BaseClient {
  final http.Client _inner;
  final VoidCallback onUnauthorized;
  final SpotifyService spotifyService;

  SpotifyHttpClient({
    http.Client? inner,
    required this.onUnauthorized,
    required this.spotifyService,
  }) : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final clone = _copyRequest(request);
    var streamed = await _inner.send(clone);

    // 2️⃣ If the status is 401, notify once
    if (streamed.statusCode == 401) {
      onUnauthorized();
      if (await spotifyService.attemptRefresh()) {
        final retryClone = _copyRequest(request);
        streamed = await _inner.send(retryClone);
      }
    }

    return streamed;
  }
  
  // Pulled from stack overflow <3
  // https://stackoverflow.com/questions/51096991/dart-http-bad-state-cant-finalize-a-finalized-request-when-retrying-a-http

  http.BaseRequest _copyRequest(http.BaseRequest request) {
    http.BaseRequest requestCopy;

    if (request is http.Request) {
      requestCopy = http.Request(request.method, request.url)
        ..encoding = request.encoding
        ..bodyBytes = request.bodyBytes;
    } else if (request is http.MultipartRequest) {
      requestCopy = http.MultipartRequest(request.method, request.url)
        ..fields.addAll(request.fields)
        ..files.addAll(request.files);
    } else if (request is http.StreamedRequest) {
      throw Exception('copying streamed requests is not supported');
    } else {
      throw Exception('request type is unknown, cannot copy');
    }

    requestCopy
      ..persistentConnection = request.persistentConnection
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..headers.addAll(request.headers);

    return requestCopy;
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
