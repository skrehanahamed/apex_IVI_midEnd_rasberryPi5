#!/usr/bin/env python3
import http.server
import socketserver
import json
import os
import sys

PORT = 8088
JSON_FILE = "/etc/apex-ivi/radio_stations.json"

class RadioHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        clean_path = self.path.split("?")[0]
        if clean_path in ("/radio/stations.json", "/radio/stations"):
            if os.path.exists(JSON_FILE):
                try:
                    with open(JSON_FILE, "rb") as f:
                        data = f.read()
                    self.send_response(200)
                    self.send_header("Content-Type", "application/json; charset=utf-8")
                    self.send_header("Access-Control-Allow-Origin", "*")
                    self.send_header("Content-Length", str(len(data)))
                    self.end_headers()
                    self.wfile.write(data)
                    return
                except Exception as e:
                    self.send_error(500, f"Error reading stations: {e}")
                    return
            else:
                self.send_error(404, "radio_stations.json not found")
                return
        elif clean_path in ("/health", "/"):
            msg = b'{"status":"ok","service":"apex-radio-server"}\n'
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(msg)))
            self.end_headers()
            self.wfile.write(msg)
            return
        else:
            self.send_error(404, "Endpoint not found")

    def do_POST(self):
        clean_path = self.path.split("?")[0]
        if clean_path in ("/radio/stations.json", "/radio/update"):
            content_len = int(self.headers.get("Content-Length", 0))
            post_body = self.rfile.read(content_len)
            try:
                parsed = json.loads(post_body.decode("utf-8"))
                with open(JSON_FILE, "w", encoding="utf-8") as f:
                    json.dump(parsed, f, indent=2)
                res = b'{"status":"success","message":"stations updated"}\n'
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(res)))
                self.end_headers()
                self.wfile.write(res)
            except Exception as e:
                self.send_error(400, f"Invalid JSON payload: {e}")
        else:
            self.send_error(404, "Endpoint not found")

    def log_message(self, format, *args):
        sys.stderr.write("[ApexRadioServer] %s - - [%s] %s\n" % (self.client_address[0], self.log_date_time_string(), format % args))

class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True

if __name__ == "__main__":
    with ReusableTCPServer(("0.0.0.0", PORT), RadioHandler) as httpd:
        print(f"[ApexRadioServer] Listening on http://0.0.0.0:{PORT}")
        httpd.serve_forever()
