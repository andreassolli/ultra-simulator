#!/usr/bin/env python3
"""Serve this folder and open the game: `python3 serve.py [port]` (default 8000), then Ctrl+C to stop."""
import http.server, os, socketserver, sys, threading, webbrowser

port = int(sys.argv[1]) if len(sys.argv) > 1 else 8000
os.chdir(os.path.dirname(os.path.abspath(__file__)))

class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map, ".wasm": "application/wasm", ".js": "text/javascript", ".swf": "application/x-shockwave-flash"}

    def log_message(self, *args):
        pass

socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(("127.0.0.1", port), Handler) as httpd:
    url = "http://localhost:%d/play.html" % port
    print("Ultra simulator running at", url, "(Ctrl+C to stop)")
    threading.Timer(0.5, lambda: webbrowser.open(url)).start()
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
