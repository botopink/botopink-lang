----- SOURCE CODE -- std/collections.bp
```botopink
//// std/collections — the four collection types, one namespace each (decision
//// 106): `Dict<K, V>`, `Set<T>`, `Queue<T>` and `Order`. Was the four modules
//// `dict`, `sets`, `queue` and `order`; the type is the namespace now, so a
//// constructor is called on the type it builds (decision 111) —
//// `Dict.empty()`, `Set.empty()` / `Set.fromList(xs)`, `Queue.empty()` /
//// `Queue.fromList(xs)` — and every other function keeps its name.

// ── Dict<K, V> ──────────────────────────────────────────────────────────────
// `Dict` (was `dict`) — Gleam-inspired — a `type Dict<K, V>` wrapping an
// association list `pairs: Array<#(K, V)>` for full backend portability
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
// `Dict<K, V>` answers the ambient `Index<K, V>` of `builtins.d.bp`
// (decision 63, amended), which is what makes `d["k"]` legal: the index
// expression has no typing rule of its own and rewrites to `d.at("k")`. The
// reader was spelled `lookup` until that amendment gave every indexable type
// one method name.

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

    pub fn empty() -> Dict<K, V> {
        return Dict(pairs: []);
    }
}

test "dict empty is empty" {
    val d = Dict.empty();
    assert d.isEmpty();
    assert d.size() == 0;
}

test "dict insert and at" {
    val d = Dict.empty().insert("a", 1);
    assert d.at("a").unwrapOr(0) == 1;
    assert d.at("z").unwrapOr(-1) == -1;
}

test "dict pipeline: insert chain" {
    val d = Dict.empty().insert("x", 10).insert("y", 20).insert("z", 30);
    assert d.at("x").unwrapOr(0) == 10;
    assert d.at("y").unwrapOr(0) == 20;
    assert d.at("z").unwrapOr(0) == 30;
}

test "dict hasKey" {
    val d = Dict.empty().insert("k", 99);
    assert d.hasKey("k");
    assert !d.hasKey("missing");
}

test "dict delete removes key" {
    val d = Dict.empty().insert("a", 1).insert("b", 2).delete("a");
    assert !d.hasKey("a");
    assert d.at("b").unwrapOr(0) == 2;
}

test "dict insert overwrites duplicate" {
    val d = Dict.empty().insert("k", 1).insert("k", 99);
    assert d.size() == 1;
    assert d.at("k").unwrapOr(0) == 99;
}

test "dict size counts unique keys" {
    val d = Dict.empty().insert("a", 1).insert("b", 2);
    assert d.size() == 2;
}

test "dict keys" {
    val d = Dict.empty().insert("a", 1).insert("b", 2);
    assert d.keys().length == 2;
}

test "dict values" {
    val d = Dict.empty().insert("a", 10).insert("b", 20);
    assert d.values().length == 2;
}

test "dict fold sums values" {
    val d = Dict.empty().insert("a", 3).insert("b", 7);
    val total = d.fold(0, { acc, k, v -> acc + v });
    assert total == 10;
}

test "dict merge right-biased" {
    val a = Dict.empty().insert("k", 1);
    val b = Dict.empty().insert("k", 99);
    val m = a.merge(b);
    assert m.at("k").unwrapOr(0) == 99;
}

test "dict mapValues transforms values" {
    val d = Dict.empty().insert("a", 3).insert("b", 7);
    val doubled = d.mapValues({ v -> v * 2 });
    assert doubled.at("a").unwrapOr(0) == 6;
    assert doubled.at("b").unwrapOr(0) == 14;
}

// ── option method API over `at`'s `?V` (B1: Option map/flatMap/unwrapOr) ──

test "option map over a present at" {
    val some = Dict.empty().insert("a", 1).at("a");
    assert some.map({ x -> x + 9 }).unwrapOr(0) == 10;
}

test "option map propagates absence" {
    val none = Dict.empty().insert("a", 1).at("z");
    assert none.map({ x -> x + 9 }).unwrapOr(-1) == -1;
}

test "option flatMap chains present" {
    val d = Dict.empty().insert("a", 1);
    val r = d.at("a").flatMap({ x -> d.at("a").map({ y -> x + y }) });
    assert r.unwrapOr(0) == 2;
}

test "option flatMap short-circuits on absence" {
    val d = Dict.empty().insert("a", 1);
    val r = d.at("missing").flatMap({ x -> d.at("a") });
    assert r.unwrapOr(-7) == -7;
}

test "option unwrapOr returns present value" {
    assert Dict.empty().insert("a", 42).at("a").unwrapOr(0) == 42;
}

