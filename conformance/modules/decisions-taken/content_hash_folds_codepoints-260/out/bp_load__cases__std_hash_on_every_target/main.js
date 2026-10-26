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

//// `std/hash` on all four targets (decision 238, `01-compiler/05-wasm` step

//// 5): on wasm every cell is bound with `fn:` to a private body in exact

//// arithmetic, answering what Node's `crypto` answers — the digests, the MACs,

//// PBKDF2, the constant-time compare and the content hashes in one program,

//// since the wasm heap grows (decision 261). `contentHash` folds code points

//// on every target (decision 260): a character above U+FFFF is one code point.

const hash = require("../std/hash.js");

function main() {
    __bp_print(hash.sha256("abc"));
    __bp_print(hash.sha512("abc"));
    __bp_print(hash.md5("héllo €"));
    __bp_print(hash.sha1Base64("dGhlIHNhbXBsZSBub25jZQ==258EAFA5-E914-47DA-95CA-C5AB0DC85B11"));
    __bp_print(hash.sha256Base64Url("hello world"));
    __bp_print(hash.strongHash(""));
    __bp_print(hash.hmacSha256("key", "The quick brown fox jumps over the lazy dog"));
    __bp_print(hash.hmacSha256Base64Url("secret", "header.payload"));
    __bp_print(hash.pbkdf2Sha256("pässwörd", "salt", 2, 40));
    __bp_print(hash.pbkdf2Sha256("password", "salt", 9, 32));
    __bp_print(hash.equalsConstantTime("abcd", "abcd"));
    __bp_print(hash.equalsConstantTime("abcd", "abce"));
    __bp_print(hash.equalsConstantTime("abc", "abcd"));
    __bp_print(hash.contentHash("héllo €"));
    __bp_print(hash.contentHash("🎉"));
    __bp_print(hash.contentHash("a🎉b"));
    __bp_print(hash.cacheKey(["user:1", "profile"]));
    __bp_print(hash.strongCacheKey(["user", "1:profile"]));
    __bp_print(hash.etag("<p>hi</p>"));
    __bp_print(hash.weakEtag("<p>hi</p>"));
    __bp_print(hash.matches("<p>hi</p>", "*"));
    __bp_print(hash.fingerprint("app.js", "body{}"));
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
    return "cases/std_hash_on_every_target|*";
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

Object.defineProperty(exports, "__bp_priv__", { value: { hash, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
