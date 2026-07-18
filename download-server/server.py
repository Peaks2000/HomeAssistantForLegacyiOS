#!/usr/bin/env python3

import argparse
import mimetypes
import socket
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit


SERVER_DIRECTORY = Path(__file__).resolve().parent
PACKAGE_DIRECTORY = SERVER_DIRECTORY.parent / "packages"
INDEX_FILE = SERVER_DIRECTORY / "index.html"
DOWNLOADS = {
    "/download/armv7": PACKAGE_DIRECTORY / "org.home-assistant.legacy_0.5.6_ios4-armv7.deb",
    "/download/arm64": PACKAGE_DIRECTORY / "org.home-assistant.legacy_0.5.6_ios7-arm64.deb",
    "/download/rootless-arm64": PACKAGE_DIRECTORY / "org.home-assistant.legacy_0.5.6_ios15-rootless-arm64.deb",
}


class DownloadHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        path = urlsplit(self.path).path
        if path in ("/", "/index.html"):
            self.send_file(INDEX_FILE, download=False)
            return
        if path in DOWNLOADS:
            self.send_file(DOWNLOADS[path], download=True)
            return
        self.send_error(404, "Not found")

    def do_HEAD(self):
        path = urlsplit(self.path).path
        if path in ("/", "/index.html"):
            self.send_file(INDEX_FILE, download=False, include_body=False)
            return
        if path in DOWNLOADS:
            self.send_file(DOWNLOADS[path], download=True, include_body=False)
            return
        self.send_error(404, "Not found")

    def send_file(self, path, download, include_body=True):
        if not path.is_file():
            self.send_error(404, "Download is not available")
            return
        content_type = mimetypes.guess_type(path.name)[0] or "application/octet-stream"
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(path.stat().st_size))
        self.send_header("Cache-Control", "no-store")
        if download:
            self.send_header("Content-Disposition", f'attachment; filename="{path.name}"')
        self.end_headers()
        if include_body:
            with path.open("rb") as source:
                while chunk := source.read(64 * 1024):
                    self.wfile.write(chunk)


def parse_arguments():
    parser = argparse.ArgumentParser(description="Serve Home Assistant Legacy packages")
    parser.add_argument("--bind", default="0.0.0.0", help="Address to listen on")
    parser.add_argument("--port", type=int, default=8080, help="TCP port to listen on")
    parser.add_argument(
        "--auto-port",
        action="store_true",
        help="Try the next 20 ports when the requested port is occupied",
    )
    return parser.parse_args()


def create_server(bind_address, requested_port, auto_port):
    ports = range(requested_port, requested_port + 20) if auto_port else (requested_port,)
    last_error = None
    for port in ports:
        try:
            return ThreadingHTTPServer((bind_address, port), DownloadHandler)
        except OSError as error:
            last_error = error
            if error.errno != 98 or not auto_port:
                break
    if last_error is not None and last_error.errno == 98:
        suggestion = " Try a different port, for example: ./start-download-server.sh 9000"
        if auto_port:
            suggestion = f" Tried ports {requested_port}-{requested_port + 19}."
        raise SystemExit(f"Could not start: the requested port is already in use.{suggestion}")
    raise SystemExit(f"Could not start the server: {last_error}")


def lan_address():
    probe = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        probe.connect(("192.0.2.1", 80))
        return probe.getsockname()[0]
    except OSError:
        return None
    finally:
        probe.close()


def main():
    arguments = parse_arguments()
    missing = [str(path) for path in DOWNLOADS.values() if not path.is_file()]
    if missing:
        raise SystemExit("Missing package files:\n" + "\n".join(missing))
    server = create_server(arguments.bind, arguments.port, arguments.auto_port)
    actual_port = server.server_address[1]
    address = lan_address() if arguments.bind == "0.0.0.0" else arguments.bind
    print(f"Download server: http://{address or arguments.bind}:{actual_port}")
    if actual_port != arguments.port:
        print(f"Port {arguments.port} was busy, so port {actual_port} was selected automatically.")
    print("Press Ctrl+C to stop it.")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping server.")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