// ── empty-collection boundary (B1) ──

test "dict empty boundary: size 0, at misses" {
    val d: Dict<string, i32> = Dict.empty();
    assert d.size() == 0;
    assert !d.hasKey("anything");
    assert d.at("anything").unwrapOr(-1) == -1;
    assert d.keys().length == 0;
    assert d.values().length == 0;
}

// ── Set<T> ──────────────────────────────────────────────────────────────────
// `Set` (was `sets`) — Gleam-inspired — a `type Set<T>` wrapping a deduplicated
// `Array<T>` (`items`). Pure botopink — no host backing. O(n) contains;
// uniqueness via `Array.indexOf` (structural equality — string/numeric elems).
//
// Instance operations are `self`-methods on the record; `empty`/`fromList`
// are type-scoped constructors (`Set.empty()`, `Set.fromList(xs)`). API
// naming note: `new`/`set` are keyword tokens — the constructor is `empty`.

pub type Set<T>(
    items: Array<T>,
) {
    pub fn contains(self: Self, x: T) -> bool {
        return self.items.indexOf(x) != -1;
    }

    pub fn size(self: Self) -> i32 {
        return self.items.length;
    }

    pub fn isEmpty(self: Self) -> bool {
        return self.items.length == 0;
    }

    pub fn toList(self: Self) -> Array<T> {
        return self.items;
    }

    pub fn insert(self: Self, x: T) -> Set<T> {
        return if (self.items.indexOf(x) != -1) self else Set(items: self.items.append(
                [x]
            ));
    }

    pub fn delete(self: Self, x: T) -> Set<T> {
        return Set(items: self.items.filter({ item -> item != x }));
    }

    pub fn union(self: Self, other: Set<T>) -> Set<T> {
        var out = self;
        other.items.forEach({ x ->
            out = out.insert(x);
        });
        return out;
    }

    pub fn intersection(self: Self, other: Set<T>) -> Set<T> {
        return Set(items: self.items.filter({ x -> other.items.indexOf(x) != -1 }));
    }

    pub fn difference(self: Self, other: Set<T>) -> Set<T> {
        return Set(items: self.items.filter({ x -> other.items.indexOf(x) == -1 }));
    }

    pub fn empty() -> Set<T> {
        return Set(items: []);
    }

    pub fn fromList(xs: Array<T>) -> Set<T> {
        var out: Set<T> = Set(items: []);
        xs.forEach({ x ->
            out = out.insert(x);
        });
        return out;
    }
}

test "set empty is empty" {
    assert Set.empty().isEmpty();
    assert Set.empty().size() == 0;
}

test "set insert and contains" {
    val s = Set.empty().insert("a").insert("b");
    assert s.contains("a");
    assert s.contains("b");
    assert !s.contains("c");
}

test "set insert is idempotent" {
    val s = Set.empty().insert("x").insert("x");
    assert s.size() == 1;
}

test "set delete removes element" {
    val s = Set.empty().insert("a").insert("b").delete("a");
    assert !s.contains("a");
    assert s.contains("b");
}

test "set fromList deduplicates" {
    val s = Set.fromList([1, 2, 2, 3, 1]);
    assert s.size() == 3;
}

test "set toList round-trips" {
    val s = Set.fromList(["x", "y", "z"]);
    assert s.toList().length == 3;
}

test "set union combines without duplicates" {
    val a = Set.fromList([1, 2, 3]);
    val b = Set.fromList([2, 3, 4]);
    val u = a.union(b);
    assert u.size() == 4;
    assert u.contains(1);
    assert u.contains(4);
}

test "set intersection keeps shared elements" {
    val a = Set.fromList([1, 2, 3]);
    val b = Set.fromList([2, 3, 4]);
    val i = a.intersection(b);
    assert i.size() == 2;
    assert i.contains(2);
    assert i.contains(3);
    assert !i.contains(1);
}

test "set difference removes b from a" {
    val a = Set.fromList([1, 2, 3]);
    val b = Set.fromList([2, 3, 4]);
    val d = a.difference(b);
    assert d.size() == 1;
    assert d.contains(1);
    assert !d.contains(2);
}

// ── empty-collection boundary (B1) ──

test "set empty boundary: size 0, contains misses, toList empty" {
    val s: Set<i32> = Set.empty();
    assert s.size() == 0;
    assert s.isEmpty();
    assert !s.contains(1);
    assert s.toList().length == 0;
    // an empty set is the identity element for union.
    assert s.union(Set.fromList([1, 2])).size() == 2;
    // intersection / difference with empty stay empty.
    assert Set.fromList([1, 2]).intersection(s).size() == 0;
}

