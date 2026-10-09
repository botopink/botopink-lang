----- SOURCE CODE -- std/collections.bp
```botopink
//// std/collections — the four collection types, one namespace each (decision
//// 106): `Dict<K, V>`, `Set<T>`, `Queue<T>` and `Order`. Was the four modules
//// `dict`, `sets`, `queue` and `order`; the type is the namespace now, so a
//// constructor is called on the type it builds (decision 111) —
//// `Dict.empty()` / `Dict.ofEntries(entries)`, `Set.empty()` /
//// `Set.fromList(xs)`, `Queue.empty()` / `Queue.fromList(xs)` — and every
//// other function keeps its name.

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
) implement Index<K, V>, Display {
    // Decision 8 §7 — `Dict("a": 1, "b": 2)`: the pairs in order, a string
    // key or value quoted, anything else in its own text. `K` and `V` are
    // generic, so which is a string is asked of the value (`is`, decision 8 §4).
    pub fn display(self: Self<K, V>) -> string {
        var parts: string[] = [];
        self.pairs.forEach(
            { p -> parts.push(shown(p._0) + ": " + shown(p._1)) },
        );
        return "Dict(" + parts.join(", ") + ")";
    }

    pub fn at(self: Self<K, V>, key: K) -> ?V {
        // NOTE: written with `forEach` + accumulator rather than
        // `.at(0).map(…)` — chained method dispatch on a `?T` (option-map) is
        // not lowered yet (tracked in tasks/v0.beta.4 Part A: primitive/option
        // method dispatch). `.at(0)` here would type as array, not `?T`.
        var found: ?V = null;
        self.pairs.forEach({ p -> if (p._0 == key) found = p._1 });
        return found;
    }

    pub fn hasKey(self: Self<K, V>, key: K) -> bool {
        return self.pairs.filter({ p -> p._0 == key }).at(0) != null;
    }

    pub fn size(self: Self<K, V>) -> i32 {
        return self.pairs.length;
    }

    pub fn isEmpty(self: Self<K, V>) -> bool {
        return self.pairs.length == 0;
    }

    pub fn keys(self: Self<K, V>) -> Array<K> {
        return self.pairs.map({ p -> p._0 });
    }

    pub fn values(self: Self<K, V>) -> Array<V> {
        return self.pairs.map({ p -> p._1 });
    }

    pub fn insert(self: Self<K, V>, key: K, value: V) -> Dict<K, V> {
        val filtered = self.pairs.filter({ p -> p._0 != key });
        return Dict(pairs: filtered.append([#(key, value)]));
    }

    pub fn delete(self: Self<K, V>, key: K) -> Dict<K, V> {
        return Dict(pairs: self.pairs.filter({ p -> p._0 != key }));
    }

    // Right-biased merge: keys in both keep `other`'s value.
    pub fn merge(self: Self<K, V>, other: Dict<K, V>) -> Dict<K, V> {
        var out = self;
        other.pairs.forEach({ p ->
            out = out.insert(p._0, p._1);
        });
        return out;
    }

    pub fn fold<A>(
        self: Self<K, V>,
        initial: A,
        f: fn(acc: A, key: K, value: V) -> A,
    ) -> A {
        var acc = initial;
        self.pairs.forEach({ p ->
            acc = f(acc, p._0, p._1);
        });
        return acc;
    }

    pub fn mapValues<W>(self: Self<K, V>, f: fn(value: V) -> W) -> Dict<K, W> {
        var out: #(K, W)[] = [];
        self.pairs.forEach({ p -> out.push(#(p._0, f(p._1))) });
        return Dict(pairs: out);
    }

    pub fn empty() -> Dict<K, V> {
        return Dict(pairs: []);
    }

    // The dict of `entries`, inserted in order (decision 174): a key that
    // repeats keeps its LAST value, at the place of that last entry — what a
    // chain of `insert` answers. `Dict.ofEntries([])` is `Dict.empty()`.
    pub fn ofEntries(entries: Array<#(K, V)>) -> Dict<K, V> {
        var out: Dict<K, V> = Dict(pairs: []);
        entries.forEach({ e ->
            out = out.insert(e._0, e._1);
        });
        return out;
    }
}

// One key or value of `Dict.display`: a string quoted, anything else as it
// interpolates.
fn shown<T>(x: T) -> string {
    if (x is string) return "\"" + x + "\"";
    return "${x}";
}

test "dict displays as its pairs, a string quoted (decision 8 §7)" {
    val d = Dict.empty().insert("a", 1).insert("b", 2);
    assert d.display() == "Dict(\"a\": 1, \"b\": 2)";
    val n = Dict.empty().insert(1, "x");
    assert n.display() == "Dict(1: \"x\")";
}

test "dict ofEntries builds the dict of its entries, in order" {
    val d = Dict.ofEntries([#("a", 1), #("b", 2), #("c", 3)]);
    assert d.size() == 3;
    assert d.keys().join(",") == "a,b,c";
    assert d.at("b") ?? 0 == 2;
    assert d.at("z") ?? -1 == -1;
    assert d.display() == "Dict(\"a\": 1, \"b\": 2, \"c\": 3)";
}

test "dict ofEntries keeps the last value of a repeated key, as insert does" {
    val d = Dict.ofEntries([#("a", 1), #("b", 2), #("a", 3)]);
    val chained = Dict.empty().insert("a", 1).insert("b", 2).insert("a", 3);
    assert d.size() == 2;
    assert d.at("a") ?? 0 == 3;
    assert d.keys().join(",") == "b,a";
    assert d.display() == chained.display();
}

test "dict ofEntries of no entries is the empty dict, and takes any key type" {
    val none: Array<#(string, i32)> = [];
    assert Dict.ofEntries(none).isEmpty();
    val byNumber = Dict.ofEntries([#(1, "one"), #(2, "two")]);
    assert byNumber.at(2) ?? "" == "two";
    assert byNumber.insert(3, "three").size() == 3;
}

test "dict empty is empty" {
    val d = Dict.empty();
    assert d.isEmpty();
    assert d.size() == 0;
}

test "dict insert and at" {
    val d = Dict.empty().insert("a", 1);
    assert d.at("a") ?? 0 == 1;
    assert d.at("z") ?? -1 == -1;
}

test "dict pipeline: insert chain" {
    val d = Dict.empty().insert("x", 10).insert("y", 20).insert("z", 30);
    assert d.at("x") ?? 0 == 10;
    assert d.at("y") ?? 0 == 20;
    assert d.at("z") ?? 0 == 30;
}

test "dict hasKey" {
    val d = Dict.empty().insert("k", 99);
    assert d.hasKey("k");
    assert !d.hasKey("missing");
}

test "dict delete removes key" {
    val d = Dict.empty().insert("a", 1).insert("b", 2).delete("a");
    assert !d.hasKey("a");
    assert d.at("b") ?? 0 == 2;
}

test "dict insert overwrites duplicate" {
    val d = Dict.empty().insert("k", 1).insert("k", 99);
    assert d.size() == 1;
    assert d.at("k") ?? 0 == 99;
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
    assert m.at("k") ?? 0 == 99;
}

test "dict mapValues transforms values" {
    val d = Dict.empty().insert("a", 3).insert("b", 7);
    val doubled = d.mapValues({ v -> v * 2 });
    assert doubled.at("a") ?? 0 == 6;
    assert doubled.at("b") ?? 0 == 14;
}

// ── `??` over `at`'s `?V` (decision 330: `?T` has no methods) ──

test "?? returns the present value" {
    assert Dict.empty().insert("a", 42).at("a") ?? 0 == 42;
}

// ── empty-collection boundary (B1) ──

test "dict empty boundary: size 0, at misses" {
    val d: Dict<string, i32> = Dict.empty();
    assert d.size() == 0;
    assert !d.hasKey("anything");
    assert d.at("anything") ?? -1 == -1;
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
    pub fn contains(self: Self<T>, x: T) -> bool {
        return self.items.indexOf(x) != -1;
    }

    pub fn size(self: Self<T>) -> i32 {
        return self.items.length;
    }

    pub fn isEmpty(self: Self<T>) -> bool {
        return self.items.length == 0;
    }

    pub fn toList(self: Self<T>) -> Array<T> {
        return self.items;
    }

    pub fn insert(self: Self<T>, x: T) -> Set<T> {
        return if (self.items.indexOf(x) != -1)
            self
        else
            Set(items: self.items.append([x]));
    }

    pub fn delete(self: Self<T>, x: T) -> Set<T> {
        return Set(items: self.items.filter({ item -> item != x }));
    }

    pub fn union(self: Self<T>, other: Set<T>) -> Set<T> {
        var out = self;
        other.items.forEach({ x ->
            out = out.insert(x);
        });
        return out;
    }

    pub fn intersection(self: Self<T>, other: Set<T>) -> Set<T> {
        return Set(
            items: self.items.filter({ x -> other.items.indexOf(x) != -1 }),
        );
    }

    pub fn difference(self: Self<T>, other: Set<T>) -> Set<T> {
        return Set(
            items: self.items.filter({ x -> other.items.indexOf(x) == -1 }),
        );
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
    pub fn size(self: Self<T>) -> i32 {
        return self.items.length;
    }

    pub fn isEmpty(self: Self<T>) -> bool {
        return self.items.length == 0;
    }

    pub fn enqueue(self: Self<T>, item: T) -> Queue<T> {
        return Queue(items: self.items.append([item]));
    }

    pub fn dequeue(self: Self<T>) -> #(Queue<T>, ?T) {
        val head = self.items.at(0);
        val rest = self.items.slice(1, self.items.length);
        return #(Queue(items: rest), head);
    }

    pub fn peek(self: Self<T>) -> ?T {
        return self.items.at(0);
    }

    pub fn toList(self: Self<T>) -> Array<T> {
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
    assert q.peek() ?? -1 == 10;
}

test "queue dequeue returns front and rest" {
    val q = Queue.empty().enqueue(1).enqueue(2);
    val result = q.dequeue();
    val rest = result._0;
    val head = result._1;
    assert head ?? -1 == 1;
    assert rest.size() == 1;
    assert rest.peek() ?? -1 == 2;
}

test "queue dequeue empty yields no front item" {
    val result = Queue.empty().dequeue();
    val head = result._1;
    assert head ?? -99 == -99;
}

test "queue fifo order preserved" {
    val q = Queue.empty().enqueue(1).enqueue(2).enqueue(3);
    val r1 = q.dequeue();
    val r2 = r1._0.dequeue();
    val r3 = r2._0.dequeue();
    assert r1._1 ?? -1 == 1;
    assert r2._1 ?? -1 == 2;
    assert r3._1 ?? -1 == 3;
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
    assert q.peek() ?? -1 == -1;
    val r = q.dequeue();
    assert r._0.size() == 0;
    assert r._1 ?? -1 == -1;
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

// behavior Array
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
//   default fn range(...)
//   default fn repeat(...)
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
Array.range = function(start, stop) {
    return (() => { if ((start >= stop)) { return []; } else { const head = start; return [head, ...(Array.range((start + 1), stop))]; } })();
};
Array.repeat = function(value, times) {
    return (() => { if ((times <= 0)) { return []; } else { const head = value; return [head, ...(Array.repeat(value, (times - 1)))]; } })();
};
Array.prototype.slice = function(start, end) {
    if ((end != null)) { return ((__xs, __a, __e) => { const __n = __xs.length; if (__a == null) __a = 0; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return Array.from({ length: Math.max(__f - __b, 0) }, (_, __i) => __xs[__b + __i]); })(this, start, end); } else { return ((__xs, __a) => { const __n = __xs.length; if (__a == null) __a = 0; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return Array.from({ length: __n - __b }, (_, __i) => __xs[__b + __i]); })(this, start); }
};
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

    display() {
        let parts = [];
        this.pairs.forEach((p) => {
    return parts.push(((shown(p[0]) + ": ") + shown(p[1])));
});
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
        return new Dict(filtered.concat([[key, value]]));
    }

    delete(key) {
        return new Dict(this.pairs.filter((p) => {
    return (!__bp_eq(p[0], key, 0));
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

    static ofEntries(entries) {
        let out = new Dict([]);
        entries.forEach((e) => {
    out = out.insert(e[0], e[1]);
});
        return out;
    }
}
Dict.prototype.__bp = "Dict";
exports.Dict = Dict;

// One key or value of `Dict.display`: a string quoted, anything else as it

// interpolates.

function shown(x) {
    if (typeof x === "string") { return (("\"" + x) + "\""); }
    return ("" + x);
}

// ── `??` over `at`'s `?V` (decision 330: `?T` has no methods) ──

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
    return (!__bp_eq(item, x, 0));
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
    display(): string;
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
    ofEntries(entries: Array<[K, V]>): Dict<K, V>;
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
import {collections} from "std";

fn describe(o: Order) -> string {
    val s = case o {
        Lt -> "less";
        Gt -> "greater";
        _ -> "equal";
    };
    return s;
}

fn main() {
    @print(collections.toInt(collections.lt()));
    @print(describe(collections.reverse(collections.lt())));
}
```

----- JAVASCRIPT -- main.js
```javascript
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

const collections = require("./std/collections.js");

function describe(o) {
    const s = (() => {
        const _s = o;
        if (_s.tag === "Lt") return "less";
        if (_s.tag === "Gt") return "greater";
        return "equal";
    })();
    return s;
}

function main() {
    __bp_print(collections.toInt(collections.lt()));
    __bp_print(describe(collections.reverse(collections.lt())));
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

----- RUN LOG -----
```logs
-1
greater
```
