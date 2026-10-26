function __bp_array_at(xs, i) { return xs.at(i) ?? null; }

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

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

// behavior array
//   length: i32
//   fn at(...)
//   fn push(...)
//   fn pop(...)
//   default fn slice(...)
//   fn join(...)
//   fn reverse(...)
//   fn indexOf(...)
//   default fn lastIndexOf(...)
//   fn forEach(...)
//   fn map(...)
//   fn filter(...)
//   fn zip(...)
//   fn range(...)
//   fn repeat(...)
//   default fn isEmpty(...)
//   default fn contains(...)
//   default fn first(...)
//   default fn rest(...)
//   default fn take(...)
//   default fn drop(...)
//   default fn fold(...)
//   default fn find(...)
//   default fn count(...)
//   default fn all(...)
//   default fn any(...)
//   default fn append(...)
//   default fn prepend(...)
//   default fn flatten(...)
//   default fn flatMap(...)
//   default fn toList(...)
//   default fn some(...)
//   default fn every(...)
//   default fn flat(...)
//   default fn findIndex(...)
//   default fn fill(...)
//   default fn chunked(...)
//   default fn sliding(...)
//   default fn unique(...)
Array.range = function(start, stop) { return ((__a, __b) => Array.from({ length: Math.max(0, __b - __a) }, (_, __i) => __a + __i))(start, stop); };
Array.repeat = function(value, times) { return ((__v, __n) => Array.from({ length: Math.max(0, __n) }, () => __v))(value, times); };
Array.prototype.slice = function(start, end) {
    if ((end != null)) { return ((__xs, __a, __e) => { const __n = __xs.length; if (__a == null) __a = 0; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return Array.from({ length: Math.max(__f - __b, 0) }, (_, __i) => __xs[__b + __i]); })(this, start, end); } else { return ((__xs, __a) => { const __n = __xs.length; if (__a == null) __a = 0; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return Array.from({ length: __n - __b }, (_, __i) => __xs[__b + __i]); })(this, start); }
};
Array.prototype.indexOf = function(item) { return this.findIndex((__e) => __bp_eq(__e, item, 0)); };
Array.prototype.lastIndexOf = function(item) { return this.findLastIndex((__e) => __bp_eq(__e, item, 0)); };
Array.prototype.zip = function(other) { return this.map((__x, __i) => [__x, (other)[__i]]).slice(0, Math.min(this.length, (other).length)); };
Array.prototype.isEmpty = function() {
    return (this.length === 0);
};
Array.prototype.contains = function(x) {
    return (this.indexOf(x) !== (-1));
};
Array.prototype.first = function() {
    return __bp_array_at(this, 0);
};
Array.prototype.rest = function() {
    return this.slice(1, this.length);
};
Array.prototype.take = function(n) {
    return this.slice(0, n);
};
Array.prototype.drop = function(n) {
    return this.slice(n, this.length);
};
Array.prototype.fold = function(initial, f) {
    let acc = initial;
    this.forEach((x) => {
    acc = f(acc, x);
});
    return acc;
};
Array.prototype.count = function(pred) {
    return this.filter(pred).length;
};
Array.prototype.all = function(pred) {
    return (this.filter(pred).length === this.length);
};
Array.prototype.any = function(pred) {
    return (this.filter(pred).length !== 0);
};
Array.prototype.prepend = function(item) {
    let out = [item];
    this.forEach((x) => {
    return out.push(x);
});
    return out;
};
Array.prototype.flatten = function() {
    let out = [];
    this.forEach((inner) => {
    out = out.concat(inner);
});
    return out;
};
Array.prototype.toList = function() {
    return this;
};
Array.prototype.some = function(pred) {
    return this.any(pred);
};
Array.prototype.every = function(pred) {
    return this.all(pred);
};
Array.prototype.flat = function() {
    return this.flatten();
};
Array.prototype.findIndex = function(pred) {
    let out = (-1);
    let i = 0;
    this.forEach((x) => {
    (() => { if ((out === (-1))) { return (() => { if (pred(x)) { return out = i; } })(); } })();
    i = (i + 1);
});
    return out;
};
Array.prototype.fill = function(value) {
    return Array.repeat(value, this.length);
};
Array.prototype.chunked = function(n) {
    let out = [];
    if ((n <= 0)) { return out; }
    const len = this.length;
    for (const k of Array.from({length: Math.max(0, (len) - (0))}, (_, __i) => (0) + __i)) {
    (() => { if ((((k % n) + 0) === 0)) { return out = out.concat([this.slice(k, (k + n))]); } })();
}
    return out;
};
Array.prototype.sliding = function(n) {
    let out = [];
    if ((n <= 0)) { return out; }
    const windows = ((this.length - n) + 1);
    if ((windows <= 0)) { return out; }
    for (const k of Array.from({length: Math.max(0, (windows) - (0))}, (_, __i) => (0) + __i)) {
    out = out.concat([this.slice(k, (k + n))]);
}
    return out;
};
Array.prototype.unique = function() {
    let out = [];
    this.forEach((x) => {
    return (() => { if ((!out.any((y) => {
    return __bp_eq(y, x, 0);
}))) { return out = out.concat([x]); } })();
});
    return out;
};

