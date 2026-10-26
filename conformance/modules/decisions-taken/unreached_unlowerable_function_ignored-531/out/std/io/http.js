function __bp_f64(v) {
    if (Number.isNaN(v)) { return "NaN"; }
    if (!Number.isFinite(v)) { return (v < 0) ? "-Infinity" : "Infinity"; }
    if (v === 0) { return Object.is(v, -0) ? "-0.0" : "0.0"; }
    const t = Math.abs(v).toExponential();
    const i = t.indexOf("e");
    const d = t.slice(0, i).replace(".", "");
    const e = Number(t.slice(i + 1));
    const g = (v < 0) ? "-" : "";
    const x = g + d[0] + "." + ((d.length > 1) ? d.slice(1) : "0") + "e" + e;
    const p = e + 1;
    const f = g + ((p <= 0) ? "0." + "0".repeat(-p) + d : (p >= d.length) ? d + "0".repeat(p - d.length) + ".0" : d.slice(0, p) + "." + d.slice(p));
    return ((f.length <= x.length) && (Math.abs(v) < 9007199254740992)) ? f : x;
}

function __bp_case_map(t) {
    const m = new Map();
    for (const e of t.split(" ")) {
        const p = e.replace("!", "").split(",").map((x) => parseInt(x, 36));
        if (e[0] === "!") { m.set(p[0], String.fromCodePoint(...p.slice(1))); continue; }
        for (let i = 0; i < p[1]; i += 1) m.set(p[0] + i * p[2], String.fromCodePoint(p[0] + i * p[2] + p[3]));
    }
    return m;
}

function __bp_case(s, m) {
    let o = "";
    for (const c of s) {
        const r = m.get(c.codePointAt(0));
        o += (r === undefined) ? c : r;
    }
    return o;
}

