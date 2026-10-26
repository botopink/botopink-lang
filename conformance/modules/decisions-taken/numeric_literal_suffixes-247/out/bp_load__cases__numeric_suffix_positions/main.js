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

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

function __bp_wnorm(v, u, what) {
    if (u ? (v < 0n || v > 18446744073709551615n) : (v < -9223372036854775808n || v > 9223372036854775807n)) { throw Object.defineProperty(new Error("integer overflow: " + what), "__bp_panic", { value: true }); }
    return (v >= -9007199254740991n && v <= 9007199254740991n) ? Number(v) : v;
}

function __bp_wadd(a, b, u, what) {
    if (typeof a === "number" && typeof b === "number") { const r = a + b + 0; if (Number.isSafeInteger(r) && (r >= 0 || !u)) { return r; } }
    return __bp_wnorm(BigInt(a) + BigInt(b), u, what);
}

function __bp_wmul(a, b, u, what) {
    if (typeof a === "number" && typeof b === "number") { const r = a * b + 0; if (Number.isSafeInteger(r) && (r >= 0 || !u)) { return r; } }
    return __bp_wnorm(BigInt(a) * BigInt(b), u, what);
}

//// Decision 247 — a suffixed literal is the same literal wherever it stands:

//// in a `case` guard, in a `case` arm body, in a parameter's default, in a

//// default made of an expression and inside a lambda. The suffix is the

//// checker's and never reaches a backend (`1577836800000l` in a guard was a

//// `SyntaxError` in JS and an `erlc` syntax error on Erlang and BEAM). The

//// same holds in a method's parameter default (`type`, associated, `implement`,

//// a `behavior` default fn, a `type` variant's method), a record field default

//// and a `case` guard inside a method body.

class Stamp {
    constructor(mtime) {
        this.mtime = mtime;
    }
}
Stamp.prototype.__bp = "Stamp";

function stat(n) {
    if ((n < 0)) { return ({ error: "negative" }); }
    return ({ ok: new Stamp(n) });
}

function offset(v) {
    return v;
}

function sum(v) {
    return v;
}

function narrow(v) {
    return v;
}

class Box {
    constructor(label, size) {
        this.label = label;
        this.size = size;
    }

    grow(by) {
        return __bp_wadd(this.size, by, 0, "+ on i64 at src/main.bp:33:26");
    }

    static make(base) {
        return base;
    }
}
Box.prototype.__bp = "Box";

// behavior Scale
//   fn by(...)
const Scale = {};
Scale.by = function(x, factor) {
    return __bp_wmul(x, factor, 0, "* on i64 at src/main.bp:43:18");
};

// behavior Tag
//   fn tag(...)

class Item {
    constructor(id) {
        this.id = id;
    }

    tag(n) {
        return __bp_wadd(this.id, n, 0, "+ on i64 at src/main.bp:53:24");
    }
}
Item.prototype.__bp = "Item";
Item.prototype["__bp_b_bp_load_cases_numeric_suffix_positions@main@@Tag"] = true;

class Pick {
    constructor(n) {
        this.n = n;
    }

    band() {
        const _case0 = (() => {
            const _s = this.n;
            {
                const v = _s;
                if ((v > 5)) return ({ __bp_return: true, value: "high" });
            }
            return ({ __bp_return: true, value: "low" });
        })();
        if (_case0 && _case0.__bp_return) return _case0.value;
    }
}
Pick.prototype.__bp = "Pick";

class Level {
    static weight(self, k) {
        return k;
    }

    toString() {
        return __bp_text(this);
    }
}
Level.prototype.__bp = "Level";
class Level$Low extends Level {
}
Level$Low.prototype.tag = "Low";
class Level$High extends Level {
}
Level$High.prototype.tag = "High";
Level.Low = new Level$Low();
Level.High = new Level$High();

function main() {
    const stamp = stat(1577836900000);
    (() => {
        const _s = stamp;
        if ("ok" in _s) {
            const s = _s.ok;
            if ((s.mtime > 1577836800000)) return __bp_print("after");
        }
        if ("ok" in _s) {
            return __bp_print("before");
        }
        if ("error" in _s) {
            const e = _s.error;
            return __bp_print(e);
        }
        throw new Error("case_clause");
    })();
    (() => {
        const _s = 3;
        {
            const n = _s;
            if ((n > 2)) return __bp_print("big");
        }
        return __bp_print("small");
    })();
    (() => {
        const _s = 2;
        {
            const n = _s;
            if (((n === 2) && (n < 9))) return __bp_print("two");
        }
        return __bp_print("other");
    })();
    const grown = (() => {
        const _s = 1;
        if (_s === 1) return __bp_wadd(10, 1, 0, "+ on i64 at src/main.bp:91:19");
        return 0;
    })();
    __bp_print(grown);
    __bp_print(offset(7));
    __bp_print(sum((2 + 3)));
    __bp_print(narrow(9));
    __bp_print([1, 2].map((v) => {
    return __bp_wadd(v, 5, 0, "+ on i64 at src/main.bp:98:33");
}));
    const box = new Box("b", 4);
    __bp_print(box.size);
    __bp_print(box.grow(6));
    __bp_print(Box.make(8));
    __bp_print(Scale.by(2, 10));
    __bp_print(new Item(1).tag(3));
    __bp_print(new Pick(9).band());
    __bp_print(Level.weight(Level.Low, 5));
    __bp_print(("sum=" + __bp_wadd(3, 4, 0, "+ on i64 at src/main.bp:107:21")));
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
    return "cases/numeric_suffix_positions|*";
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

Object.defineProperty(exports, "__bp_priv__", { value: { Stamp, stat, offset, sum, narrow, Box, Scale, Item, Pick, Level, Level$Low, Level$High, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
