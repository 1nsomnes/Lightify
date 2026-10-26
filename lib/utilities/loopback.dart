import "dart:io";
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

Future<Uri> loopbackAuthorize({
  required Uri authorizeUrl,
  int port = 3434,
}) async {
  final server =
      await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  
  if (!await launchUrl(authorizeUrl, mode: LaunchMode.externalApplication)) {
    server.close();
    throw Exception('Could not launch $authorizeUrl');
  }
  
  // browsers can hit the server with unrelated requests (favicon, prefetch),
  // so wait for the actual OAuth redirect
  late final HttpRequest request;
  await for (final req in server) {
    final params = req.uri.queryParameters;
    if (params.containsKey("code") || params.containsKey("error")) {
      request = req;
      break;
    }
    debugPrint("loopback ignoring request to ${req.uri.path}");
    req.response
      ..statusCode = 404
      ..close();
  }
  
  request.response
    ..statusCode = 200
    ..headers.set('Content-Type', 'text/html; charset=utf-8')
    ..write('''
      <html>
        <body>
          <h2>Authentication complete</h2>
          <p>You can now close this window and return to the app.</p>
        </body>
      </html>
    ''')
    ..close();
  
  // make sure that html is actually served
  await Future.delayed(Duration(milliseconds: 50));
  
  await server.close(force: true);
  
  return request.uri;
}