//// std/collections — the four collection types, one namespace each (decision

//// 106): `Dict<K, V>`, `Set<T>`, `Queue<T>` and `Order`. Was the four modules

//// `dict`, `sets`, `queue` and `order`; the type is the namespace now, so a

//// constructor is called on the type it builds (decision 111) —

//// `Dict.empty()` / `Dict.ofEntries(entries)`, `Set.empty()` /

//// `Set.fromList(xs)`, `Queue.empty()` / `Queue.fromList(xs)` — and every

//// other function keeps its name.

// ── Dict<K, V> ──────────────────────────────────────────────────────────────

// `Dict` (was `dict`) — Gleam-inspired — a `type Dict<K, V>` wrapping an

// association list `pairs: array<#(K, V)>` for full backend portability

// (no host-backing). O(n) read; camelCase convention.

// 

// Instance operations are `self`-methods on the record; `empty` is a

// type-scoped constructor, `Dict.empty()` (records hold state and are

// constructed — unlike interfaces, which are pure behaviour contracts).

// 

// `==` / `!=` on generic K uses structural equality (string/numeric keys —

// the common case). API naming note: `new`/`get` are keyword tokens — use

// `empty`/`at`.

// 

// `Dict<K, V>` answers the ambient `Index<K, V>` of `primitives.bp`

// (decision 63, amended), which is what makes `d["k"]` legal: the index

// expression has no typing rule of its own and rewrites to `d.at("k")`. The

// reader was spelled `lookup` until that amendment gave every indexable type

// one method name.

class Dict {
    constructor(pairs) {
        this.pairs = pairs;
    }

    display() {
        let parts = [];
        for (const p of this.pairs) {
    parts = parts.concat([((shown(p[0], this.__bp_s?.$K) + ": ") + shown(p[1], this.__bp_s?.$V))]);
}
        return (("Dict(" + parts.join(", ")) + ")");
    }

    at(key) {
        // NOTE: written with `forEach` + accumulator rather than;
        // `.at(0).map(…)` — chained method dispatch on a `?T` (option-map) is;
        // not lowered yet (tracked in tasks/v0.beta.4 Part A: primitive/option;
        // method dispatch). `.at(0)` here would type as array, not `?T`.;
        let found = null;
        this.pairs.forEach((p) => {
    return (() => { if (__bp_eq(p[0], key, 0)) { return found = p[1]; } })();
});
        return found;
    }

    hasKey(key) {
        return (__bp_array_at(this.pairs.filter((p) => {
    return __bp_eq(p[0], key, 0);
}), 0) != null);
    }

    size() {
        return this.pairs.length;
    }

    isEmpty() {
        return (this.pairs.length === 0);
    }

    keys() {
        return this.pairs.map((p) => {
    return p[0];
});
    }

    values() {
        return this.pairs.map((p) => {
    return p[1];
});
    }

    insert(key, value) {
        const filtered = this.pairs.filter((p) => {
    return (!__bp_eq(p[0], key, 0));
});
        return Object.defineProperty(new Dict(filtered.concat([[key, value]])), "__bp_s", { value: { pairs: ["[", ["#", this.__bp_s?.$K, this.__bp_s?.$V]], $K: this.__bp_s?.$K, $V: this.__bp_s?.$V } });
    }

    bump(key, by) {
        return this.insert(key, __bp_int((((() => { const __bp_nullish = this.at(key); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })()) + by), -2147483648, 2147483647, "+ on i32 at src/collections.bp:81:53"));
    }

    delete(key) {
        return Object.defineProperty(new Dict(this.pairs.filter((p) => {
    return (!__bp_eq(p[0], key, 0));
})), "__bp_s", { value: { pairs: ["[", ["#", this.__bp_s?.$K, this.__bp_s?.$V]], $K: this.__bp_s?.$K, $V: this.__bp_s?.$V } });
    }

