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

function __bp_text(v, s) {
    const a = [];
    let i = 0;
    return __bp_show(v, s == null ? null : s, true, a).replace(/%[sO]/g, () => String(a[i++]));
}

//// The `.new` of a run (decision 989 (6)): `snapshot/main.snap.new` holds the module's whole

//// candidate file. The program never accepts a candidate — it never writes `snapshot/main.snap`

//// (decision 67).

const { writeText } = require("../std/io/fs.js");

const { diff } = require("../conformance-lib/records.js");

const { SnapFile, parseFile, renderFile, HEADER } = require("../conformance-lib/sections.js");

const { Observed, assemble, reds } = require("../conformance-lib/observe.js");

/** Where the candidate goes, beside the accepted file. */

const CANDIDATE_PATH = "snapshot/main.snap.new";

exports.CANDIDATE_PATH = CANDIDATE_PATH;

/** The accepted file's path. */

const ACCEPTED_PATH = "snapshot/main.snap";

exports.ACCEPTED_PATH = ACCEPTED_PATH;

/** `text` written to the file at `path`, through `io.fs` on every target (decision 992: wasm's */

/** `io.fs` is the other targets'). `Error` when the file cannot be written. */

function deliver(path, text) {
    try {
        const written = (() => { const _try0 = writeText(path, text); if ("error" in _try0) { const e = _try0.error; return ((() => {
        const _s = true;
        {
            throw ({ __bp_try: ({ error: (("cannot write " + path) + (": " + __bp_text(e))) }) });
        }
    })()); } return _try0.ok; })();
        return ({ ok: null });
    } catch (__e) {
        if (__e !== null && typeof __e === "object" && "__bp_try" in __e) { return __e.__bp_try; }
        throw __e;
    }
}
exports.deliver = deliver;

/** The whole check of a module: its observed answers against the accepted file's text. `Ok` when */

/** every case is green; else the candidate is delivered (a candidate when the text differs) and the */

/** `Error` names the red cases and the candidate. */

function finish(accepted, observed, target) {
    try {
        const file = (() => { const _try0 = parseFile(accepted); if ("error" in _try0) { const m = _try0.error; return ((() => {
        const _s = true;
        {
            throw ({ __bp_try: ({ error: ((("snapshot/main.snap line " + m.line.toString()) + ": ") + m.reason) }) });
        }
    })()); } return _try0.ok; })();
        const red = reds(file, observed, target);
        const text = assemble(file, observed, target);
        if (((red.length === 0) && __bp_eq(text, renderFile(file), 0))) { return ({ ok: null }); }
        // The verdict names the red cases whether or not the candidate could be written.;
        const written = (() => {
                const _s = deliver(CANDIDATE_PATH, text);
                if ("ok" in _s) {
                    return "";
                }
                if ("error" in _s) {
                    const m = _s.error;
                    return ("\n" + m);
                }
                throw new Error("case_clause");
            })();
        return ({ error: (((((((red.length.toString() + " red on ") + target) + ": ") + red.join(", ")) + "\n") + diff(renderFile(file), text)) + written) });
    } catch (__e) {
        if (__e !== null && typeof __e === "object" && "__bp_try" in __e) { return __e.__bp_try; }
        throw __e;
    }
}
exports.finish = finish;

Object.defineProperty(exports, "__bp_priv__", { value: { writeText, diff, SnapFile, parseFile, renderFile, HEADER, Observed, assemble, reds, CANDIDATE_PATH, ACCEPTED_PATH, deliver, finish } });