function __bp_lower(s) {
    return __bp_case(s, __bp_lower.m ??= __bp_case_map("1t,q,1,w 5c,n,1,w 60,7,1,w 74,o,2,1 8i,3,2,1 8p,8,2,1 96,n,2,1 ag,1,2,-3d ah,3,2,1 ap,1,2,5u aq,2,2,1 au,1,2,5q av,1,2,1 ax,2,1,5p az,1,2,1 b2,1,2,27 b3,1,2,5m b4,1,2,5n b5,1,2,1 b7,1,2,5p b8,1,2,5r ba,1,2,5v bb,1,2,5t bc,1,2,1 bg,1,2,5v bh,1,2,5x bj,1,2,5y bk,3,2,1 bq,1,2,62 br,1,2,1 bt,1,2,62 bw,1,2,1 by,1,2,62 bz,1,2,1 c1,2,1,61 c3,2,2,1 c7,1,2,63 c8,1,2,1 cc,1,2,1 ck,1,2,2 cl,1,2,1 cn,1,2,2 co,1,2,1 cq,1,2,2 cr,9,2,1 da,9,2,1 dt,1,2,2 du,2,2,1 dy,1,2,-2p dz,1,2,-1k e0,k,2,1 f4,1,2,-3m f6,9,2,1 fu,1,2,8bv fv,1,2,1 fx,1,2,-4j fy,1,2,8bs g1,1,2,1 g3,1,2,-5f g4,1,2,1x g5,1,2,1z g6,5,2,1 og,2,2,1 om,1,2,1 ov,1,2,38 p2,1,2,12 p4,3,1,11 p8,1,2,1s pa,2,1,1r pd,h,1,w pv,9,1,w r3,1,2,8 rc,c,2,1 s4,1,2,-1o s7,1,2,1 s9,1,2,-7 sa,1,2,1 sd,3,1,-3m sg,g,1,28 sw,w,1,w v4,h,2,1 wa,r,2,1 xs,1,2,f xt,7,2,1 y8,1c,2,1 10x,12,1,1c 3a8,12,1,5ls 3bb,1,2,5ls 3bh,1,2,5ls 3vk,28,1,tzk 3xs,6,1,8 5mx,1,2,1 5n4,17,1,-2bk 5od,3,1,-2bk 5xc,23,2,1 61q,1,2,-5vj 61s,1c,2,1 64o,8,1,-8 654,6,1,-8 65k,8,1,-8 660,8,1,-8 66g,6,1,-8 66x,4,2,-8 67c,8,1,-8 688,8,1,-8 68o,8,1,-8 694,8,1,-8 69k,2,1,-8 69m,2,1,-22 69o,1,2,-9 6a0,4,1,-2e 6a4,1,2,-9 6ag,2,1,-8 6ai,2,1,-2s 6aw,2,1,-8 6ay,2,1,-34 6b0,1,2,-7 6bc,2,1,-3k 6be,2,1,-3i 6bg,1,2,-9 6jq,1,2,-5st 6ju,1,2,-6gv 6jv,1,2,-6di 6k2,1,2,s 6lc,g,1,g 6mb,1,2,1 792,q,1,q 8ow,1c,1,1c 8rk,1,2,1 8rm,1,2,-8af 8rn,1,2,-2xy 8ro,1,2,-89z 8rr,3,2,1 8rx,1,2,-8bg 8ry,1,2,-8al 8rz,1,2,-8bj 8s0,1,2,-8bi 8s2,1,2,1 8s5,1,2,1 8se,2,1,-8cf 8sg,1e,2,1 8vf,2,2,1 8vm,1,2,1 wu8,n,2,1 ww0,e,2,1 x0i,7,2,1 x0y,v,2,1 x2x,2,2,1 x31,1,2,-r9g x32,5,2,1 x3f,1,2,1 x3h,1,2,-wmg x3k,2,2,1 x3q,a,2,1 x4a,1,2,-wn8 x4b,1,2,-wnj x4c,1,2,-wnf x4d,1,2,-wn5 x4e,1,2,-wn8 x4g,1,2,-wlu x4h,1,2,-wmi x4i,1,2,-wlx x4j,1,2,ps x4k,8,2,1 x50,1,2,-1c x51,1,2,-wn7 x52,1,2,-raw x53,2,2,1 x57,1,2,-wo7 x58,8,2,1 x5o,1,2,-wu9 x6d,1,2,1 1ee9,q,1,w 1fcw,14,1,14 1fhs,10,1,14 1fn4,b,1,13 1fng,f,1,13 1fnw,7,1,13 1fo4,2,1,13 1h1c,1f,1,1s 1h74,m,1,w 1jfk,w,1,w 20cg,w,1,w 20f4,p,1,r 2olc,y,1,y !8g,2x,lj"));
}

function __bp_show(v, s, top, a) {
    if ((typeof v === "string")) {
        a.push(top ? v : (("\"" + Array.from(v, (c) => ((c === "\"") || (c === "\\")) ? ("\\" + c) : (c === "\n") ? "\\n" : (c === "\r") ? "\\r" : (c === "\t") ? "\\t" : c).join("")) + "\""));
        return "%s";
    }
    if ((typeof v === "bigint")) {
        a.push(String(v));
        return "%s";
    }
    if (((typeof v === "number") && (s === "f"))) {
        a.push(__bp_f64(v));
        return "%s";
    }
    if (Array.isArray(v)) {
        const t = ((s != null) && (s[0] === "#"));
        return (((t ? "#(" : "[") + v.map((e, i) => __bp_show(e, (s == null) ? null : t ? s[i + 1] : s[1], false, a)).join(", ")) + (t ? ")" : "]"));
    }
    if ((((typeof v === "object") && (v != null)) && (typeof v.__bp !== "string"))) {
        const k = Object.keys(v);
        if (((k.length === 1) && ((k[0] === "ok") || (k[0] === "error")))) {
            return ((((k[0] === "ok") ? "Ok(" : "Error(") + __bp_show(v[k[0]], null, false, a)) + ")");
        }
    }
    if (((v != null) && (typeof v.__bp === "string"))) {
        if ((typeof v.display === "function")) {
            a.push(v.display());
            return "%s";
        }
        const k = Object.keys(v);
        return (((typeof Object.getPrototypeOf(v).tag === "string") ? ((v.__bp + ".") + Object.getPrototypeOf(v).tag) : v.__bp) + ((k.length === 0) ? "" : (("(" + k.map((n) => ((n + ": ") + __bp_show(v[n], v.__bp_s?.[n], false, a))).join(", ")) + ")")));
    }
    if ((v === undefined)) return "null";
    a.push(v);
    return "%O";
}

