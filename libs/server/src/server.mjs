// server — host HTTP backing (node `http`).
//
// The real minimal server behind `libs/server`'s `#[@external]` declarations
// (see `server.bp`). It is framework-agnostic: it knows nothing about rakun's
// router or `Response`. `serve(port, handler)` starts a node HTTP server and, for
// every request, calls `handler(method, path, headersJson, queryJson, body)` —
// the framework's dispatcher, passed across the boundary as a plain function —
// and writes back whatever it returns (`{ status, body }`). Headers and the query
// string are JSON-encoded so the boundary stays scalar (no map types cross it).
//
// `serve` keeps the process alive (the listening socket holds the event loop);
// `stop` closes it. The Erlang/BEAM transport (gen_tcp / inets / cowboy) is a
// recorded follow-up — this is the node-first surface F5 graduates `server` to.

import http from "node:http";

let _server = null;

export function serve(port, handler) {
  _server = http.createServer((req, res) => {
    const chunks = [];
    req.on("data", (c) => chunks.push(c));
    req.on("end", () => {
      let out;
      try {
        const u = new URL(req.url, "http://localhost");
        const query = {};
        for (const [k, v] of u.searchParams) query[k] = v;
        const body = Buffer.concat(chunks).toString();
        out = handler(req.method, u.pathname, JSON.stringify(req.headers), JSON.stringify(query), body);
      } catch (e) {
        res.writeHead(500, { "content-type": "text/plain; charset=utf-8" });
        res.end(String((e && e.message) || e));
        return;
      }
      const status = out && typeof out.status === "number" ? out.status : 200;
      const body = out && out.body != null ? String(out.body) : "";
      res.writeHead(status, { "content-type": "text/plain; charset=utf-8" });
      res.end(body);
    });
  });
  _server.listen(port);
  return 0;
}

export function stop() {
  if (_server) {
    _server.close();
    _server = null;
  }
  return 0;
}