// ── Queue<T> ────────────────────────────────────────────────────────────────
// `Queue` (was `queue`) — Gleam-inspired — a `type Queue<T>` wrapping an `Array<T>`
// (front at index 0). Pure botopink — no host backing. O(n) enqueue (copy),
// O(1) peek.
//
// Instance operations are `self`-methods on the record; `empty`/`fromList`
// are type-scoped constructors (`Queue.empty()`, `Queue.fromList(xs)`).
// `dequeue` returns `#(Queue<T>, ?T)` (the updated queue + the removed front
// item). API naming note: `new` is a keyword token —
// the constructor is `empty`.

pub type Queue<T>(
    items: Array<T>,
) {
    pub fn size(self: Self) -> i32 {
        return self.items.length;
    }

    pub fn isEmpty(self: Self) -> bool {
        return self.items.length == 0;
    }

    pub fn enqueue(self: Self, item: T) -> Queue<T> {
        return Queue(items: self.items.append([item]));
    }

    pub fn dequeue(self: Self) -> #(Queue<T>, ?T) {
        val head = self.items.at(0);
        val rest = self.items.slice(1, self.items.length);
        return #(Queue(items: rest), head);
    }

    pub fn peek(self: Self) -> ?T {
        return self.items.at(0);
    }

    pub fn toList(self: Self) -> Array<T> {
        return self.items;
    }

    pub fn empty() -> Queue<T> {
        return Queue(items: []);
    }

    pub fn fromList(xs: Array<T>) -> Queue<T> {
        return Queue(items: xs);
    }
}

test "queue empty is empty" {
    val q = Queue.empty();
    assert q.isEmpty();
    assert q.size() == 0;
}

test "queue enqueue increases size" {
    val q = Queue.empty().enqueue(1);
    assert q.size() == 1;
    assert !q.isEmpty();
}

test "queue peek at front" {
    val q = Queue.empty().enqueue(10).enqueue(20);
    assert q.peek().unwrapOr(-1) == 10;
}

test "queue dequeue returns front and rest" {
    val q = Queue.empty().enqueue(1).enqueue(2);
    val result = q.dequeue();
    val rest = result._0;
    val head = result._1;
    assert head.unwrapOr(-1) == 1;
    assert rest.size() == 1;
    assert rest.peek().unwrapOr(-1) == 2;
}

test "queue dequeue empty yields no front item" {
    val result = Queue.empty().dequeue();
    val head = result._1;
    assert head.unwrapOr(-99) == -99;
}

test "queue fifo order preserved" {
    val q = Queue.empty().enqueue(1).enqueue(2).enqueue(3);
    val r1 = q.dequeue();
    val r2 = r1._0.dequeue();
    val r3 = r2._0.dequeue();
    assert r1._1.unwrapOr(-1) == 1;
    assert r2._1.unwrapOr(-1) == 2;
    assert r3._1.unwrapOr(-1) == 3;
}

test "queue fromList and toList round-trip" {
    val q = Queue.fromList([10, 20, 30]);
    assert q.size() == 3;
    assert q.toList().join(",") == "10,20,30";
}

// ── empty-collection boundary (B1) ──

test "queue empty boundary: size 0, peek + dequeue miss" {
    val q: Queue<i32> = Queue.empty();
    assert q.size() == 0;
    assert q.isEmpty();
    assert q.peek().unwrapOr(-1) == -1;
    val r = q.dequeue();
    assert r._0.size() == 0;
    assert r._1.unwrapOr(-1) == -1;
}

// ── Order ───────────────────────────────────────────────────────────────────
// `Order` (was `order`) — Gleam-style, inspired by `gleam/order`. A sum type — the
// `type Order` (type-exported to importers) plus companion functions.
// Construct via the module fns (`collections.lt()`); `toInt`/`reverse` operate on
// an `Order`. Enums are concrete types, not interfaces.

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

----- JAVASCRIPT -- std/collections.js
```javascript
function __bp_array_at(xs, i) { return (i >= 0 && i < xs.length) ? xs[i] : null; }

//// std/collections — the four collection types, one namespace each (decision

//// 106): `Dict<K, V>`, `Set<T>`, `Queue<T>` and `Order`. Was the four modules

//// `dict`, `sets`, `queue` and `order`; the type is the namespace now, so a

//// constructor is called on the type it builds (decision 111) —

//// `Dict.empty()`, `Set.empty()` / `Set.fromList(xs)`, `Queue.empty()` /

//// `Queue.fromList(xs)` — and every other function keeps its name.

// ── Dict<K, V> ──────────────────────────────────────────────────────────────

// `Dict` (was `dict`) — Gleam-inspired — a `type Dict<K, V>` wrapping an

// association list `pairs: Array<#(K, V)>` for full backend portability

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