function __bp_text(v, s) {
    const a = [];
    let i = 0;
    return __bp_show(v, s == null ? null : s, true, a).replace(/%[sO]/g, () => String(a[i++]));
}

function __bp_host_fail(F, e) {
    const n = e instanceof Error;
    return { error: new F.HostError(n ? e.message : String(e), "host", n ? F.HostErrorName.Error : F.HostErrorName.Throw, (n && typeof e.stack === "string") ? e.stack : null) };
}

function __bp_task(p) {
    const t = p.then((r) => { if (r != null && "error" in r) { t.__bp_failure = true; throw r.error; } return (r == null) ? r : r.ok; });
    t.__bp_fails = true;
    t.catch(() => {});
    return t;
}

function __bp_await(t) {
    return (t != null && t.__bp_fails === true) ? t.then((v) => ({ ok: v }), (e) => { if (t.__bp_failure === true) { return { error: e }; } throw e; }) : t;
}

function __bp_host_result_task(F, f) {
    return __bp_task(new Promise((r) => r(f())).then((v) => ({ ok: v }), (e) => __bp_host_fail(F, e)));
}

// behavior bytes
//   fn fromUtf8(...)
//   fn toUtf8(...)
//   fn length(...)
//   fn concat(...)
//   default fn slice(...)
Uint8Array.prototype.toUtf8 = function() { return ((__b) => require('buffer').isUtf8(__b) ? { ok: new TextDecoder("utf-8", { ignoreBOM: true }).decode(__b) } : { error: "bytes.toUtf8: not valid UTF-8" })(this); };
Uint8Array.prototype.concat = function(other) { return ((__a, __b) => { const __r = new Uint8Array(__a.length + __b.length); __r.set(__a, 0); __r.set(__b, __a.length); return __r; })(this, other); };
Uint8Array.prototype.slice = function(start, end) {
    if ((end != null)) { return ((__b, __a, __e) => { if (__a == null) __a = 0; const __n = __b.length; const __s = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return new Uint8Array(__b.subarray(__s, Math.max(__s, __f))); })(this, start, end); } else { return ((__b, __a) => { if (__a == null) __a = 0; const __n = __b.length; const __s = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return new Uint8Array(__b.subarray(__s, __n)); })(this, start); }
};

//// std/io/http — minimal HTTP client primitives (cross-backend).

//// 

//// Reference:

////   Node.js  — https://nodejs.org/api/globals.html#fetch

////              (the global `fetch` since Node 18; `Response.text()`

////               reads the body as a UTF-8 string).

////   Erlang   — https://www.erlang.org/doc/man/httpc.html

////              (`httpc:request/4`; requires `inets:start()` and,

////               for https URLs, `ssl:start()`).

//// 

//// `fetch(req: Request) -> Async<Result<Response, HttpError>>` is the one

//// surface (decision 623; `fetch(url)` is gone): `Request(method, url,

//// headers = [], body = null)` — a short GET is

//// `fetch(Request(method: .Get, url: u))` — and a failure is a variant of

//// `HttpError` (`NotAllowedOnHost`, `Network(message)`, `Timeout`), matched

//// by variant. Decision 432: the task that fails with the error — `await`

//// answers the `Result`, so the caller writes `try await http.fetch(req)`

//// to propagate it. It maps the host binding `fetchHost` (`result: true`,

//// decisions 431, 490) to the `HttpError` of its `HostError` (decision 486):

//// the node template's rejected `fetch` is `Error(HostError(…))` and a

//// fulfilled one `Ok({ status, body })`; the erlang template ensures

//// `inets`/`ssl` are started (`application:ensure_all_started/1`,

//// idempotent) and lowers to a synchronous `httpc:request/4`, whose

