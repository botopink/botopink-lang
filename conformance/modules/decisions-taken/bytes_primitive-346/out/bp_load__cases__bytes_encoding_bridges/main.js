function __bp_eq(a, b, d) {
    if (Object.is(a, b)) {
        return true;
    }
    if ((((((d > 32) || (a === null)) || (b === null)) || (typeof a !== "object")) || (a.constructor !== b.constructor))) {
        return false;
    }
    if (Array.isArray(a)) {
        return ((a.length === b.length) && a.every((e, i) => __bp_eq(e, b[i], (d + 1))));
    }
    const k = Object.keys(a);
    return ((k.length === Object.keys(b).length) && k.every((n) => __bp_eq(a[n], b[n], (d + 1))));
}

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

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
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

//// Decision 346 — `encoding`'s `Bytes` bridges: base64 and hex over bytes, lossless where the

//// text codecs read the bytes back as UTF-8. A decoder answers `Result<Bytes, EncodingError>` with

//// the text codecs' rules and `Error` variants (decision 486). The parent binary knew no `Bytes`.

const encoding = require("../std/encoding.js");
const { EncodingError } = require("../std/encoding.js");

function show(r) {
    return (() => {
        const _s = r;
        if ("ok" in _s) {
            const b = _s.ok;
            return ("bytes " + encoding.hexEncodeBytes(b));
        }
        if ("error" in _s) {
            const e = _s.error;
            return ("error " + errorName(e));
        }
        throw new Error("case_clause");
    })();
}

function errorName(e) {
    return (() => {
        const _s = e;
        if (_s.tag === "NotBase64") return "NotBase64";
        if (_s.tag === "NotHex") return "NotHex";
        if (_s.tag === "NotPercentEncoded") return "NotPercentEncoded";
        throw new Error("case_clause");
    })();
}

function main() {
    const hi = (new TextEncoder().encode("hi"));
    __bp_print(encoding.base64EncodeBytes(hi));
    __bp_print(encoding.hexEncodeBytes(hi));
    const raw = ((_r) => "error" in _r ? (hi) : _r.ok)(encoding.hexDecodeBytes("00ff80c3"));
    __bp_print(raw.length);
    __bp_print(encoding.base64EncodeBytes(raw));
    __bp_print(show(encoding.base64DecodeBytes("AP+Aww==")));
    __bp_print(show(encoding.base64DecodeBytes("AP+Aww")));
    __bp_print(show(encoding.base64DecodeBytes("aGk")));
    __bp_print(show(encoding.base64DecodeBytes("aGl")));
    __bp_print(show(encoding.base64DecodeBytes("a*b=")));
    __bp_print(show(encoding.base64DecodeBytes("")));
    __bp_print(show(encoding.hexDecodeBytes("00FFab")));
    __bp_print(show(encoding.hexDecodeBytes("abc")));
    __bp_print(show(encoding.hexDecodeBytes("zz")));
    __bp_print(__bp_eq(((_r) => "error" in _r ? (hi) : _r.ok)(encoding.base64DecodeBytes(encoding.base64EncodeBytes(raw))), raw, 0));
    __bp_print(__bp_eq(encoding.base64Encode("hi"), encoding.base64EncodeBytes(hi), 0));
}
exports.main = main;

function __bp_loaded_main() {
    main();
    return ({ ok: null });
}
exports.__bp_loaded_main = __bp_loaded_main;

function __bp_loaded_main_off() {
    return ({ error: "" });
}
exports.__bp_loaded_main_off = __bp_loaded_main_off;

function __bp_loaded_info() {
    return "cases/bytes_encoding_bridges|*";
}
exports.__bp_loaded_info = __bp_loaded_info;

function _botopink_main() {
    main();
}
if (require.main === module) {
    const __bp_abort = (e) => { const k = (e != null && e.__bp_panic != null) ? ["panic", (typeof e.__bp_panic === "string") ? e.__bp_panic : e.message] : (e != null && typeof e.__bp_assert_loc === "string") ? ["panic", e.message] : [(e != null && e.__bp_host === true) ? "host" : "crash", (e instanceof Error) ? e.message : String(e)]; globalThis.process.stderr.write(k[0] + ": " + k[1] + "\n", () => globalThis.process.exit(1)); };
    globalThis.process.on("uncaughtException", __bp_abort);
    globalThis.process.on("unhandledRejection", __bp_abort);
    _botopink_main();
}

Object.defineProperty(exports, "__bp_priv__", { value: { encoding, EncodingError, show, errorName, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