    merge(other) {
        let out = this;
        other.pairs.forEach((p) => {
    out = out.insert(p[0], p[1]);
});
        return out;
    }

    fold(initial, f, __bp_ty_A) {
        let acc = initial;
        this.pairs.forEach((p) => {
    acc = f(acc, p[0], p[1]);
});
        return acc;
    }

    mapValues(f, __bp_ty_W) {
        let out = [];
        this.pairs.forEach((p) => {
    return out.push([p[0], f(p[1])]);
});
        return Object.defineProperty(new Dict(out), "__bp_s", { value: { pairs: ["[", ["#", this.__bp_s?.$K, __bp_ty_W]], $K: this.__bp_s?.$K, $V: __bp_ty_W } });
    }

    static empty(__bp_ty_K, __bp_ty_V) {
        return Object.defineProperty(new Dict([]), "__bp_s", { value: { pairs: ["[", ["#", __bp_ty_K, __bp_ty_V]], $K: __bp_ty_K, $V: __bp_ty_V } });
    }

    static ofEntries(entries, __bp_ty_K, __bp_ty_V) {
        let out = Object.defineProperty(new Dict([]), "__bp_s", { value: { pairs: ["[", ["#", __bp_ty_K, __bp_ty_V]], $K: __bp_ty_K, $V: __bp_ty_V } });
        entries.forEach((e) => {
    out = out.insert(e[0], e[1]);
});
        return out;
    }
}
Dict.prototype.__bp = "Dict";
Dict.prototype["__bp_b_std@primitives@@Index"] = true;
Dict.prototype["__bp_b_std@primitives@@Display"] = true;
Dict.prototype.__bp_s = { pairs: ["[", ["#", null, null]] };
exports.Dict = Dict;

// One key or value of `Dict.display`: a string quoted, anything else as it

// interpolates.

function shown(x, __bp_ty_T) {
    if (typeof x === "string") { return (("\"" + __bp_text(x, __bp_ty_T)) + "\""); }
    return ("" + __bp_text(x, __bp_ty_T));
}

// ── `??` over `at`'s `?V` (decision 330: `?T` has no methods) ──

// ── empty-collection boundary (B1) ──

// ── Set<T> ──────────────────────────────────────────────────────────────────

// `Set` (was `sets`) — Gleam-inspired — a `type Set<T>` wrapping a deduplicated

// `array<T>` (`items`). Pure botopink — no host backing. O(n) contains;

// membership by `==` over `any` (decision 210: records by value on every

// target; `indexOf` is the host's identity on commonJS and wasm).

// 

// Instance operations are `self`-methods on the record; `empty`/`fromList`

// are type-scoped constructors (`Set.empty()`, `Set.fromList(xs)`). API

// naming note: `new`/`set` are keyword tokens — the constructor is `empty`.

class Set {
    constructor(items) {
        this.items = items;
    }

    contains(x) {
        return this.items.any((y) => {
    return __bp_eq(y, x, 0);
});
    }

    size() {
        return this.items.length;
    }

    isEmpty() {
        return (this.items.length === 0);
    }

    toList() {
        return this.items;
    }

    insert(x) {
        return (() => { if (this.items.any((y) => {
    return __bp_eq(y, x, 0);
})) { return this; } else { return Object.defineProperty(new Set(this.items.concat([x])), "__bp_s", { value: { items: ["[", this.__bp_s?.$T], $T: this.__bp_s?.$T } }); } })();
    }

    delete(x) {
        return Object.defineProperty(new Set(this.items.filter((item) => {
    return (!__bp_eq(item, x, 0));
})), "__bp_s", { value: { items: ["[", this.__bp_s?.$T], $T: this.__bp_s?.$T } });
    }

    union(other) {
        return Object.defineProperty(new Set(this.items.concat(other.difference(this).items)), "__bp_s", { value: { items: ["[", this.__bp_s?.$T], $T: this.__bp_s?.$T } });
    }

    intersection(other) {
        return Object.defineProperty(new Set(this.items.filter((x) => {
    return other.contains(x);
})), "__bp_s", { value: { items: ["[", this.__bp_s?.$T], $T: this.__bp_s?.$T } });
    }

    difference(other) {
        return Object.defineProperty(new Set(this.items.filter((x) => {
    return (!other.contains(x));
})), "__bp_s", { value: { items: ["[", this.__bp_s?.$T], $T: this.__bp_s?.$T } });
    }