//// `{error, R}` becomes `Error(HostError(<R formatted>, …))`. A host text

//// that names a timeout is `Timeout`, any other is `Network(message)`;

//// `NotAllowedOnHost` is what a host that does not allow the request answers

//// (the wasm `wasi:http` adapter, decisions 334, 393). Erlang is eager:

//// `Async<T>` is `T` there, so the caller's `await` is identity on that

//// backend. An HTTP error status (404, 500) is a RESPONSE, not a failure: it

//// is `Ok` with its `status`.

//// 

//// Out of scope: streaming responses.

//// 

//// BEAM and wasm targets are out of scope here: `wat3` has no host fetch

//// surface; BEAM follows the erlang template once an `httpc`-equivalent

//// shim is ported. Either backend's caller will fail with a missing-

//// external diagnostic at codegen time, matching the spec wave's

//// scope.

const { HostError } = require("../../std/failure.js");

class Response {
    constructor(status, body) {
        this.status = status;
        this.body = body;
    }
}
Response.prototype.__bp = "Response";
exports.Response = Response;

class Header {
    constructor(name, value) {
        this.name = name;
        this.value = value;
    }
}
Header.prototype.__bp = "Header";
exports.Header = Header;

// The request method; `.Get` is the short GET.

class Method {
    static verb(self) {
        return (() => {
            const _s = self;
            if (_s.tag === "Get") return "GET";
            if (_s.tag === "Post") return "POST";
            if (_s.tag === "Put") return "PUT";
            if (_s.tag === "Delete") return "DELETE";
            if (_s.tag === "Patch") return "PATCH";
            if (_s.tag === "Head") return "HEAD";
            if (_s.tag === "Options") return "OPTIONS";
            throw new Error("case_clause");
        })();
    }

    toString() {
        return __bp_text(this);
    }
}
Method.prototype.__bp = "Method";
class Method$Get extends Method {
}
Method$Get.prototype.tag = "Get";
class Method$Post extends Method {
}
Method$Post.prototype.tag = "Post";
class Method$Put extends Method {
}
Method$Put.prototype.tag = "Put";
class Method$Delete extends Method {
}
Method$Delete.prototype.tag = "Delete";
class Method$Patch extends Method {
}
Method$Patch.prototype.tag = "Patch";
class Method$Head extends Method {
}
Method$Head.prototype.tag = "Head";
class Method$Options extends Method {
}
Method$Options.prototype.tag = "Options";
Method.Get = new Method$Get();
Method.Post = new Method$Post();
Method.Put = new Method$Put();
Method.Delete = new Method$Delete();
Method.Patch = new Method$Patch();
Method.Head = new Method$Head();
Method.Options = new Method$Options();
exports.Method = Method;

// What `fetch` sends (decision 623). A `body` rides `Post`, `Put` and `Patch`.

class Request {
    constructor(method, url, headers, body) {
        this.method = method;
        this.url = url;
        this.headers = headers;
        this.body = body;
    }
}
Request.prototype.__bp = "Request";
exports.Request = Request;

// Every way a `fetch` fails (decision 623).

class HttpError {
    static Network(message) {
        return new HttpError$Network(message);
    }

    toString() {
        return __bp_text(this);
    }
}
HttpError.prototype.__bp = "HttpError";
class HttpError$NotAllowedOnHost extends HttpError {
}
HttpError$NotAllowedOnHost.prototype.tag = "NotAllowedOnHost";
class HttpError$Network extends HttpError {
    constructor(message) {
        super();
        this.message = message;
    }

    get $0() {
        return this.message;
    }
}
HttpError$Network.prototype.tag = "Network";
class HttpError$Timeout extends HttpError {
}
HttpError$Timeout.prototype.tag = "Timeout";
HttpError.NotAllowedOnHost = new HttpError$NotAllowedOnHost();
HttpError.Timeout = new HttpError$Timeout();
exports.HttpError = HttpError;

// The request as the host takes it, under `result: true` (decisions 431, 490):

// the response, or every way the host fails as `Error(HostError(…))`. The

