----- SOURCE CODE -- std/order.bp
```botopink
//// Gleam-style `order` module, inspired by `gleam/order`. A sum type — the
//// `type Order` (type-exported to importers) plus companion functions.
//// Construct via the module fns (`order.lt()`); `toInt`/`reverse` operate on
//// an `Order`. Enums are concrete types, not interfaces.

pub type Order {
    Lt,
    Eq,
    Gt,
}

pub fn lt() -> Order {
    return Order.Lt;
}

pub fn eq() -> Order {
    return Order.Eq;
}

pub fn gt() -> Order {
    return Order.Gt;
}

pub fn toInt(o: Order) -> i32 {
    val n = case o {
        Lt -> -1;
        Eq -> 0;
        _ -> 1;
    };
    return n;
}

pub fn reverse(o: Order) -> Order {
    val r = case o {
        Lt -> Order.Gt;
        Gt -> Order.Lt;
        _ -> Order.Eq;
    };
    return r;
}

test "order toInt" {
    assert toInt(lt()) == -1;
    assert toInt(eq()) == 0;
    assert toInt(gt()) == 1;
}

test "order reverse" {
    assert toInt(reverse(lt())) == 1;
    assert toInt(reverse(gt())) == -1;
    assert toInt(reverse(eq())) == 0;
}

test "order case over Order" {
    val o = reverse(lt());
    val s = case o {
        Lt -> "less";
        Gt -> "greater";
        _ -> "equal";
    };
    assert s == "greater";
}

```

----- JAVASCRIPT -- std/order.js
```javascript
//// Gleam-style `order` module, inspired by `gleam/order`. A sum type — the

//// `type Order` (type-exported to importers) plus companion functions.

//// Construct via the module fns (`order.lt()`); `toInt`/`reverse` operate on

//// an `Order`. Enums are concrete types, not interfaces.

class Order {
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
```

----- TYPESCRIPT TYPEDEF -- std/order.d.ts
```typescript
export declare class Order {
    readonly tag: "Lt" | "Eq" | "Gt";
    static readonly Lt: Order;
    static readonly Eq: Order;
    static readonly Gt: Order;
}


export declare function lt(): Order;


export declare function eq(): Order;


export declare function gt(): Order;


export declare function toInt(o: Order): number;


export declare function reverse(o: Order): Order;

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- std/dict.bp
```botopink
//// Gleam-inspired `dict` module — a `type Dict<K, V>` wrapping an
//// association list `pairs: Array<#(K, V)>` for full backend portability
//// (no host-backing). O(n) read; camelCase convention.
////
//// Instance operations are `self`-methods on the record; `empty` is a
//// top-level constructor (records hold state and are constructed — unlike
//// interfaces, which are pure behaviour contracts).
////
//// `==` / `!=` on generic K uses structural equality (string/numeric keys —
//// the common case). API naming note: `new`/`get` are keyword tokens — use
//// `empty`/`at`.
////
//// `Dict<K, V>` answers the ambient `Index<K, V>` of `builtins.d.bp`
//// (decision 63, amended), which is what makes `d["k"]` legal: the index
//// expression has no typing rule of its own and rewrites to `d.at("k")`. The
//// reader was spelled `lookup` until that amendment gave every indexable type
//// one method name.

