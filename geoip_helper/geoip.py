import http.server
import re
import json

import geoip2.database
import geoip2.errors


def main():
    # Can download from https://git.io/GeoLite2-City.mmdb
    reader = geoip2.database.Reader("GeoLite2-City.mmdb")

    server = http.server.HTTPServer(("127.0.0.1", 8345), Handler)
    server.geoip_reader = reader
    server.serve_forever()


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        match = re.match(r"/geoip-json/([0-9.:]+)", self.path)
        if not match:
            self.send_error(404)
            return

        ip_address = match.group(1)

        # https://web.archive.org/web/20200807042950/http://smart-ip.net/geoip-api
        try:
            geoip_response = self.server.geoip_reader.city(ip_address)

            doc = {
                "source": "geolite2",
                "host": ip_address,
                "lang": "en",
                "countryName": geoip_response.country.names["en"],
                "countryCode": geoip_response.country.iso_code,
                "latitude": geoip_response.location.latitude,
                "longitude": geoip_response.location.longitude,
            }

        except (geoip2.errors.AddressNotFoundError, KeyError):
            doc = {
                "source": "geolite2",
                "host": ip_address,
            }

        except ValueError:
            self.send_error(404)
            return

        output = json.dumps(doc)

        self.send_response(200)
        self.send_header("Content-Length", str(len(output)))
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(output.encode("utf-8"))


if __name__ == "__main__":
    main()
