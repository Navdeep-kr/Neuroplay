import http.server
import socketserver
import os
import mimetypes

PORT = 8080
DIRECTORY = os.path.join(os.path.dirname(os.path.abspath(__file__)), "app", "build", "web")

# Ensure proper mime types
mimetypes.add_type("application/javascript", ".js")
mimetypes.add_type("application/wasm", ".wasm")
mimetypes.add_type("text/html", ".html")
mimetypes.add_type("application/json", ".json")

class SPAServerHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def do_GET(self):
        # Direct root visitors to the official marketing website homepage
        if self.path in ("/", ""):
            host_header = self.headers.get("Host", "localhost:8080")
            host_only = host_header.split(":")[0]
            self.send_response(302)
            self.send_header("Location", f"http://{host_only}:3000/")
            self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
            self.end_headers()
            return

        # Resolve target file path
        path = self.translate_path(self.path)
        if not os.path.exists(path) and "." not in os.path.basename(self.path):
            self.path = "/index.html"
        return super().do_GET()

    def end_headers(self):
        # Prevent caching during development/testing
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()

if __name__ == "__main__":
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("0.0.0.0", PORT), SPAServerHandler) as httpd:
        print(f"Serving NEUROPLAY at http://0.0.0.0:{PORT}")
        httpd.serve_forever()
