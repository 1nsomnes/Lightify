import 'dart:async';
import 'dart:ui';
import 'package:http/http.dart' as http;

class SpotifyHttpClient extends http.BaseClient {
  final http.Client _inner;
  final VoidCallback onUnauthorized;

  SpotifyHttpClient({http.Client? inner, required this.onUnauthorized})
    : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final streamed = await _inner.send(request);

    // 2️⃣ If the status is 401, notify once
    if (streamed.statusCode == 401) {
      onUnauthorized();
      // (optional) you could attempt a refresh+retry here
    }

    // 3️⃣ Return the (possibly original) response
    return streamed;
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