    static empty(__bp_ty_T) {
        return Object.defineProperty(new Set([]), "__bp_s", { value: { items: ["[", __bp_ty_T], $T: __bp_ty_T } });
    }

    static fromList(xs, __bp_ty_T) {
        let out = Object.defineProperty(new Set([]), "__bp_s", { value: { items: ["[", __bp_ty_T], $T: __bp_ty_T } });
        xs.forEach((x) => {
    out = out.insert(x);
});
        return out;
    }
}
Set.prototype.__bp = "Set";
exports.Set = Set;

// ── empty-collection boundary (B1) ──

// ── Queue<T> ────────────────────────────────────────────────────────────────

// `Queue` (was `queue`) — Gleam-inspired — a `type Queue<T>` wrapping an `array<T>`

// (front at index 0). Pure botopink — no host backing. O(n) enqueue (copy),

// O(1) peek.

// 

// Instance operations are `self`-methods on the record; `empty`/`fromList`

// are type-scoped constructors (`Queue.empty()`, `Queue.fromList(xs)`).

// `dequeue` returns `#(Queue<T>, ?T)` (the updated queue + the removed front

// item). API naming note: `new` is a keyword token —

// the constructor is `empty`.

class Queue {
    constructor(items) {
        this.items = items;
    }

    size() {
        return this.items.length;
    }

    isEmpty() {
        return (this.items.length === 0);
    }

    enqueue(item) {
        return Object.defineProperty(new Queue(this.items.concat([item])), "__bp_s", { value: { items: ["[", this.__bp_s?.$T], $T: this.__bp_s?.$T } });
    }

    dequeue() {
        const head = __bp_array_at(this.items, 0);
        const rest = this.items.slice(1, this.items.length);
        return [Object.defineProperty(new Queue(rest), "__bp_s", { value: { items: ["[", this.__bp_s?.$T], $T: this.__bp_s?.$T } }), head];
    }

    peek() {
        return __bp_array_at(this.items, 0);
    }

    toList() {
        return this.items;
    }

    static empty(__bp_ty_T) {
        return Object.defineProperty(new Queue([]), "__bp_s", { value: { items: ["[", __bp_ty_T], $T: __bp_ty_T } });
    }

    static fromList(xs, __bp_ty_T) {
        return Object.defineProperty(new Queue(xs), "__bp_s", { value: { items: ["[", __bp_ty_T], $T: __bp_ty_T } });
    }
}
Queue.prototype.__bp = "Queue";
exports.Queue = Queue;

// ── empty-collection boundary (B1) ──

// ── Order ───────────────────────────────────────────────────────────────────

// `Order` (was `order`) — Gleam-style, inspired by `gleam/order`. A sum type — the

// `type Order` (type-exported to importers) plus companion functions.

// Construct via the module fns (`collections.lt()`); `toInt`/`reverse` operate on

// an `Order`. Enums are concrete types, not interfaces.

class Order {
    toString() {
        return __bp_text(this);
    }
}
Order.prototype.__bp = "Order";
class Order$Lt extends Order {
}
Order$Lt.prototype.tag = "Lt";
class Order$Eq extends Order {
}
Order$Eq.prototype.tag = "Eq";
class Order$Gt extends Order {
}
Order$Gt.prototype.tag = "Gt";
Order.Lt = new Order$Lt();
Order.Eq = new Order$Eq();
Order.Gt = new Order$Gt();
exports.Order = Order;

function lt() {
    return Order.Lt;
}
exports.lt = lt;

function eq() {
    return Order.Eq;
}
exports.eq = eq;

function gt() {
    return Order.Gt;
}
exports.gt = gt;

function toInt(o) {
    const n = (() => {
        const _s = o;
        if (_s.tag === "Lt") return (-1);
        if (_s.tag === "Eq") return 0;
        return 1;
    })();
    return n;
}
exports.toInt = toInt;

function reverse(o) {
    const r = (() => {
        const _s = o;
        if (_s.tag === "Lt") return Order.Gt;
        if (_s.tag === "Gt") return Order.Lt;
        return Order.Eq;
    })();
    return r;
}
exports.reverse = reverse;

Object.defineProperty(exports, "__bp_priv__", { value: { Dict, shown, Set, Queue, Order, Order$Lt, Order$Eq, Order$Gt, lt, eq, gt, toInt, reverse } });
