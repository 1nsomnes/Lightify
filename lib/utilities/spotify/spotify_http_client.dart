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
    // The original is still readable after being sent, so only copy it when
    // a retry is actually needed.
    final streamed = await _inner.send(request);
    if (streamed.statusCode != 401) return streamed;

    onUnauthorized();
    if (!await spotifyService.attemptRefresh()) return streamed;

    final retry = _copyRequest(request);
    await streamed.stream.drain<void>();
    return _inner.send(retry);
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