// `Dict<K, V>` answers the ambient `Index<K, V>` of `builtins.d.bp`

// (decision 63, amended), which is what makes `d["k"]` legal: the index

// expression has no typing rule of its own and rewrites to `d.at("k")`. The

// reader was spelled `lookup` until that amendment gave every indexable type

// one method name.

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

    static empty() {
        return new Dict([]);
    }
}
Dict.prototype.__bp = "Dict";
exports.Dict = Dict;

// ── option method API over `at`'s `?V` (B1: Option map/flatMap/unwrapOr) ──

// ── empty-collection boundary (B1) ──

// ── Set<T> ──────────────────────────────────────────────────────────────────

// `Set` (was `sets`) — Gleam-inspired — a `type Set<T>` wrapping a deduplicated

// `Array<T>` (`items`). Pure botopink — no host backing. O(n) contains;

// uniqueness via `Array.indexOf` (structural equality — string/numeric elems).

// 

// Instance operations are `self`-methods on the record; `empty`/`fromList`

// are type-scoped constructors (`Set.empty()`, `Set.fromList(xs)`). API

// naming note: `new`/`set` are keyword tokens — the constructor is `empty`.

class Set {
    constructor(items) {
        this.items = items;
    }

    contains(x) {
        return (this.items.indexOf(x) !== (-1));
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
        return (() => { if ((this.items.indexOf(x) !== (-1))) { return this; } else { return new Set(this.items.concat([x])); } })();
    }

    delete(x) {
        return new Set(this.items.filter((item) => {
    return (item !== x);
}));
    }

    union(other) {
        let out = this;
        other.items.forEach((x) => {
    out = out.insert(x);
});
        return out;
    }

    intersection(other) {
        return new Set(this.items.filter((x) => {
    return (other.items.indexOf(x) !== (-1));
}));
    }

    difference(other) {
        return new Set(this.items.filter((x) => {
    return (other.items.indexOf(x) === (-1));
}));
    }

    static empty() {
        return new Set([]);
    }

    static fromList(xs) {
        let out = new Set([]);
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

// `Queue` (was `queue`) — Gleam-inspired — a `type Queue<T>` wrapping an `Array<T>`

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
        return new Queue(this.items.concat([item]));
    }

    dequeue() {
        const head = __bp_array_at(this.items, 0);
        const rest = this.items.slice(1, this.items.length);
        return [new Queue(rest), head];
    }

    peek() {
        return __bp_array_at(this.items, 0);
    }

    toList() {
        return this.items;
    }

    static empty() {
        return new Queue([]);
    }

    static fromList(xs) {
        return new Queue(xs);
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

----- TYPESCRIPT TYPEDEF -- std/collections.d.ts
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
    empty(): Dict<K, V>;
}


export declare class Set<T> {
    readonly items: Array<T>;
    constructor(items: Array<T>);
    contains(x: T): boolean;
    size(): number;
    isEmpty(): boolean;
    toList(): Array<T>;
    insert(x: T): Set<T>;
    delete(x: T): Set<T>;
    union(other: Set<T>): Set<T>;
    intersection(other: Set<T>): Set<T>;
    difference(other: Set<T>): Set<T>;
    empty(): Set<T>;
    fromList(xs: Array<T>): Set<T>;
}


export declare class Queue<T> {
    readonly items: Array<T>;
    constructor(items: Array<T>);
    size(): number;
    isEmpty(): boolean;
    enqueue(item: T): Queue<T>;
    dequeue(): [Queue<T>, T | null];
    peek(): T | null;
    toList(): Array<T>;
    empty(): Queue<T>;
    fromList(xs: Array<T>): Queue<T>;
}


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

----- SOURCE CODE -- main.bp
```botopink
import {collections.Dict} from "std";

fn main() {
    val d = Dict.empty().insert("a", 1);
    @print(d.at("a").unwrapOr(0));
    @print(d.insert("b", 2).size());
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
    if ((v === undefined)) return "null";
    a.push(v);
    return "%O";
}

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

const { Dict } = require("./std/collections.js");

function main() {
    const d = Dict.empty().insert("a", 1);
    __bp_print(((_o) => _o != null ? _o : (0))(d.at("a")));
    __bp_print(d.insert("b", 2).size());
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
import { Dict } from "./std/collections";



```

----- RUN LOG -----
```logs
1
2
```
