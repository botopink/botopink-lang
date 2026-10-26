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

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

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

//// Decision 235 — `@TypeInfo.all(with: [a, b])` answers every declaration

//// carrying any decorator of the list, in the one order (module path, then

//// declaration order), a declaration carrying two of them once, with the

//// meta every listed decorator set. Each `value` is `unknown` (decision 254);

//// calling it through `is fn() -> T` is front 130's. A type's entry has no

//// return type: `returnTypeName` is `""` (decision 256).

class Mailer {
    constructor(host) {
        this.host = host;
    }

    static make() {
        return "Mailer";
    }
}
Mailer.prototype.__bp = "Mailer";

class Orders {
    constructor(table) {
        this.table = table;
    }

    static make() {
        return "Orders";
    }
}
Orders.prototype.__bp = "Orders";

class Billing {
    constructor(rate) {
        this.rate = rate;
    }

    static make() {
        return "Billing";
    }
}
Billing.prototype.__bp = "Billing";

function main() {
    for (const d of [new Declared("Mailer", "bp_load__cases__typeinfo_all_list/main", [], "", () => {
    return Mailer.make();
}, [new DeclaredTypedMeta("bp_load__cases__typeinfo_all_list@main@@Service", () => {
    return new Service("service");
})]), new Declared("Orders", "bp_load__cases__typeinfo_all_list/main", [], "", () => {
    return Orders.make();
}, [new DeclaredTypedMeta("bp_load__cases__typeinfo_all_list@main@@Store", () => {
    return new Store("sql");
})]), new Declared("Billing", "bp_load__cases__typeinfo_all_list/main", [], "", () => {
    return Billing.make();
}, [new DeclaredTypedMeta("bp_load__cases__typeinfo_all_list@main@@Service", () => {
    return new Service("service");
}), new DeclaredTypedMeta("bp_load__cases__typeinfo_all_list@main@@Audited", () => {
    return new Audited("yes");
})])]) {
    let meta = [];
    for (const m of declared__metaAll__Service(d.typedMeta, "bp_load__cases__typeinfo_all_list@main@@Service")) {
    meta = meta.concat([("role=" + m.role)]);
}
    for (const m of declared__metaAll__Store(d.typedMeta, "bp_load__cases__typeinfo_all_list@main@@Store")) {
    meta = meta.concat([("store=" + m.store)]);
}
    __bp_print(((d.name + " ") + meta.join(",")));
}
    for (const d of [new Declared("Mailer", "bp_load__cases__typeinfo_all_list/main", [], "", () => {
    return Mailer.make();
}, [new DeclaredTypedMeta("bp_load__cases__typeinfo_all_list@main@@Service", () => {
    return new Service("service");
})]), new Declared("Billing", "bp_load__cases__typeinfo_all_list/main", [], "", () => {
    return Billing.make();
}, [new DeclaredTypedMeta("bp_load__cases__typeinfo_all_list@main@@Service", () => {
    return new Service("service");
}), new DeclaredTypedMeta("bp_load__cases__typeinfo_all_list@main@@Audited", () => {
    return new Audited("yes");
})])]) {
    __bp_print((((((d.name + " ") + (__bp_int((declared__metaAll__Service(d.typedMeta, "bp_load__cases__typeinfo_all_list@main@@Service").length + declared__metaAll__Audited(d.typedMeta, "bp_load__cases__typeinfo_all_list@main@@Audited").length), -2147483648, 2147483647, "+ on i32 at src/main.bp:54:21")).toString()) + " [") + d.returnTypeName) + "]"));
}
}
exports.main = main;

// What `#[service]` records.

class Service {
    constructor(role) {
        this.role = role;
    }
}
Service.prototype.__bp = "Service";

// What `#[repository]` records.

class Store {
    constructor(store) {
        this.store = store;
    }
}
Store.prototype.__bp = "Store";

// What `#[audited]` records.

class Audited {
    constructor(audit) {
        this.audit = audit;
    }
}
Audited.prototype.__bp = "Audited";

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
    return "cases/typeinfo_all_list|*";
}
exports.__bp_loaded_info = __bp_loaded_info;

function declared__metaAll__Service(slots, key) {
    let out = [];
    for (const s of slots) {
    (() => { if ((s.key === key)) { const f = s.value; return (() => { if (((_v) => (typeof _v === "function" && _v.length === 0))(f)) { return out.push(f()); } })(); } })();
}
    return out;
}
exports.declared__metaAll__Service = declared__metaAll__Service;

function declared__metaAll__Store(slots, key) {
    let out = [];
    for (const s of slots) {
    (() => { if ((s.key === key)) { const f = s.value; return (() => { if (((_v) => (typeof _v === "function" && _v.length === 0))(f)) { return out.push(f()); } })(); } })();
}
    return out;
}
exports.declared__metaAll__Store = declared__metaAll__Store;

function declared__metaAll__Audited(slots, key) {
    let out = [];
    for (const s of slots) {
    (() => { if ((s.key === key)) { const f = s.value; return (() => { if (((_v) => (typeof _v === "function" && _v.length === 0))(f)) { return out.push(f()); } })(); } })();
}
    return out;
}
exports.declared__metaAll__Audited = declared__metaAll__Audited;

function _botopink_main() {
    main();
}
if (require.main === module) {
    const __bp_abort = (e) => { const k = (e != null && e.__bp_panic != null) ? ["panic", (typeof e.__bp_panic === "string") ? e.__bp_panic : e.message] : (e != null && typeof e.__bp_assert_loc === "string") ? ["panic", e.message] : [(e != null && e.__bp_host === true) ? "host" : "crash", (e instanceof Error) ? e.message : String(e)]; globalThis.process.stderr.write(k[0] + ": " + k[1] + "\n", () => globalThis.process.exit(1)); };
    globalThis.process.on("uncaughtException", __bp_abort);
    globalThis.process.on("unhandledRejection", __bp_abort);
    _botopink_main();
}

Object.defineProperty(exports, "__bp_priv__", { value: { DeclaredMeta, DeclaredTypedMeta, Declared, Mailer, Orders, Billing, main, Service, Store, Audited, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info, declared__metaAll__Service, declared__metaAll__Store, declared__metaAll__Audited } });