// headers cross as two lists, names and values in the same order; `hasBody`

// says whether `body` is sent.

// 

// Node: `globalThis.fetch(url, { method, headers, body })` chained with

// `.text()` flattens the `Response → Promise<text>` shape into one

// `{ status, body }`; a rejection anywhere in the chain is

// `Error(HostError(<message>, …))` (`codegen/commonJS.zig` `wrapResult`).

// `fetch` takes no body on `GET` / `HEAD`.

// 

// Erlang: idempotently start `inets` + `ssl` (`application:ensure_all_started/1`,

// so a second `fetch` call doesn't bomb on `{already_started, _}`), then call

// `httpc:request/4`; a body rides `post` / `put` / `patch` with the request's

// `content-type` header (else `application/octet-stream`).

// The OK arm answers `{ok, #{status => Code, body => Body}}`; the error arm

// `{error, Reason}`, whose message is the reason formatted (decision 490).

function fetchHost(method, url, names, values, hasBody, body) { return __bp_host_result_task(require("../../std/failure.js"), () => ((__m, __u, __n, __v, __hb, __b) => globalThis.fetch(__u, { method: __m, headers: Object.fromEntries(__n.map((__k, __i) => [__k, __v[__i]])), body: (__hb && __m !== "GET" && __m !== "HEAD") ? __b : undefined }).then(__r => __r.text().then(__t => ({ status: __r.status, body: __t }))))(method, url, names, values, hasBody, body)); }

// A host text that names a timeout is `Timeout`, any other `Network`.

function hostFailure(e) {
    const text = __bp_lower(e.message);
    if ((text.includes("timeout") || text.includes("timed out"))) { return HttpError.Timeout; } else { return HttpError.Network(e.message); }
}

// Issue the request and resolve with the response, or fail with the

// `HttpError` (`await` answers `Error(httpError)`, decision 432):

// `fetchHost`'s `HostError` mapped to a variant (decision 486).

function fetch(req) {
    return __bp_task((async () => {
        const names = req.headers.map((h) => {
    return h.name;
});
        const values = req.headers.map((h) => {
    return h.value;
});
        const r = await __bp_await(fetchHost(Method.verb(req.method), req.url, names, values, (req.body != null), (() => { const __bp_nullish = req.body; if (__bp_nullish != null) { return __bp_nullish; } else { return (new TextEncoder().encode("")); } })()));
        {
            const _s = r;
            if ("ok" in _s) {
                const resp = _s.ok;
                return ({ ok: resp });
            }
            if ("error" in _s) {
                const e = _s.error;
                return ({ error: hostFailure(e) });
            }
            throw new Error("case_clause");
        }
    })());
}
exports.fetch = fetch;

// ── tests ────────────────────────────────────────────────────────────────────

// No inline runtime tests: `fetch` needs network access, which the

// per-backend lib-test runners do not provide. The surface is exercised

// indirectly through the parser §A3 + infer §A3 acceptance gates

// (`modules/compiler-core/src/parser/tests/effect_rejections.zig`)

// which pin `declare fn` with `#[external(.<Target>(…))]` as accepted.

// 

// A compile-only smoke fixture lives below to ensure callers can

// `try await fetch(req)` from a `-> Async<Result<…>>` body without the type

// checker tripping on the eager `Response` payload. The body is not executed

// at test time (its `await` would issue a network call), but the fixture

// type-checks at compile time.

function fetchStatus(url) {
    return __bp_task((async () => {
        const _try0 = await __bp_await(fetch(new Request(Method.Get, url, [], null)));
        if ("error" in _try0) return _try0;
        const resp = _try0.ok;
        return ({ ok: resp.status });
    })());
}
exports.fetchStatus = fetchStatus;

Object.defineProperty(exports, "__bp_priv__", { value: { HostError, Response, Header, Method, Method$Get, Method$Post, Method$Put, Method$Delete, Method$Patch, Method$Head, Method$Options, Request, HttpError, HttpError$NotAllowedOnHost, HttpError$Network, HttpError$Timeout, fetchHost, hostFailure, fetch, fetchStatus } });
