import http.server
import socketserver
import os

os.chdir('c:\\Users\\PC\\AuraSphere\\crm\\aura_crm\\build\\web')

class MyHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        path = self.path
        if path.endswith('/'):
            path = path[:-1]
        
        # Route all non-file requests to index.html
        if not os.path.isfile(path.lstrip('/')):
            self.path = '/index.html'
        
        return super().do_GET()

PORT = 3000
Handler = MyHandler

with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print(f"Server running at http://localhost:{PORT}")
    httpd.serve_forever()
