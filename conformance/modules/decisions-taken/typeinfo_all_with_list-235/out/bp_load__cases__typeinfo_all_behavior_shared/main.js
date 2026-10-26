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

class DeclaredMeta {
    constructor(key, value) {
        this.key = key;
        this.value = value;
    }
}
DeclaredMeta.prototype.__bp = "DeclaredMeta";

class DeclaredTypedMeta {
    constructor(key, value) {
        this.key = key;
        this.value = value;
    }
}
DeclaredTypedMeta.prototype.__bp = "DeclaredTypedMeta";

class Declared {
    constructor(name, module, meta, returnTypeName, value, typedMeta) {
        this.name = name;
        this.module = module;
        this.meta = meta;
        this.returnTypeName = returnTypeName;
        this.value = value;
        this.typedMeta = typedMeta;
    }
}
Declared.prototype.__bp = "Declared";

//// Decision 564 — a query over several decorators answers the behavior they

//// share: `#[service]` and `#[repository]` both name `Bean`, so

//// `@TypeInfo.all(with: [service, repository])` answers

//// `Declared<Bean>[]`, in the one order (decision 235).

// behavior Bean
//   fn make(...)

class Mailer {
    constructor(host) {
        this.host = host;
    }

    static make() {
        return new Mailer("smtp");
    }
}
Mailer.prototype.__bp = "Mailer";
Mailer.prototype["__bp_b_bp_load_cases_typeinfo_all_behavior_shared@main@@Bean"] = true;
exports.Mailer = Mailer;

class Orders {
    constructor(table) {
        this.table = table;
    }

    static make() {
        return new Orders("orders");
    }
}
Orders.prototype.__bp = "Orders";
Orders.prototype["__bp_b_bp_load_cases_typeinfo_all_behavior_shared@main@@Bean"] = true;
exports.Orders = Orders;

function main() {
    const all = [new Declared("Mailer", "bp_load__cases__typeinfo_all_behavior_shared/main", [], "", null, [new DeclaredTypedMeta("bp_load__cases__typeinfo_all_behavior_shared@main@@BeanRole", () => {
    return new BeanRole("service");
})]), new Declared("Orders", "bp_load__cases__typeinfo_all_behavior_shared/main", [], "", null, [new DeclaredTypedMeta("bp_load__cases__typeinfo_all_behavior_shared@main@@BeanRole", () => {
    return new BeanRole("repository");
})])];
    for (const d of all) {
    __bp_print(((d.name + " ") + declared__metaAll__BeanRole(d.typedMeta, "bp_load__cases__typeinfo_all_behavior_shared@main@@BeanRole").map((m) => {
    return m.role;
}).join(",")));
}
}
exports.main = main;

// What `#[service]` and `#[repository]` record: the bean's role.

class BeanRole {
    constructor(role) {
        this.role = role;
    }
}
BeanRole.prototype.__bp = "BeanRole";
exports.BeanRole = BeanRole;

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
    return "cases/typeinfo_all_behavior_shared|*";
}
exports.__bp_loaded_info = __bp_loaded_info;

function declared__metaAll__BeanRole(slots, key) {
    let out = [];
    for (const s of slots) {
    (() => { if ((s.key === key)) { const f = s.value; return (() => { if (((_v) => (typeof _v === "function" && _v.length === 0))(f)) { return out.push(f()); } })(); } })();
}
    return out;
}

function _botopink_main() {
    main();
}
if (require.main === module) {
    const __bp_abort = (e) => { const k = (e != null && e.__bp_panic != null) ? ["panic", (typeof e.__bp_panic === "string") ? e.__bp_panic : e.message] : (e != null && typeof e.__bp_assert_loc === "string") ? ["panic", e.message] : [(e != null && e.__bp_host === true) ? "host" : "crash", (e instanceof Error) ? e.message : String(e)]; globalThis.process.stderr.write(k[0] + ": " + k[1] + "\n", () => globalThis.process.exit(1)); };
    globalThis.process.on("uncaughtException", __bp_abort);
    globalThis.process.on("unhandledRejection", __bp_abort);
    _botopink_main();
}

Object.defineProperty(exports, "__bp_priv__", { value: { DeclaredMeta, DeclaredTypedMeta, Declared, Mailer, Orders, main, BeanRole, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info, declared__metaAll__BeanRole } });
