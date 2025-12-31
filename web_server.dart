import 'dart:async';
import 'dart:io';

Future<void> main() async {
  final server = await HttpServer.bind('localhost', 8080);
  print('🚀 Server running at http://localhost:8080');
  
  await for (HttpRequest request in server) {
    try {
      var path = request.uri.path;
      if (path == '/') path = '/index.html';
      
      final file = File('build/web$path');
      
      if (await file.exists()) {
        request.response.statusCode = 200;
        if (path.endsWith('.html')) {
          request.response.headers.contentType = ContentType.html;
          // Disable cache for HTML files to ensure fresh content
          request.response.headers.add('Cache-Control', 'no-cache, no-store, must-revalidate');
          request.response.headers.add('Pragma', 'no-cache');
          request.response.headers.add('Expires', '0');
        } else if (path.endsWith('.js')) {
          request.response.headers.add('Content-Type', 'application/javascript');
          request.response.headers.add('Cache-Control', 'no-cache, no-store, must-revalidate');
        } else if (path.endsWith('.json')) {
          request.response.headers.contentType = ContentType.json;
        }
        request.response.headers.add('Access-Control-Allow-Origin', '*');
        request.response.add(await file.readAsBytes());
      } else {
        // Try index.html for SPA routing
        final indexFile = File('build/web/index.html');
        if (await indexFile.exists()) {
          request.response.statusCode = 200;
          request.response.headers.contentType = ContentType.html;
          request.response.headers.add('Access-Control-Allow-Origin', '*');
          request.response.add(await indexFile.readAsBytes());
        } else {
          request.response.statusCode = 404;
          request.response.write('Not Found: $path');
        }
      }
    } catch (e) {
      request.response.statusCode = 500;
      request.response.write('Error: $e');
    }
    await request.response.close();
  }
}
