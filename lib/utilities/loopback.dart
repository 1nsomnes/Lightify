import "dart:io";
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
  
  final request = await server.first;
  
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