pub type Dict<K, V>(
    pairs: Array<#(K, V)>,
) implement Index<K, V> {
    pub fn at(self: Self, key: K) -> ?V {
        // NOTE: written with `forEach` + accumulator rather than
        // `.at(0).map(…)` — chained method dispatch on a `?T` (option-map) is
        // not lowered yet (tracked in tasks/v0.beta.4 Part A: primitive/option
        // method dispatch). `.at(0)` here would type as array, not `?T`.
        var found: ?V = null;
        self.pairs.forEach({ p -> if (p._0 == key) found = p._1 });
        return found;
    }

    pub fn hasKey(self: Self, key: K) -> bool {
        return self.pairs.filter({ p -> p._0 == key }).at(0) != null;
    }

    pub fn size(self: Self) -> i32 {
        return self.pairs.length;
    }

    pub fn isEmpty(self: Self) -> bool {
        return self.pairs.length == 0;
    }

    pub fn keys(self: Self) -> Array<K> {
        return self.pairs.map({ p -> p._0 });
    }

    pub fn values(self: Self) -> Array<V> {
        return self.pairs.map({ p -> p._1 });
    }

    pub fn insert(self: Self, key: K, value: V) -> Dict<K, V> {
        val filtered = self.pairs.filter({ p -> p._0 != key });
        return Dict(pairs: filtered.append([#(key, value)]));
    }

    pub fn delete(self: Self, key: K) -> Dict<K, V> {
        return Dict(pairs: self.pairs.filter({ p -> p._0 != key }));
    }

    // Right-biased merge: keys in both keep `other`'s value.
    pub fn merge(self: Self, other: Dict<K, V>) -> Dict<K, V> {
        var out = self;
        other.pairs.forEach({ p ->
            out = out.insert(p._0, p._1);
        });
        return out;
    }

    pub fn fold<A>(
        self: Self,
        initial: A,
        f: fn(acc: A, key: K, value: V) -> A,
    ) -> A {
        var acc = initial;
        self.pairs.forEach({ p ->
            acc = f(acc, p._0, p._1);
        });
        return acc;
    }

    pub fn mapValues<W>(self: Self, f: fn(value: V) -> W) -> Dict<K, W> {
        var out = [];
        self.pairs.forEach({ p -> out.push(#(p._0, f(p._1))) });
        return Dict(pairs: out);
    }
}

pub fn empty<K, V>() -> Dict<K, V> {
    return Dict(pairs: []);
}

test "dict empty is empty" {
    val d = empty();
    assert d.isEmpty();
    assert d.size() == 0;
}

test "dict insert and at" {
    val d = empty().insert("a", 1);
    assert d.at("a").unwrapOr(0) == 1;
    assert d.at("z").unwrapOr(-1) == -1;
}

test "dict pipeline: insert chain" {
    val d = empty().insert("x", 10).insert("y", 20).insert("z", 30);
    assert d.at("x").unwrapOr(0) == 10;
    assert d.at("y").unwrapOr(0) == 20;
    assert d.at("z").unwrapOr(0) == 30;
}

test "dict hasKey" {
    val d = empty().insert("k", 99);
    assert d.hasKey("k");
    assert !d.hasKey("missing");
}

test "dict delete removes key" {
    val d = empty().insert("a", 1).insert("b", 2).delete("a");
    assert !d.hasKey("a");
    assert d.at("b").unwrapOr(0) == 2;
}

test "dict insert overwrites duplicate" {
    val d = empty().insert("k", 1).insert("k", 99);
    assert d.size() == 1;
    assert d.at("k").unwrapOr(0) == 99;
}

test "dict size counts unique keys" {
    val d = empty().insert("a", 1).insert("b", 2);
    assert d.size() == 2;
}

test "dict keys" {
    val d = empty().insert("a", 1).insert("b", 2);
    assert d.keys().length == 2;
}

test "dict values" {
    val d = empty().insert("a", 10).insert("b", 20);
    assert d.values().length == 2;
}

test "dict fold sums values" {
    val d = empty().insert("a", 3).insert("b", 7);
    val total = d.fold(0, { acc, k, v -> acc + v });
    assert total == 10;
}

test "dict merge right-biased" {
    val a = empty().insert("k", 1);
    val b = empty().insert("k", 99);
    val m = a.merge(b);
    assert m.at("k").unwrapOr(0) == 99;
}

test "dict mapValues transforms values" {
    val d = empty().insert("a", 3).insert("b", 7);
    val doubled = d.mapValues({ v -> v * 2 });
    assert doubled.at("a").unwrapOr(0) == 6;
    assert doubled.at("b").unwrapOr(0) == 14;
}

// ── option method API over `at`'s `?V` (B1: Option map/flatMap/unwrapOr) ──

test "option map over a present at" {
    val some = empty().insert("a", 1).at("a");
    assert some.map({ x -> x + 9 }).unwrapOr(0) == 10;
}

test "option map propagates absence" {
    val none = empty().insert("a", 1).at("z");
    assert none.map({ x -> x + 9 }).unwrapOr(-1) == -1;
}

test "option flatMap chains present" {
    val d = empty().insert("a", 1);
    val r = d.at("a").flatMap({ x -> d.at("a").map({ y -> x + y }) });
    assert r.unwrapOr(0) == 2;
}

test "option flatMap short-circuits on absence" {
    val d = empty().insert("a", 1);
    val r = d.at("missing").flatMap({ x -> d.at("a") });
    assert r.unwrapOr(-7) == -7;
}

test "option unwrapOr returns present value" {
    assert empty().insert("a", 42).at("a").unwrapOr(0) == 42;
}

// ── empty-collection boundary (B1) ──

test "dict empty boundary: size 0, at misses" {
    val d: Dict<string, i32> = empty();
    assert d.size() == 0;
    assert !d.hasKey("anything");
    assert d.at("anything").unwrapOr(-1) == -1;
    assert d.keys().length == 0;
    assert d.values().length == 0;
}

```

----- JAVASCRIPT -- std/dict.js
```javascript
function __bp_array_at(xs, i) { return (i >= 0 && i < xs.length) ? xs[i] : null; }

//// Gleam-inspired `dict` module — a `type Dict<K, V>` wrapping an

//// association list `pairs: Array<#(K, V)>` for full backend portability

//// (no host-backing). O(n) read; camelCase convention.

//// 

//// Instance operations are `self`-methods on the record; `empty` is a

//// top-level constructor (records hold state and are constructed — unlike

//// interfaces, which are pure behaviour contracts).

//// 

//// `==` / `!=` on generic K uses structural equality (string/numeric keys —

//// the common case). API naming note: `new`/`get` are keyword tokens — use

//// `empty`/`at`.

//// 

//// `Dict<K, V>` answers the ambient `Index<K, V>` of `builtins.d.bp`

//// (decision 63, amended), which is what makes `d["k"]` legal: the index

//// expression has no typing rule of its own and rewrites to `d.at("k")`. The

//// reader was spelled `lookup` until that amendment gave every indexable type

//// one method name.

class Dict {
    constructor(pairs) {
        this.pairs = pairs;
    }

    at(key) {
        // NOTE: written with `forEach` + accumulator rather than;
        // `.at(0).map(…)` — chained method dispatch on a `?T` (option-map) is;
        // not lowered yet (tracked in tasks/v0.beta.4 Part A: primitive/option;
        // method dispatch). `.at(0)` here would type as array, not `?T`.;
        let found = null;
        this.pairs.forEach((p) => {
    return (() => { if ((p[0] === key)) { return found = p[1]; } })();
});
        return found;
    }

    hasKey(key) {
        return (__bp_array_at(this.pairs.filter((p) => {
    return (p[0] === key);
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
    return (p[0] !== key);
});
        return new Dict(filtered.concat([[key, value]]));
    }

    delete(key) {
        return new Dict(this.pairs.filter((p) => {
    return (p[0] !== key);
}));
    }

    merge(other) {
        let out = this;
        other.pairs.forEach((p) => {
    out = out.insert(p[0], p[1]);
});
        return out;
    }

    fold(initial, f) {
        let acc = initial;
        this.pairs.forEach((p) => {
    acc = f(acc, p[0], p[1]);
});
        return acc;
    }

    mapValues(f) {
        let out = [];
        this.pairs.forEach((p) => {
    return out.push([p[0], f(p[1])]);
});
        return new Dict(out);
    }
}
Dict.prototype.__bp = "Dict";
exports.Dict = Dict;

function empty() {
    return new Dict([]);
}
exports.empty = empty;

// ── option method API over `at`'s `?V` (B1: Option map/flatMap/unwrapOr) ──

// ── empty-collection boundary (B1) ──
```

----- TYPESCRIPT TYPEDEF -- std/dict.d.ts
```typescript
export declare class Dict<K, V> {
    readonly pairs: Array<[K, V]>;
    constructor(pairs: Array<[K, V]>);
    at(key: K): V | null;
    hasKey(key: K): boolean;
    size(): number;
    isEmpty(): boolean;
    keys(): Array<K>;
    values(): Array<V>;
    insert(key: K, value: V): Dict<K, V>;
    delete(key: K): Dict<K, V>;
    merge(other: Dict<K, V>): Dict<K, V>;
    fold<A>(initial: A, f: (acc: A, key: K, value: V) => A): A;
    mapValues<W>(f: (value: V) => W): Dict<K, W>;
}


export declare function empty<K, V>(): Dict<K, V>;

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {dict.Dict, dict: {empty as newDict}, order: {gt, reverse, toInt}} from "std";

fn main() {
    val d: Dict<string, i32> = newDict();
    @print(d.insert("a", 1).size());
    @print(toInt(reverse(gt())));
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_show(v, s, top, a) {
    if ((typeof v === "string")) {
        a.push(top ? v : (("\"" + Array.from(v, (c) => ((c === "\"") || (c === "\\")) ? ("\\" + c) : (c === "\n") ? "\\n" : (c === "\r") ? "\\r" : (c === "\t") ? "\\t" : c).join("")) + "\""));
        return "%s";
    }
    if (((typeof v === "number") && (s === "f"))) {
        a.push(Number.isInteger(v) ? v.toFixed(1) : String(v));
        return "%s";
    }
    if (Array.isArray(v)) {
        const t = ((s != null) && (s[0] === "#"));
        return (((t ? "#(" : "[") + v.map((e, i) => __bp_show(e, (s == null) ? null : t ? s[i + 1] : s[1], false, a)).join(", ")) + (t ? ")" : "]"));
    }
    if (((v != null) && (typeof v.__bp === "string"))) {
        if ((typeof v.display === "function")) {
            a.push(v.display());
            return "%s";
        }
        const k = Object.keys(v);
        return (((typeof v.tag === "string") ? ((v.__bp + ".") + v.tag) : v.__bp) + ((k.length === 0) ? "" : (("(" + k.map((n) => ((n + ": ") + __bp_show(v[n], null, false, a))).join(", ")) + ")")));
    }
    a.push(v);
    return "%O";
}

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

const { Dict, empty: newDict } = require("./std/dict.js");
const { gt, reverse, toInt } = require("./std/order.js");

function main() {
    const d = newDict();
    __bp_print(d.insert("a", 1).size());
    __bp_print(toInt(reverse(gt())));
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
import { Dict, empty as newDict } from "./std/dict";
import { gt, reverse, toInt } from "./std/order";











```

----- RUN LOG -----
```logs
1
-1
```
