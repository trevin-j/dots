from flask import Flask, Response, jsonify, request
from config import Settings
from compiler import compile_css_for_url


def create_app(settings: Settings = Settings()) -> Flask:
    app = Flask(__name__)

    def _add_cors(resp: Response) -> Response:
        if settings.enable_cors:
            resp.headers["Access-Control-Allow-Origin"] = settings.cors_allow_origin
            resp.headers["Access-Control-Allow-Methods"] = "GET, OPTIONS"
            resp.headers["Access-Control-Allow-Headers"] = "Content-Type, If-None-Match"
        return resp

    @app.route("/health", methods=["GET"])
    def health():
        return _add_cors(jsonify({"ok": True}))

    @app.route("/css", methods=["GET", "OPTIONS"])
    def css():
        if request.method == "OPTIONS":
            resp = Response("", status=204)
            return _add_cors(resp)

        url = request.args.get("url", "")
        if not url:
            resp = jsonify({"error": "missing url query param"})
            resp.status_code = 400
            return _add_cors(resp)

        css_text, etag = compile_css_for_url(url, settings.scheme_path, settings.sites_dir)

        inm = request.headers.get("If-None-Match")
        quoted_etag = f"\"{etag}\""

        if inm == quoted_etag:
            resp = Response(status=304)
            resp.headers["ETag"] = quoted_etag
            resp.headers["Cache-Control"] = "no-cache"
            return _add_cors(resp)

        resp = Response(css_text, status=200, mimetype="text/css; charset=utf-8")
        resp.headers["ETag"] = quoted_etag
        resp.headers["Cache-Control"] = "no-cache"
        # Useful debugging:
        resp.headers["X-Theme-Server"] = "mat-css-v0"
        return _add_cors(resp)

    return app


if __name__ == "__main__":
    # Run:
    #   python app.py
    app = create_app()
    app.run(host="127.0.0.1", port=8787, debug=True)

