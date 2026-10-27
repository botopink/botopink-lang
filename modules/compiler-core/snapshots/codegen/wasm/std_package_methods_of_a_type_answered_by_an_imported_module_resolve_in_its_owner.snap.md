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

pub type Dict<K, V>(
    pairs: array<#(K, V)>,
) implement Index<K, V>, Display {
    // Decision 8 §7 — `Dict("a": 1, "b": 2)`: the pairs in order, a string
    // key or value quoted, anything else in its own text. `K` and `V` are
    // generic, so which is a string is asked of the value (`is`, decision 8 §4).
    pub fn display(self: Self<K, V>) -> string {
        var parts: string[] = [];
        for self.pairs { p ->
            parts.push(shown(p._0) + ": " + shown(p._1));
        }
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

    pub fn keys(self: Self<K, V>) -> array<K> {
        return self.pairs.map({ p -> p._0 });
    }

    pub fn values(self: Self<K, V>) -> array<V> {
        return self.pairs.map({ p -> p._1 });
    }

    pub fn insert(self: Self<K, V>, key: K, value: V) -> Dict<K, V> {
        val filtered = self.pairs.filter({ p -> p._0 != key });
        return Dict(pairs: filtered.append([#(key, value)]));
    }

    // Decision 340 — `insert(key, (at(key) ?? 0) + by)`: an integer `V`, an
    // absent key counting from 0. On a module `var`, `counts = counts.bump(k, n)`
    // is atomic on the BEAM as any `x = f(x)` is (decision 547 (ii)).
    pub fn bump(self: Self<K, V>, key: K, by: V) -> Dict<K, V> {
        return self.insert(key, (self.at(key) ?? 0) + by);
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
    pub fn ofEntries(entries: array<#(K, V)>) -> Dict<K, V> {
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
    val none: array<#(string, i32)> = [];
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
// `array<T>` (`items`). Pure botopink — no host backing. O(n) contains;
// membership by `==` over `any` (decision 210: records by value on every
// target; `indexOf` is the host's identity on commonJS and wasm).
//
// Instance operations are `self`-methods on the record; `empty`/`fromList`
// are type-scoped constructors (`Set.empty()`, `Set.fromList(xs)`). API
// naming note: `new`/`set` are keyword tokens — the constructor is `empty`.

pub type Set<T>(
    items: array<T>,
) {
    pub fn contains(self: Self<T>, x: T) -> bool {
        return self.items.any({ y -> y == x });
    }

    pub fn size(self: Self<T>) -> i32 {
        return self.items.length;
    }

    pub fn isEmpty(self: Self<T>) -> bool {
        return self.items.length == 0;
    }

    pub fn toList(self: Self<T>) -> array<T> {
        return self.items;
    }

    pub fn insert(self: Self<T>, x: T) -> Set<T> {
        return if (self.items.any({ y -> y == x }))
            self
        else
            Set(items: self.items.append([x]));
    }

    pub fn delete(self: Self<T>, x: T) -> Set<T> {
        return Set(items: self.items.filter({ item -> item != x }));
    }

    pub fn union(self: Self<T>, other: Set<T>) -> Set<T> {
        return Set(items: self.items.append(other.difference(self).items));
    }

    pub fn intersection(self: Self<T>, other: Set<T>) -> Set<T> {
        return Set(
            items: self.items.filter({ x -> other.contains(x) }),
        );
    }

    pub fn difference(self: Self<T>, other: Set<T>) -> Set<T> {
        return Set(
            items: self.items.filter({ x -> !other.contains(x) }),
        );
    }

    pub fn empty() -> Set<T> {
        return Set(items: []);
    }

    pub fn fromList(xs: array<T>) -> Set<T> {
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
// `Queue` (was `queue`) — Gleam-inspired — a `type Queue<T>` wrapping an `array<T>`
// (front at index 0). Pure botopink — no host backing. O(n) enqueue (copy),
// O(1) peek.
//
// Instance operations are `self`-methods on the record; `empty`/`fromList`
// are type-scoped constructors (`Queue.empty()`, `Queue.fromList(xs)`).
// `dequeue` returns `#(Queue<T>, ?T)` (the updated queue + the removed front
// item). API naming note: `new` is a keyword token —
// the constructor is `empty`.

pub type Queue<T>(
    items: array<T>,
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

    pub fn toList(self: Self<T>) -> array<T> {
        return self.items;
    }

    pub fn empty() -> Queue<T> {
        return Queue(items: []);
    }

    pub fn fromList(xs: array<T>) -> Queue<T> {
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

----- WASM TEXT -- std/collections.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $arr_i32 (array (mut i32)))
    (type $arr_f64 (array (mut f64)))
    (type $arr_any (sub (array (mut anyref))))
    (type $tuple (sub final $arr_any (array (mut anyref))))
    (type $box_i32 (sub (struct (field $v i32))))
    (type $box_i64 (struct (field $v i64)))
    (type $box_f64 (struct (field $v f64)))
    (type $box_bool (sub final $box_i32 (struct (field $v i32))))
    (type $box_big (struct (field $v (ref null $str))))
    (type $closure (sub (struct (field $fn funcref) (field $arity i32) (field $mark i32))))
    (type $result (struct (field $tag (mut i32)) (field $payload (mut anyref))))
    (type $exn (struct (field $msg (ref null $str)) (field $print i32)))
    (type $task (struct (field $state (mut i32)) (field $waiters (mut (ref null $waiter))) (field $value (mut anyref)) (field $frame (mut structref)) (field $kind i32) (field $next (mut (ref null $task))) (field $aux (mut anyref)) (field $left (mut i32))))
    (type $waiter (struct (field $next (mut (ref null $waiter))) (field $kind i32) (field $target (ref null $task)) (field $slot i32)))
    (type $hostn (struct (field $next (mut (ref null $hostn))) (field $h i32) (field $t (ref null $task))))
    (type $gen (struct (field $state (mut i32)) (field $kind i32) (field $frame (mut structref)) (field $value (mut anyref)) (field $src (mut (ref null $gen))) (field $aux (mut anyref)) (field $left (mut i32))))
    (type $cell (struct (field $filled (mut i32)) (field $value (mut anyref))))
    (type $__decl (sub (struct (field $ti (ref null $__tinfo)))))
    (type $__tinfo (struct (field $name (ref null $str)) (field $print funcref) (field $eq funcref) (field $display funcref) (field $kind i32)))
    (type $__print_sig (func (param anyref)))
    (type $__eq_sig (func (param anyref anyref) (result i32)))
    (type $sig_0 (func (param (ref null $closure)) (result anyref)))
    (type $sig_1 (func (param (ref null $closure) anyref) (result anyref)))
    (type $sig_2 (func (param (ref null $closure) anyref anyref) (result anyref)))
    (type $sig_3 (func (param (ref null $closure) anyref anyref anyref) (result anyref)))
    (type $sig_4 (func (param (ref null $closure) anyref anyref anyref anyref) (result anyref)))
    (type $sig_5 (func (param (ref null $closure) anyref anyref anyref anyref anyref) (result anyref)))
    (type $sig_6 (func (param (ref null $closure) anyref anyref anyref anyref anyref anyref) (result anyref)))
    (type $sig_7 (func (param (ref null $closure) anyref anyref anyref anyref anyref anyref anyref) (result anyref)))
    (type $sig_8 (func (param (ref null $closure) anyref anyref anyref anyref anyref anyref anyref anyref) (result anyref)))
  )
  (rec
    (type $rec_Dict (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut (ref null $arr_any))))))
    (type $brand_rec_Dict (struct (field i64) (field i32) (field f32) (field f32) (field f64) (field i32) (field f64) (field i64) (field f32) (field f32) (field f64) (field i64) (field f32) (field f32) (field i32) (field i64) (field f64) (field f32) (field f64) (field i32) (field f64) (field i64) (field f64) (field i64) (field f64) (field i32) (field f32) (field i64) (field i64) (field i32) (field f32) (field i32)))
  )
  (rec
    (type $rec_Queue (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut (ref null $arr_any))))))
    (type $brand_rec_Queue (struct (field i64) (field f32) (field i64) (field i64) (field f32) (field f64) (field f64) (field f64) (field f32) (field i64) (field f64) (field i64) (field i32) (field f64) (field i64) (field f64) (field f64) (field i32) (field i64) (field f32) (field f64) (field i64) (field i64) (field i64) (field f64) (field f32) (field i32) (field f32) (field f32) (field f32) (field i32) (field f64)))
  )
  (rec
    (type $rec_Set (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut (ref null $arr_any))))))
    (type $brand_rec_Set (struct (field i32) (field f64) (field i32) (field i32) (field i32) (field i64) (field f64) (field i64) (field f64) (field i32) (field f32) (field f64) (field i32) (field i32) (field i32) (field i32) (field f64) (field i64) (field i32) (field f32) (field f64) (field f32) (field i64) (field f64) (field i32) (field i64) (field f64) (field i64) (field f64) (field i64) (field f64) (field f64)))
  )
  (import "std@__rt" "__ti_register" (func $__ti_register (param structref)))
  (import "std@__rt" "__eq_decl" (func $__eq_decl (param anyref anyref) (result i32)))
  (import "std@__rt" "__write_bytes" (func $__write_bytes (param i32 i32)))
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (global $__cap (import "std@__rt" "__cap") (mut arrayref))
  (global $__cap_depth (import "std@__rt" "__cap_depth") (mut i32))
  (import "std@__rt" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  ;; std/collections — the four collection types, one namespace each (decision
  ;; 106): `Dict<K, V>`, `Set<T>`, `Queue<T>` and `Order`. Was the four modules
  ;; `dict`, `sets`, `queue` and `order`; the type is the namespace now, so a
  ;; constructor is called on the type it builds (decision 111) —
  ;; `Dict.empty()` / `Dict.ofEntries(entries)`, `Set.empty()` /
  ;; `Set.fromList(xs)`, `Queue.empty()` / `Queue.fromList(xs)` — and every
  ;; other function keeps its name.
  ;; ── Dict<K, V> ──────────────────────────────────────────────────────────────
  ;; `Dict` (was `dict`) — Gleam-inspired — a `type Dict<K, V>` wrapping an
  ;; association list `pairs: array<#(K, V)>` for full backend portability
  ;; (no host-backing). O(n) read; camelCase convention.
  ;; 
  ;; Instance operations are `self`-methods on the record; `empty` is a
  ;; type-scoped constructor, `Dict.empty()` (records hold state and are
  ;; constructed — unlike interfaces, which are pure behaviour contracts).
  ;; 
  ;; `==` / `!=` on generic K uses structural equality (string/numeric keys —
  ;; the common case). API naming note: `new`/`get` are keyword tokens — use
  ;; `empty`/`at`.
  ;; 
  ;; `Dict<K, V>` answers the ambient `Index<K, V>` of `primitives.bp`
  ;; (decision 63, amended), which is what makes `d["k"]` legal: the index
  ;; expression has no typing rule of its own and rewrites to `d.at("k")`. The
  ;; reader was spelled `lookup` until that amendment gave every indexable type
  ;; one method name.
  (func $Dict_display (param $self (ref null $rec_Dict)) (result (ref null $str))
    (local $__mem0 i32)
    (local $parts (ref null $arr_any))
    (local $p i32)
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $p__sh0 (ref null $arr_any))
    array.new_fixed $arr_any 0
    local.set $parts
    local.get $self
    struct.get $rec_Dict $f0
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
    ref.cast (ref null $arr_any)
        local.set $p__sh0
    local.get $parts
    local.get $p__sh0
    i32.const 0
    array.get $arr_any
    call $shown
    global.get $__s0
    call $__str_concat
    local.get $p__sh0
    i32.const 1
    array.get $arr_any
    call $shown
    call $__str_concat
    call $__arr_push_any
    local.set $parts
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    i32.const 0
    drop
    global.get $__s1
    local.get $parts
    global.get $__s2
    call $__arr_join_any
    call $__str_concat
    global.get $__s3
    call $__str_concat
    return
  )
  (func $Dict_at (param $self (ref null $rec_Dict)) (param $key anyref) (result anyref)
    (local $found anyref)
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $p (ref null $arr_any))
    ref.null any
    local.set $found
    local.get $self
    struct.get $rec_Dict $f0
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
    ref.cast (ref null $arr_any)
        local.set $p
    local.get $p
    i32.const 0
    array.get $arr_any
    local.get $key
    call $__unk_eq
    (if (result i32)
      (then
    local.get $p
    i32.const 1
    array.get $arr_any
    local.set $found
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $found
    return
  )
  (func $Dict_hasKey (param $self (ref null $rec_Dict)) (param $key anyref) (result i32)
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $p (ref null $arr_any))
    (local $__out0 (ref null $arr_any))
    local.get $self
    struct.get $rec_Dict $f0
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    array.new_default $arr_any
    local.set $__out0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
    ref.cast (ref null $arr_any)
        local.set $p
    local.get $p
    i32.const 0
    array.get $arr_any
    local.get $key
    call $__unk_eq
    (if
      (then
    local.get $__out0
    local.get $__acc0
    local.get $__iter0
    local.get $__idx0
    array.get $arr_any
    array.set $arr_any
    local.get $__acc0
    i32.const 1
    i32.add
    local.set $__acc0
      )
    )
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $__out0
    i32.const 0
    local.get $__acc0
    call $__arr_slice_any
    i32.const 0
    call $__arr_at_opt_any
    ref.is_null
    i32.eqz
    return
  )
  (func $Dict_size (param $self (ref null $rec_Dict)) (result i32)
    local.get $self
    struct.get $rec_Dict $f0
    array.len
    return
  )
  (func $Dict_isEmpty (param $self (ref null $rec_Dict)) (result i32)
    local.get $self
    struct.get $rec_Dict $f0
    array.len
    i32.const 0
    i32.eq
    return
  )
  (func $Dict_keys (param $self (ref null $rec_Dict)) (result (ref null $arr_any))
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $p (ref null $arr_any))
    (local $__out0 (ref null $arr_any))
    local.get $self
    struct.get $rec_Dict $f0
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    array.new_default $arr_any
    local.set $__out0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
    ref.cast (ref null $arr_any)
        local.set $p
    local.get $__out0
    local.get $__idx0
    local.get $p
    i32.const 0
    array.get $arr_any
    array.set $arr_any
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $__out0
    return
  )
  (func $Dict_values (param $self (ref null $rec_Dict)) (result (ref null $arr_any))
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $p (ref null $arr_any))
    (local $__out0 (ref null $arr_any))
    local.get $self
    struct.get $rec_Dict $f0
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    array.new_default $arr_any
    local.set $__out0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
    ref.cast (ref null $arr_any)
        local.set $p
    local.get $__out0
    local.get $__idx0
    local.get $p
    i32.const 1
    array.get $arr_any
    array.set $arr_any
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $__out0
    return
  )
  (func $Dict_insert (param $self (ref null $rec_Dict)) (param $key anyref) (param $value anyref) (result (ref null $rec_Dict))
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $filtered (ref null $arr_any))
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $p (ref null $arr_any))
    (local $__out0 (ref null $arr_any))
    local.get $self
    struct.get $rec_Dict $f0
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    array.new_default $arr_any
    local.set $__out0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
    ref.cast (ref null $arr_any)
        local.set $p
    local.get $p
    i32.const 0
    array.get $arr_any
    local.get $key
    call $__unk_eq
    i32.eqz
    (if
      (then
    local.get $__out0
    local.get $__acc0
    local.get $__iter0
    local.get $__idx0
    array.get $arr_any
    array.set $arr_any
    local.get $__acc0
    i32.const 1
    i32.add
    local.set $__acc0
      )
    )
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $__out0
    i32.const 0
    local.get $__acc0
    call $__arr_slice_any
    local.set $filtered
    local.get $filtered
    local.get $key
    local.get $value
    array.new_fixed $tuple 2
    array.new_fixed $arr_any 1
    call $__arr_concat_any
    call $__new_31
    return
  )
  (func $Dict_bump (param $self (ref null $rec_Dict)) (param $key anyref) (param $by anyref) (result (ref null $rec_Dict))
    (local $__bp_nullish i32)
    (local $__opt0 anyref)
    local.get $self
    local.get $key
    local.get $self
    local.get $key
    call $Dict_at
    local.tee $__opt0
    ref.is_null
    i32.eqz
    (if (result i32)
      (then
    local.get $__opt0
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $__bp_nullish
    local.get $__bp_nullish
      )
      (else
    i32.const 0
      )
    )
    local.get $by
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    global.get $__s4
    call $__i32_add_chk
    struct.new $box_i32
    call $Dict_insert
    return
  )
  (func $Dict_delete (param $self (ref null $rec_Dict)) (param $key anyref) (result (ref null $rec_Dict))
    (local $__mem0 i32)
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $p (ref null $arr_any))
    (local $__out0 (ref null $arr_any))
    local.get $self
    struct.get $rec_Dict $f0
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    array.new_default $arr_any
    local.set $__out0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
    ref.cast (ref null $arr_any)
        local.set $p
    local.get $p
    i32.const 0
    array.get $arr_any
    local.get $key
    call $__unk_eq
    i32.eqz
    (if
      (then
    local.get $__out0
    local.get $__acc0
    local.get $__iter0
    local.get $__idx0
    array.get $arr_any
    array.set $arr_any
    local.get $__acc0
    i32.const 1
    i32.add
    local.set $__acc0
      )
    )
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $__out0
    i32.const 0
    local.get $__acc0
    call $__arr_slice_any
    call $__new_31
    return
  )
  (func $Dict_merge (param $self (ref null $rec_Dict)) (param $other (ref null $rec_Dict)) (result (ref null $rec_Dict))
    (local $out (ref null $rec_Dict))
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $p (ref null $arr_any))
    local.get $self
    local.set $out
    local.get $other
    struct.get $rec_Dict $f0
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
    ref.cast (ref null $arr_any)
        local.set $p
    local.get $out
    local.get $p
    i32.const 0
    array.get $arr_any
    local.get $p
    i32.const 1
    array.get $arr_any
    call $Dict_insert
    local.set $out
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $out
    return
  )
  (func $Dict_fold (param $self (ref null $rec_Dict)) (param $initial anyref) (param $f (ref null $closure)) (result anyref)
    (local $acc anyref)
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $p (ref null $arr_any))
    (local $__fnv1 (ref null $closure))
    local.get $initial
    local.set $acc
    local.get $self
    struct.get $rec_Dict $f0
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
    ref.cast (ref null $arr_any)
        local.set $p
    local.get $f
    local.set $__fnv1
    local.get $__fnv1
    local.get $acc
    local.get $p
    i32.const 0
    array.get $arr_any
    local.get $p
    i32.const 1
    array.get $arr_any
    local.get $__fnv1
    struct.get $closure $fn ;; the entry
    ref.cast (ref null $sig_3)
    call_ref $sig_3
    local.set $acc
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $acc
    return
  )
  (func $Dict_mapValues (param $self (ref null $rec_Dict)) (param $f (ref null $closure)) (result (ref null $rec_Dict))
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $out (ref null $arr_any))
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $p (ref null $arr_any))
    (local $__fnv1 (ref null $closure))
    array.new_fixed $arr_any 0
    local.set $out
    local.get $self
    struct.get $rec_Dict $f0
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
    ref.cast (ref null $arr_any)
        local.set $p
    local.get $out
    local.get $p
    i32.const 0
    array.get $arr_any
    local.get $f
    local.set $__fnv1
    local.get $__fnv1
    local.get $p
    i32.const 1
    array.get $arr_any
    local.get $__fnv1
    struct.get $closure $fn ;; the entry
    ref.cast (ref null $sig_1)
    call_ref $sig_1
    array.new_fixed $tuple 2
    call $__arr_push_any
    local.set $out
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $out
    call $__new_31
    return
  )
  (func $Dict_empty (result (ref null $rec_Dict))
    (local $__mem0 i32)
    (local $__mem1 i32)
    i32.const 0
    array.new_default $arr_any
    call $__new_31
    return
  )
  (func $Dict_ofEntries (param $entries (ref null $arr_any)) (result (ref null $rec_Dict))
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $out (ref null $rec_Dict))
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $e (ref null $arr_any))
    i32.const 0
    array.new_default $arr_any
    call $__new_31
    local.set $out
    local.get $entries
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
    ref.cast (ref null $arr_any)
        local.set $e
    local.get $out
    local.get $e
    i32.const 0
    array.get $arr_any
    local.get $e
    i32.const 1
    array.get $arr_any
    call $Dict_insert
    local.set $out
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $out
    return
  )
  ;; One key or value of `Dict.display`: a string quoted, anything else as it
  ;; interpolates.
  (func $shown (param $x anyref) (result (ref null $str))
    (local $__gc0 anyref)
    (local $__gc1 (ref null $str))
    (local $__gc2 (ref null $str))
    local.get $x
    local.tee $__gc0
    ref.test (ref null $str)
    local.get $__gc0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    global.get $__s5
    call $__cap_begin
    local.set $__gc1
    local.get $x
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    call $__print_i32_raw
    local.get $__gc1
    call $__cap_end
    call $__str_concat
    global.get $__s5
    call $__str_concat
    return
      )
      (else
        ref.null $str
      )
    )
    drop
    global.get $__s6
    call $__cap_begin
    local.set $__gc2
    local.get $x
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    call $__print_i32_raw
    local.get $__gc2
    call $__cap_end
    call $__str_concat
    return
  )
  ;; ── `??` over `at`'s `?V` (decision 330: `?T` has no methods) ──
  ;; ── empty-collection boundary (B1) ──
  ;; ── Set<T> ──────────────────────────────────────────────────────────────────
  ;; `Set` (was `sets`) — Gleam-inspired — a `type Set<T>` wrapping a deduplicated
  ;; `array<T>` (`items`). Pure botopink — no host backing. O(n) contains;
  ;; membership by `==` over `any` (decision 210: records by value on every
  ;; target; `indexOf` is the host's identity on commonJS and wasm).
  ;; 
  ;; Instance operations are `self`-methods on the record; `empty`/`fromList`
  ;; are type-scoped constructors (`Set.empty()`, `Set.fromList(xs)`). API
  ;; naming note: `new`/`set` are keyword tokens — the constructor is `empty`.
  (func $Set_contains (param $self (ref null $rec_Set)) (param $x anyref) (result i32)
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $y anyref)
    local.get $self
    struct.get $rec_Set $f0
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
        local.set $y
    local.get $y
    local.get $x
    call $__unk_eq
    (if
      (then
    i32.const 1
    local.set $__acc0
      )
    )
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $__acc0
    return
  )
  (func $Set_size (param $self (ref null $rec_Set)) (result i32)
    local.get $self
    struct.get $rec_Set $f0
    array.len
    return
  )
  (func $Set_isEmpty (param $self (ref null $rec_Set)) (result i32)
    local.get $self
    struct.get $rec_Set $f0
    array.len
    i32.const 0
    i32.eq
    return
  )
  (func $Set_toList (param $self (ref null $rec_Set)) (result (ref null $arr_any))
    local.get $self
    struct.get $rec_Set $f0
    return
  )
  (func $Set_insert (param $self (ref null $rec_Set)) (param $x anyref) (result (ref null $rec_Set))
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $y anyref)
    local.get $self
    struct.get $rec_Set $f0
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
        local.set $y
    local.get $y
    local.get $x
    call $__unk_eq
    (if
      (then
    i32.const 1
    local.set $__acc0
      )
    )
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $__acc0
    (if (result (ref null $rec_Set))
      (then
    local.get $self
      )
      (else
    local.get $self
    struct.get $rec_Set $f0
    local.get $x
    array.new_fixed $arr_any 1
    call $__arr_concat_any
    call $__new_35
      )
    )
    return
  )
  (func $Set_delete (param $self (ref null $rec_Set)) (param $x anyref) (result (ref null $rec_Set))
    (local $__mem0 i32)
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $item anyref)
    (local $__out0 (ref null $arr_any))
    local.get $self
    struct.get $rec_Set $f0
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    array.new_default $arr_any
    local.set $__out0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
        local.set $item
    local.get $item
    local.get $x
    call $__unk_eq
    i32.eqz
    (if
      (then
    local.get $__out0
    local.get $__acc0
    local.get $__iter0
    local.get $__idx0
    array.get $arr_any
    array.set $arr_any
    local.get $__acc0
    i32.const 1
    i32.add
    local.set $__acc0
      )
    )
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $__out0
    i32.const 0
    local.get $__acc0
    call $__arr_slice_any
    call $__new_35
    return
  )
  (func $Set_union (param $self (ref null $rec_Set)) (param $other (ref null $rec_Set)) (result (ref null $rec_Set))
    (local $__mem0 i32)
    local.get $self
    struct.get $rec_Set $f0
    local.get $other
    local.get $self
    call $Set_difference
    struct.get $rec_Set $f0
    call $__arr_concat_any
    call $__new_35
    return
  )
  (func $Set_intersection (param $self (ref null $rec_Set)) (param $other (ref null $rec_Set)) (result (ref null $rec_Set))
    (local $__mem0 i32)
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $x anyref)
    (local $__out0 (ref null $arr_any))
    local.get $self
    struct.get $rec_Set $f0
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    array.new_default $arr_any
    local.set $__out0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
        local.set $x
    local.get $other
    local.get $x
    call $Set_contains
    (if
      (then
    local.get $__out0
    local.get $__acc0
    local.get $__iter0
    local.get $__idx0
    array.get $arr_any
    array.set $arr_any
    local.get $__acc0
    i32.const 1
    i32.add
    local.set $__acc0
      )
    )
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $__out0
    i32.const 0
    local.get $__acc0
    call $__arr_slice_any
    call $__new_35
    return
  )
  (func $Set_difference (param $self (ref null $rec_Set)) (param $other (ref null $rec_Set)) (result (ref null $rec_Set))
    (local $__mem0 i32)
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $x anyref)
    (local $__out0 (ref null $arr_any))
    local.get $self
    struct.get $rec_Set $f0
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    array.new_default $arr_any
    local.set $__out0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
        local.set $x
    local.get $other
    local.get $x
    call $Set_contains
    i32.eqz
    (if
      (then
    local.get $__out0
    local.get $__acc0
    local.get $__iter0
    local.get $__idx0
    array.get $arr_any
    array.set $arr_any
    local.get $__acc0
    i32.const 1
    i32.add
    local.set $__acc0
      )
    )
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $__out0
    i32.const 0
    local.get $__acc0
    call $__arr_slice_any
    call $__new_35
    return
  )
  (func $Set_empty (result (ref null $rec_Set))
    (local $__mem0 i32)
    (local $__mem1 i32)
    i32.const 0
    array.new_default $arr_any
    call $__new_35
    return
  )
  (func $Set_fromList (param $xs (ref null $arr_any)) (result (ref null $rec_Set))
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $out (ref null $rec_Set))
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $x anyref)
    i32.const 0
    array.new_default $arr_any
    call $__new_35
    local.set $out
    local.get $xs
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
        local.set $x
    local.get $out
    local.get $x
    call $Set_insert
    local.set $out
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $out
    return
  )
  ;; ── empty-collection boundary (B1) ──
  ;; ── Queue<T> ────────────────────────────────────────────────────────────────
  ;; `Queue` (was `queue`) — Gleam-inspired — a `type Queue<T>` wrapping an `array<T>`
  ;; (front at index 0). Pure botopink — no host backing. O(n) enqueue (copy),
  ;; O(1) peek.
  ;; 
  ;; Instance operations are `self`-methods on the record; `empty`/`fromList`
  ;; are type-scoped constructors (`Queue.empty()`, `Queue.fromList(xs)`).
  ;; `dequeue` returns `#(Queue<T>, ?T)` (the updated queue + the removed front
  ;; item). API naming note: `new` is a keyword token —
  ;; the constructor is `empty`.
  (func $Queue_size (param $self (ref null $rec_Queue)) (result i32)
    local.get $self
    struct.get $rec_Queue $f0
    array.len
    return
  )
  (func $Queue_isEmpty (param $self (ref null $rec_Queue)) (result i32)
    local.get $self
    struct.get $rec_Queue $f0
    array.len
    i32.const 0
    i32.eq
    return
  )
  (func $Queue_enqueue (param $self (ref null $rec_Queue)) (param $item anyref) (result (ref null $rec_Queue))
    (local $__mem0 i32)
    (local $__mem1 i32)
    local.get $self
    struct.get $rec_Queue $f0
    local.get $item
    array.new_fixed $arr_any 1
    call $__arr_concat_any
    call $__new_33
    return
  )
  (func $Queue_dequeue (param $self (ref null $rec_Queue)) (result (ref null $arr_any))
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $head anyref)
    (local $rest (ref null $arr_any))
    local.get $self
    struct.get $rec_Queue $f0
    i32.const 0
    call $__arr_at_opt_any
    local.set $head
    local.get $self
    struct.get $rec_Queue $f0
    i32.const 1
    local.get $self
    struct.get $rec_Queue $f0
    array.len
    call $__arr_slice_any
    local.set $rest
    local.get $rest
    call $__new_33
    local.get $head
    array.new_fixed $tuple 2
    return
  )
  (func $Queue_peek (param $self (ref null $rec_Queue)) (result anyref)
    local.get $self
    struct.get $rec_Queue $f0
    i32.const 0
    call $__arr_at_opt_any
    return
  )
  (func $Queue_toList (param $self (ref null $rec_Queue)) (result (ref null $arr_any))
    local.get $self
    struct.get $rec_Queue $f0
    return
  )
  (func $Queue_empty (result (ref null $rec_Queue))
    (local $__mem0 i32)
    (local $__mem1 i32)
    i32.const 0
    array.new_default $arr_any
    call $__new_33
    return
  )
  (func $Queue_fromList (param $xs (ref null $arr_any)) (result (ref null $rec_Queue))
    (local $__mem0 i32)
    local.get $xs
    call $__new_33
    return
  )
  ;; ── empty-collection boundary (B1) ──
  ;; ── Order ───────────────────────────────────────────────────────────────────
  ;; `Order` (was `order`) — Gleam-style, inspired by `gleam/order`. A sum type — the
  ;; `type Order` (type-exported to importers) plus companion functions.
  ;; Construct via the module fns (`collections.lt()`); `toInt`/`reverse` operate on
  ;; an `Order`. Enums are concrete types, not interfaces.
  (func $lt (export "lt") (result i32)
    i32.const 0 ;; Order.Lt
    return
  )
  (func $eq (export "eq") (result i32)
    i32.const 1 ;; Order.Eq
    return
  )
  (func $gt (export "gt") (result i32)
    i32.const 2 ;; Order.Gt
    return
  )
  (func $toInt (export "toInt") (param $o i32) (result i32)
    (local $n i32)
    (local $__case_0 i32)
    local.get $o
    local.set $__case_0
    local.get $__case_0
    i32.const 0 ;; Lt
    i32.eq
    (if (result i32)
      (then
    i32.const 0
    i32.const 1
    global.get $__s7
    call $__i32_sub_chk
      )
      (else
    local.get $__case_0
    i32.const 1 ;; Eq
    i32.eq
    (if (result i32)
      (then
    i32.const 0
      )
      (else
    i32.const 1
      )
    )
      )
    )
    local.set $n
    local.get $n
    return
  )
  (func $reverse (export "reverse") (param $o i32) (result i32)
    (local $r i32)
    (local $__case_0 i32)
    local.get $o
    local.set $__case_0
    local.get $__case_0
    i32.const 0 ;; Lt
    i32.eq
    (if (result i32)
      (then
    i32.const 2 ;; Order.Gt
      )
      (else
    local.get $__case_0
    i32.const 2 ;; Gt
    i32.eq
    (if (result i32)
      (then
    i32.const 0 ;; Order.Lt
      )
      (else
    i32.const 1 ;; Order.Eq
      )
    )
      )
    )
    local.set $r
    local.get $r
    return
  )
  (func $__arr_push_any (param $xs (ref null $arr_any)) (param $x anyref) (result (ref null $arr_any))
    (local $n i32)
    (local $r (ref null $arr_any))
    local.get $xs
    array.len
    local.set $n
    local.get $n
    i32.const 1
    i32.add
    array.new_default $arr_any
    local.set $r
    local.get $r
    i32.const 0
    local.get $xs
    i32.const 0
    local.get $n
    array.copy $arr_any $arr_any
    local.get $r
    local.get $n
    local.get $x
    array.set $arr_any
    local.get $r
  )
  (func $__arr_join_any (param $xs (ref null $arr_any)) (param $sep (ref null $str)) (result (ref null $str))
    (local $n i32)
    (local $i i32)
    (local $acc (ref null $str))
    local.get $xs
    array.len
    local.set $n
    i32.const 0
    array.new_default $str
    local.set $acc
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $i
    (if
      (then
    local.get $acc
    local.get $sep
    call $__str_concat
    local.set $acc
      )
    )
    local.get $acc
    local.get $xs
    local.get $i
    array.get $arr_any
    ref.cast (ref null $str)
    call $__str_concat
    local.set $acc
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    local.get $acc
  )
  (func $__unk_is_num (param $v anyref) (result i32)
    local.get $v
    ref.is_null
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $v
    ref.test (ref null $box_i32)
    local.get $v
    ref.test (ref null $box_bool)
    i32.eqz
    i32.and
    local.get $v
    ref.test (ref null $box_f64)
    i32.or
  )
  (func $__unk_as_f64 (param $v anyref) (result f64)
    local.get $v
    ref.test (ref null $box_i32)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    f64.convert_i32_s
    return
      )
    )
    local.get $v
    ref.cast (ref null $box_f64)
    struct.get $box_f64 $v
  )
  (func $__unk_eq (param $a anyref) (param $b anyref) (result i32)
    local.get $a
    call $__unk_is_num
    local.get $b
    call $__unk_is_num
    i32.and
    (if
      (then
    local.get $a
    call $__unk_as_f64
    local.get $b
    call $__unk_as_f64
    f64.eq
    return
      )
    )
    local.get $a
    ref.test (ref null $str)
    local.get $a
    ref.is_null
    i32.eqz
    i32.and
    local.get $b
    ref.test (ref null $str)
    i32.and
    local.get $b
    ref.is_null
    i32.eqz
    i32.and
    (if
      (then
    local.get $a
    ref.cast (ref null $str)
    local.get $b
    ref.cast (ref null $str)
    call $__str_eq
    return
      )
    )
    local.get $a
    ref.test (ref null $box_bool)
    local.get $a
    ref.is_null
    i32.eqz
    i32.and
    local.get $b
    ref.test (ref null $box_bool)
    i32.and
    local.get $b
    ref.is_null
    i32.eqz
    i32.and
    (if
      (then
    local.get $a
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.get $b
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    i32.eq
    return
      )
    )
    local.get $a
    local.get $b
    call $__unk_eq_ref
  )
  (func $__arr_slice_any (param $xs (ref null $arr_any)) (param $a i32) (param $b i32) (result (ref null $arr_any))
    (local $len i32)
    (local $from i32)
    (local $to i32)
    (local $n i32)
    (local $r (ref null $arr_any))
    local.get $xs
    array.len
    local.set $len
    local.get $a
    i32.const 0
    i32.lt_s
    (if
      (then
    local.get $len
    local.get $a
    i32.add
    local.set $from
    local.get $from
    i32.const 0
    i32.lt_s
    (if
      (then
    i32.const 0
    local.set $from
      )
    )
      )
      (else
    local.get $a
    local.set $from
    local.get $from
    local.get $len
    i32.gt_s
    (if
      (then
    local.get $len
    local.set $from
      )
    )
      )
    )
    local.get $b
    i32.const 0
    i32.lt_s
    (if
      (then
    local.get $len
    local.get $b
    i32.add
    local.set $to
    local.get $to
    i32.const 0
    i32.lt_s
    (if
      (then
    i32.const 0
    local.set $to
      )
    )
      )
      (else
    local.get $b
    local.set $to
    local.get $to
    local.get $len
    i32.gt_s
    (if
      (then
    local.get $len
    local.set $to
      )
    )
      )
    )
    local.get $to
    local.get $from
    i32.sub
    local.set $n
    local.get $n
    i32.const 0
    i32.lt_s
    (if
      (then
    i32.const 0
    local.set $n
      )
    )
    local.get $n
    array.new_default $arr_any
    local.set $r
    local.get $r
    i32.const 0
    local.get $xs
    local.get $from
    local.get $n
    array.copy $arr_any $arr_any
    local.get $r
  )
  (func $__arr_at_opt_any (param $xs (ref null $arr_any)) (param $i i32) (result anyref)
    local.get $i
    i32.const 0
    i32.lt_s
    (if
      (then
    local.get $i
    local.get $xs
    array.len
    i32.add
    local.set $i
      )
    )
    local.get $i
    i32.const 0
    i32.lt_s
    local.get $i
    local.get $xs
    array.len
    i32.ge_s
    i32.or
    (if (result anyref)
      (then
    ref.null any
      )
      (else
    local.get $xs
    local.get $i
    array.get $arr_any
      )
    )
  )
  (func $__arr_concat_any (param $xs (ref null $arr_any)) (param $ys (ref null $arr_any)) (result (ref null $arr_any))
    (local $la i32)
    (local $lb i32)
    (local $r (ref null $arr_any))
    local.get $xs
    array.len
    local.set $la
    local.get $ys
    array.len
    local.set $lb
    local.get $la
    local.get $lb
    i32.add
    array.new_default $arr_any
    local.set $r
    local.get $r
    i32.const 0
    local.get $xs
    i32.const 0
    local.get $la
    array.copy $arr_any $arr_any
    local.get $r
    local.get $la
    local.get $ys
    i32.const 0
    local.get $lb
    array.copy $arr_any $arr_any
    local.get $r
  )
  (func $__tie2 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $rec_Dict)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    local.get $b
    call $__unk_eq_ref
  )
  (func $__tie10 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $rec_Set)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    local.get $b
    call $__unk_eq_ref
  )
  (func $__tie11 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $rec_Queue)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    local.get $b
    call $__unk_eq_ref
  )
  (func $__unk_eq_tuple (param $a (ref null $tuple)) (param $b (ref null $tuple)) (result i32)
    (local $i i32)
    local.get $a
    array.len
    local.get $b
    array.len
    i32.ne
    (if
      (then
    i32.const 0
    return
      )
    )
    (block $brk
    (loop $cont
    local.get $i
    local.get $a
    array.len
    i32.ge_u
    br_if $brk
    local.get $a
    local.get $i
    array.get $tuple
    local.get $b
    local.get $i
    array.get $tuple
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    i32.const 1
  )
  (func $__unk_eq_arr_any (param $a (ref null $arr_any)) (param $b (ref null $arr_any)) (result i32)
    (local $i i32)
    local.get $a
    array.len
    local.get $b
    array.len
    i32.ne
    (if
      (then
    i32.const 0
    return
      )
    )
    (block $brk
    (loop $cont
    local.get $i
    local.get $a
    array.len
    i32.ge_u
    br_if $brk
    local.get $a
    local.get $i
    array.get $arr_any
    local.get $b
    local.get $i
    array.get $arr_any
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    i32.const 1
  )
  (func $__unk_eq_s2 (param $a (ref null $rec_Dict)) (param $b (ref null $rec_Dict)) (result i32)
    local.get $a
    struct.get $rec_Dict $f0
    local.get $b
    struct.get $rec_Dict $f0
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    i32.const 1
  )
  (func $__unk_eq_s10 (param $a (ref null $rec_Set)) (param $b (ref null $rec_Set)) (result i32)
    local.get $a
    struct.get $rec_Set $f0
    local.get $b
    struct.get $rec_Set $f0
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    i32.const 1
  )
  (func $__unk_eq_s11 (param $a (ref null $rec_Queue)) (param $b (ref null $rec_Queue)) (result i32)
    local.get $a
    struct.get $rec_Queue $f0
    local.get $b
    struct.get $rec_Queue $f0
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    i32.const 1
  )
  (func $__unk_eq_ref (param $a anyref) (param $b anyref) (result i32)
    local.get $a
    ref.is_null
    local.get $b
    ref.is_null
    i32.or
    (if
      (then
    local.get $a
    ref.is_null
    local.get $b
    ref.is_null
    i32.and
    return
      )
    )
    local.get $a
    ref.cast (ref null eq)
    local.get $b
    ref.cast (ref null eq)
    ref.eq
    (if
      (then
    i32.const 1
    return
      )
    )
    local.get $a
    ref.test (ref null $tuple)
    (if
      (then
    local.get $b
    ref.test (ref null $tuple)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $tuple)
    local.get $b
    ref.cast (ref null $tuple)
    call $__unk_eq_tuple
    return
      )
    )
    local.get $a
    ref.test (ref null $arr_any)
    (if
      (then
    local.get $b
    ref.test (ref null $arr_any)
    i32.eqz
    local.get $b
    ref.test (ref null $tuple)
    i32.or
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $arr_any)
    local.get $b
    ref.cast (ref null $arr_any)
    call $__unk_eq_arr_any
    return
      )
    )
    local.get $a
    ref.test (ref null $rec_Dict)
    (if
      (then
    local.get $b
    ref.test (ref null $rec_Dict)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $rec_Dict)
    local.get $b
    ref.cast (ref null $rec_Dict)
    call $__unk_eq_s2
    return
      )
    )
    local.get $a
    ref.test (ref null $rec_Set)
    (if
      (then
    local.get $b
    ref.test (ref null $rec_Set)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $rec_Set)
    local.get $b
    ref.cast (ref null $rec_Set)
    call $__unk_eq_s10
    return
      )
    )
    local.get $a
    ref.test (ref null $rec_Queue)
    (if
      (then
    local.get $b
    ref.test (ref null $rec_Queue)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $rec_Queue)
    local.get $b
    ref.cast (ref null $rec_Queue)
    call $__unk_eq_s11
    return
      )
    )
    local.get $a
    ref.test (ref null $__decl)
    local.get $b
    ref.test (ref null $__decl)
    i32.and
    (if
      (then
    local.get $a
    local.get $b
    call $__eq_decl
    return
      )
    )
    i32.const 0
  )
  ;; Scratch layout below the data section (which starts at 256):
  ;;   0..8  WASI iovec   8  newline byte
  ;;  16..32 bool text   64..128 i32 digits
  (func $__print_nl
    i32.const 8
    i32.const 10
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
  )
  ;; separator between the arguments of a multi-argument `@print`
  (func $__print_sp
    i32.const 8
    i32.const 32
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
  )
  (func $__print_i32 (param $n i32)
    local.get $n
    call $__print_i32_raw
    call $__print_nl
  )
  (func $__print_i32_raw (param $n i32)
    (local $buf i32) (local $len i32) (local $neg i32) (local $d i32)
    (local $i i32) (local $j i32) (local $tmp i32)
    i32.const 64
    local.set $buf
    local.get $n
    i32.const 0
    i32.lt_s
    (if
      (then
        i32.const 1
        local.set $neg
        i32.const 0
        local.get $n
        i32.sub
        local.set $n
      )
    )
    (block $done
      (loop $digits
        local.get $n
        i32.const 10
        i32.rem_u
        i32.const 48
        i32.add
        local.set $d
        local.get $buf
        local.get $len
        i32.add
        local.get $d
        i32.store8
        local.get $len
        i32.const 1
        i32.add
        local.set $len
        local.get $n
        i32.const 10
        i32.div_u
        local.set $n
        local.get $n
        i32.const 0
        i32.gt_u
        br_if $digits
      )
    )
    ;; reverse
    i32.const 0
    local.set $i
    local.get $len
    i32.const 1
    i32.sub
    local.set $j
    (block $rdone
      (loop $rev
        local.get $i
        local.get $j
        i32.ge_u
        br_if $rdone
        local.get $buf
        local.get $i
        i32.add
        i32.load8_u
        local.set $tmp
        local.get $buf
        local.get $i
        i32.add
        local.get $buf
        local.get $j
        i32.add
        i32.load8_u
        i32.store8
        local.get $buf
        local.get $j
        i32.add
        local.get $tmp
        i32.store8
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        local.get $j
        i32.const 1
        i32.sub
        local.set $j
        br $rev
      )
    )
    ;; add neg sign + newline
    ;; shift the digits one byte right to make room for '-'
    ;; (dst = buf+1, NOT buf+len: the latter moved them `len`
    ;;  bytes and printed -12 as -21)
    local.get $neg
    (if
      (then
        local.get $buf
        i32.const 1
        i32.add
        local.get $buf
        local.get $len
        call $__memmove
        local.get $buf
        i32.const 45
        i32.store8
        local.get $len
        i32.const 1
        i32.add
        local.set $len
      )
    )
    local.get $buf
    local.get $len
    call $__write_bytes
  )
  (func $__memmove (param $dst i32) (param $src i32) (param $len i32)
    (local $i i32)
    local.get $len
    i32.const 1
    i32.sub
    local.set $i
    (block $done
      (loop $loop
        local.get $i
        i32.const 0
        i32.lt_s
        br_if $done
        local.get $dst
        local.get $i
        i32.add
        local.get $src
        local.get $i
        i32.add
        i32.load8_u
        i32.store8
        local.get $i
        i32.const 1
        i32.sub
        local.set $i
        br $loop
      )
    )
  )
  (func $__str_concat (param $a (ref null $str)) (param $b (ref null $str)) (result (ref null $str))
    (local $r (ref null $str)) (local $alen i32) (local $blen i32)
    local.get $a
    array.len
    local.set $alen
    local.get $b
    array.len
    local.set $blen
    local.get $alen
    local.get $blen
    i32.add
    array.new_default $str
    local.set $r
    local.get $r
    i32.const 0
    local.get $a
    i32.const 0
    local.get $alen
    array.copy $str $str
    local.get $r
    local.get $alen
    local.get $b
    i32.const 0
    local.get $blen
    array.copy $str $str
    local.get $r
  )
  (func $__str_eq (param $a (ref null $str)) (param $b (ref null $str)) (result i32)
    (local $i i32) (local $n i32) (local $an i32) (local $bn i32)
    local.get $a
    ref.is_null
    local.set $an
    local.get $b
    ref.is_null
    local.set $bn
    local.get $an
    local.get $bn
    i32.or
    (if
      (then
        local.get $an
        local.get $bn
        i32.and
        return
      )
    )
    local.get $a
    array.len
    local.set $n
    local.get $n
    local.get $b
    array.len
    i32.ne
    (if
      (then
        i32.const 0
        return
      )
    )
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $a
        local.get $i
        array.get_u $str
        local.get $b
        local.get $i
        array.get_u $str
        i32.ne
        (if
          (then
            i32.const 0
            return
          )
        )
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    i32.const 1
  )
  (func $__write_err (param $p i32) (param $n i32)
    i32.const 0
    local.get $p
    i32.store
    i32.const 4
    local.get $n
    i32.store
    i32.const 2
    i32.const 0
    i32.const 1
    i32.const 8
    call $fd_write
    drop
  )
  (func $__assert_fail (param $where i32) (param $msg i32)
    local.get $where
    i32.const 4
    i32.add
    local.get $where
    i32.load
    call $__write_err
    i32.const 188
    i64.const 8390880602276044858
    i64.store
    i32.const 196
    i64.const 7811882119909502825
    i64.store
    i32.const 204
    i32.const 101
    i32.store8
    i32.const 205
    i32.const 100
    i32.store8
    i32.const 188
    i32.const 18
    call $__write_err
    local.get $msg
    (if
      (then
        i32.const 188
        i32.const 8250
        i32.store
        i32.const 188
        i32.const 2
        call $__write_err
        local.get $msg
        i32.const 4
        i32.add
        local.get $msg
        i32.load
        call $__write_err
      )
    )
    i32.const 188
    i32.const 10
    i32.store8
    i32.const 188
    i32.const 1
    call $__write_err
  )
  (func $__panic_fail (param $msg (ref null $str))
    (local $n i32) (local $p i32) (local $i i32) (local $top i32)
    i32.const 188
    i64.const 9071397899755888
    i64.store
    i32.const 188
    i32.const 7
    call $__write_err
    local.get $msg
    array.len
    local.set $n
    global.get $__heap_ptr
    local.set $top
    local.get $n
    call $__alloc
    local.set $p
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $p
        local.get $i
        i32.add
        local.get $msg
        local.get $i
        array.get_u $str
        i32.store8
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $p
    local.get $n
    call $__write_err
    i32.const 188
    i32.const 10
    i32.store8
    i32.const 188
    i32.const 1
    call $__write_err
    local.get $top
    global.set $__heap_ptr
  )
  (func $__i32_add_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
    (local $r i64)
    local.get $a
    i64.extend_i32_s
    local.get $b
    i64.extend_i32_s
    i64.add
    local.set $r
    local.get $r
    i32.wrap_i64
    i64.extend_i32_s
    local.get $r
    i64.ne
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i32_sub_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
    (local $r i64)
    local.get $a
    i64.extend_i32_s
    local.get $b
    i64.extend_i32_s
    i64.sub
    local.set $r
    local.get $r
    i32.wrap_i64
    i64.extend_i32_s
    local.get $r
    i64.ne
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i32_mul_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
    (local $r i64)
    local.get $a
    i64.extend_i32_s
    local.get $b
    i64.extend_i32_s
    i64.mul
    local.set $r
    local.get $r
    i32.wrap_i64
    i64.extend_i32_s
    local.get $r
    i64.ne
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i64_add_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
    (local $r i64)
    local.get $a
    local.get $b
    i64.add
    local.set $r
    local.get $a
    local.get $r
    i64.xor
    local.get $b
    local.get $r
    i64.xor
    i64.and
    i64.const 0
    i64.lt_s
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
  )
  (func $__i64_sub_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
    (local $r i64)
    local.get $a
    local.get $b
    i64.sub
    local.set $r
    local.get $a
    local.get $b
    i64.xor
    local.get $a
    local.get $r
    i64.xor
    i64.and
    i64.const 0
    i64.lt_s
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
  )
  (func $__i64_mul_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
    (local $r i64)
    local.get $a
    i64.const -1
    i64.eq
    local.get $b
    i64.const -9223372036854775808
    i64.eq
    i32.and
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $a
    local.get $b
    i64.mul
    local.set $r
    local.get $a
    i64.eqz
    i32.eqz
    (if
      (then
        local.get $r
        local.get $a
        i64.div_s
        local.get $b
        i64.ne
        (if
          (then
            local.get $site
            call $__chk_fail
            unreachable
          )
        )
      )
    )
    local.get $r
  )
  (func $__cap_begin (result (ref null $str))
    (local $o (ref null $str))
    global.get $__cap
    ref.cast (ref null $str)
    local.set $o
    i32.const 0
    array.new_default $str
    global.set $__cap
    global.get $__cap_depth
    i32.const 1
    i32.add
    global.set $__cap_depth
    local.get $o
  )
  (func $__cap_end (param $o (ref null $str)) (result (ref null $str))
    (local $s (ref null $str))
    global.get $__cap
    ref.cast (ref null $str)
    local.set $s
    local.get $o
    global.set $__cap
    global.get $__cap_depth
    i32.const 1
    i32.sub
    global.set $__cap_depth
    local.get $s
  )
  (func $__chk_fail (param $site (ref null $str))
    local.get $site
    call $__panic_fail
    unreachable
  )
  (data $__d0 ": ")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "Dict(")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 ", ")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 ")")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (data $__d4 "integer overflow: + on i32 at src/collections.bp:81:53")
  (global $__s4 (mut (ref null $str)) (ref.null $str))
  (data $__d5 "\"")
  (global $__s5 (mut (ref null $str)) (ref.null $str))
  (data $__d6 "")
  (global $__s6 (mut (ref null $str)) (ref.null $str))
  (data $__d7 "integer overflow: - on i32 at src/collections.bp:540:15")
  (global $__s7 (mut (ref null $str)) (ref.null $str))
  (data $__d8 "std@collections.Dict")
  (global $__s8 (mut (ref null $str)) (ref.null $str))
  (data $__d9 "std@collections.Set")
  (global $__s9 (mut (ref null $str)) (ref.null $str))
  (data $__d10 "std@collections.Queue")
  (global $__s10 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 2
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 5
    array.new_data $str $__d1
    global.set $__s1
    i32.const 0
    i32.const 2
    array.new_data $str $__d2
    global.set $__s2
    i32.const 0
    i32.const 1
    array.new_data $str $__d3
    global.set $__s3
    i32.const 0
    i32.const 54
    array.new_data $str $__d4
    global.set $__s4
    i32.const 0
    i32.const 1
    array.new_data $str $__d5
    global.set $__s5
    i32.const 0
    i32.const 0
    array.new_data $str $__d6
    global.set $__s6
    i32.const 0
    i32.const 55
    array.new_data $str $__d7
    global.set $__s7
    i32.const 0
    i32.const 20
    array.new_data $str $__d8
    global.set $__s8
    i32.const 0
    i32.const 19
    array.new_data $str $__d9
    global.set $__s9
    i32.const 0
    i32.const 21
    array.new_data $str $__d10
    global.set $__s10
    call $__init_types
  )
  (func $__new_31 (param $f0 (ref null $arr_any)) (result (ref null $rec_Dict))
    global.get $__ti_31
    local.get $f0
    struct.new $rec_Dict
  )
  (func $__new_35 (param $f0 (ref null $arr_any)) (result (ref null $rec_Set))
    global.get $__ti_35
    local.get $f0
    struct.new $rec_Set
  )
  (func $__new_33 (param $f0 (ref null $arr_any)) (result (ref null $rec_Queue))
    global.get $__ti_33
    local.get $f0
    struct.new $rec_Queue
  )
  (global $__ti_31 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (global $__ti_35 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (global $__ti_33 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (elem declare func $__tie2 $__tie10 $__tie11)
  (func $__init_types
    global.get $__s8
    ref.null func
    ref.func $__tie2
    ref.null func
    i32.const 0
    struct.new $__tinfo
    global.set $__ti_31
    global.get $__ti_31
    call $__ti_register
    global.get $__s9
    ref.null func
    ref.func $__tie10
    ref.null func
    i32.const 0
    struct.new $__tinfo
    global.set $__ti_35
    global.get $__ti_35
    call $__ti_register
    global.get $__s10
    ref.null func
    ref.func $__tie11
    ref.null func
    i32.const 0
    struct.new $__tinfo
    global.set $__ti_33
    global.get $__ti_33
    call $__ti_register
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {collections.Dict} from "std";

fn main() -> void {
    val d = Dict.empty().insert("a", 1);
    print(d.at("a") ?? 0);
    print(d.insert("b", 2).size());
}

import {io.terminal.print} from "std";
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $arr_i32 (array (mut i32)))
    (type $arr_f64 (array (mut f64)))
    (type $arr_any (sub (array (mut anyref))))
    (type $tuple (sub final $arr_any (array (mut anyref))))
    (type $box_i32 (sub (struct (field $v i32))))
    (type $box_i64 (struct (field $v i64)))
    (type $box_f64 (struct (field $v f64)))
    (type $box_bool (sub final $box_i32 (struct (field $v i32))))
    (type $box_big (struct (field $v (ref null $str))))
    (type $closure (sub (struct (field $fn funcref) (field $arity i32) (field $mark i32))))
    (type $result (struct (field $tag (mut i32)) (field $payload (mut anyref))))
    (type $exn (struct (field $msg (ref null $str)) (field $print i32)))
    (type $task (struct (field $state (mut i32)) (field $waiters (mut (ref null $waiter))) (field $value (mut anyref)) (field $frame (mut structref)) (field $kind i32) (field $next (mut (ref null $task))) (field $aux (mut anyref)) (field $left (mut i32))))
    (type $waiter (struct (field $next (mut (ref null $waiter))) (field $kind i32) (field $target (ref null $task)) (field $slot i32)))
    (type $hostn (struct (field $next (mut (ref null $hostn))) (field $h i32) (field $t (ref null $task))))
    (type $gen (struct (field $state (mut i32)) (field $kind i32) (field $frame (mut structref)) (field $value (mut anyref)) (field $src (mut (ref null $gen))) (field $aux (mut anyref)) (field $left (mut i32))))
    (type $cell (struct (field $filled (mut i32)) (field $value (mut anyref))))
    (type $__decl (sub (struct (field $ti (ref null $__tinfo)))))
    (type $__tinfo (struct (field $name (ref null $str)) (field $print funcref) (field $eq funcref) (field $display funcref) (field $kind i32)))
    (type $__print_sig (func (param anyref)))
    (type $__eq_sig (func (param anyref anyref) (result i32)))
    (type $sig_0 (func (param (ref null $closure)) (result anyref)))
    (type $sig_1 (func (param (ref null $closure) anyref) (result anyref)))
    (type $sig_2 (func (param (ref null $closure) anyref anyref) (result anyref)))
    (type $sig_3 (func (param (ref null $closure) anyref anyref anyref) (result anyref)))
    (type $sig_4 (func (param (ref null $closure) anyref anyref anyref anyref) (result anyref)))
    (type $sig_5 (func (param (ref null $closure) anyref anyref anyref anyref anyref) (result anyref)))
    (type $sig_6 (func (param (ref null $closure) anyref anyref anyref anyref anyref anyref) (result anyref)))
    (type $sig_7 (func (param (ref null $closure) anyref anyref anyref anyref anyref anyref anyref) (result anyref)))
    (type $sig_8 (func (param (ref null $closure) anyref anyref anyref anyref anyref anyref anyref anyref) (result anyref)))
  )
  (rec
    (type $rec_Dict (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut (ref null $arr_any))))))
    (type $brand_rec_Dict (struct (field i64) (field i32) (field f32) (field f32) (field f64) (field i32) (field f64) (field i64) (field f32) (field f32) (field f64) (field i64) (field f32) (field f32) (field i32) (field i64) (field f64) (field f32) (field f64) (field i32) (field f64) (field i64) (field f64) (field i64) (field f64) (field i32) (field f32) (field i64) (field i64) (field i32) (field f32) (field i32)))
  )
  (import "std@__rt" "__ti_register" (func $__ti_register (param structref)))
  (import "std@__rt" "__eq_decl" (func $__eq_decl (param anyref anyref) (result i32)))
  (import "std@__rt" "__write_bytes" (func $__write_bytes (param i32 i32)))
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (global $__cap (import "std@__rt" "__cap") (mut arrayref))
  (global $__cap_depth (import "std@__rt" "__cap_depth") (mut i32))
  (import "std@__rt" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (func $Dict_display (param $self (ref null $rec_Dict)) (result (ref null $str))
    (local $__mem0 i32)
    (local $parts (ref null $arr_any))
    (local $p i32)
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $p__sh0 (ref null $arr_any))
    array.new_fixed $arr_any 0
    local.set $parts
    local.get $self
    struct.get $rec_Dict $f0
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
    ref.cast (ref null $arr_any)
        local.set $p__sh0
    local.get $parts
    local.get $p__sh0
    i32.const 0
    array.get $arr_any
    call $shown
    global.get $__s0
    call $__str_concat
    local.get $p__sh0
    i32.const 1
    array.get $arr_any
    call $shown
    call $__str_concat
    call $__arr_push_any
    local.set $parts
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    i32.const 0
    drop
    global.get $__s1
    local.get $parts
    global.get $__s2
    call $__arr_join_any
    call $__str_concat
    global.get $__s3
    call $__str_concat
    return
  )
  (func $Dict_at (param $self (ref null $rec_Dict)) (param $key anyref) (result anyref)
    (local $found anyref)
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $p (ref null $arr_any))
    ref.null any
    local.set $found
    local.get $self
    struct.get $rec_Dict $f0
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
    ref.cast (ref null $arr_any)
        local.set $p
    local.get $p
    i32.const 0
    array.get $arr_any
    local.get $key
    call $__unk_eq
    (if (result i32)
      (then
    local.get $p
    i32.const 1
    array.get $arr_any
    local.set $found
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $found
    return
  )
  (func $Dict_hasKey (param $self (ref null $rec_Dict)) (param $key anyref) (result i32)
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $p (ref null $arr_any))
    (local $__out0 (ref null $arr_any))
    local.get $self
    struct.get $rec_Dict $f0
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    array.new_default $arr_any
    local.set $__out0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
    ref.cast (ref null $arr_any)
        local.set $p
    local.get $p
    i32.const 0
    array.get $arr_any
    local.get $key
    call $__unk_eq
    (if
      (then
    local.get $__out0
    local.get $__acc0
    local.get $__iter0
    local.get $__idx0
    array.get $arr_any
    array.set $arr_any
    local.get $__acc0
    i32.const 1
    i32.add
    local.set $__acc0
      )
    )
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $__out0
    i32.const 0
    local.get $__acc0
    call $__arr_slice_any
    i32.const 0
    call $__arr_at_opt_any
    ref.is_null
    i32.eqz
    return
  )
  (func $Dict_size (param $self (ref null $rec_Dict)) (result i32)
    local.get $self
    struct.get $rec_Dict $f0
    array.len
    return
  )
  (func $Dict_isEmpty (param $self (ref null $rec_Dict)) (result i32)
    local.get $self
    struct.get $rec_Dict $f0
    array.len
    i32.const 0
    i32.eq
    return
  )
  (func $Dict_keys (param $self (ref null $rec_Dict)) (result (ref null $arr_any))
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $p (ref null $arr_any))
    (local $__out0 (ref null $arr_any))
    local.get $self
    struct.get $rec_Dict $f0
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    array.new_default $arr_any
    local.set $__out0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
    ref.cast (ref null $arr_any)
        local.set $p
    local.get $__out0
    local.get $__idx0
    local.get $p
    i32.const 0
    array.get $arr_any
    array.set $arr_any
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $__out0
    return
  )
  (func $Dict_values (param $self (ref null $rec_Dict)) (result (ref null $arr_any))
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $p (ref null $arr_any))
    (local $__out0 (ref null $arr_any))
    local.get $self
    struct.get $rec_Dict $f0
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    array.new_default $arr_any
    local.set $__out0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
    ref.cast (ref null $arr_any)
        local.set $p
    local.get $__out0
    local.get $__idx0
    local.get $p
    i32.const 1
    array.get $arr_any
    array.set $arr_any
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $__out0
    return
  )
  (func $Dict_insert (param $self (ref null $rec_Dict)) (param $key anyref) (param $value anyref) (result (ref null $rec_Dict))
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $filtered (ref null $arr_any))
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $p (ref null $arr_any))
    (local $__out0 (ref null $arr_any))
    local.get $self
    struct.get $rec_Dict $f0
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    array.new_default $arr_any
    local.set $__out0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
    ref.cast (ref null $arr_any)
        local.set $p
    local.get $p
    i32.const 0
    array.get $arr_any
    local.get $key
    call $__unk_eq
    i32.eqz
    (if
      (then
    local.get $__out0
    local.get $__acc0
    local.get $__iter0
    local.get $__idx0
    array.get $arr_any
    array.set $arr_any
    local.get $__acc0
    i32.const 1
    i32.add
    local.set $__acc0
      )
    )
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $__out0
    i32.const 0
    local.get $__acc0
    call $__arr_slice_any
    local.set $filtered
    local.get $filtered
    local.get $key
    local.get $value
    array.new_fixed $tuple 2
    array.new_fixed $arr_any 1
    call $__arr_concat_any
    call $__new_31
    return
  )
  (func $Dict_bump (param $self (ref null $rec_Dict)) (param $key anyref) (param $by anyref) (result (ref null $rec_Dict))
    (local $__bp_nullish i32)
    (local $__opt0 anyref)
    local.get $self
    local.get $key
    local.get $self
    local.get $key
    call $Dict_at
    local.tee $__opt0
    ref.is_null
    i32.eqz
    (if (result i32)
      (then
    local.get $__opt0
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $__bp_nullish
    local.get $__bp_nullish
      )
      (else
    i32.const 0
      )
    )
    local.get $by
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    global.get $__s4
    call $__i32_add_chk
    struct.new $box_i32
    call $Dict_insert
    return
  )
  (func $Dict_delete (param $self (ref null $rec_Dict)) (param $key anyref) (result (ref null $rec_Dict))
    (local $__mem0 i32)
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $p (ref null $arr_any))
    (local $__out0 (ref null $arr_any))
    local.get $self
    struct.get $rec_Dict $f0
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    array.new_default $arr_any
    local.set $__out0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
    ref.cast (ref null $arr_any)
        local.set $p
    local.get $p
    i32.const 0
    array.get $arr_any
    local.get $key
    call $__unk_eq
    i32.eqz
    (if
      (then
    local.get $__out0
    local.get $__acc0
    local.get $__iter0
    local.get $__idx0
    array.get $arr_any
    array.set $arr_any
    local.get $__acc0
    i32.const 1
    i32.add
    local.set $__acc0
      )
    )
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $__out0
    i32.const 0
    local.get $__acc0
    call $__arr_slice_any
    call $__new_31
    return
  )
  (func $Dict_merge (param $self (ref null $rec_Dict)) (param $other (ref null $rec_Dict)) (result (ref null $rec_Dict))
    (local $out (ref null $rec_Dict))
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $p (ref null $arr_any))
    local.get $self
    local.set $out
    local.get $other
    struct.get $rec_Dict $f0
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
    ref.cast (ref null $arr_any)
        local.set $p
    local.get $out
    local.get $p
    i32.const 0
    array.get $arr_any
    local.get $p
    i32.const 1
    array.get $arr_any
    call $Dict_insert
    local.set $out
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $out
    return
  )
  (func $Dict_fold (param $self (ref null $rec_Dict)) (param $initial anyref) (param $f (ref null $closure)) (result anyref)
    (local $acc anyref)
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $p (ref null $arr_any))
    (local $__fnv1 (ref null $closure))
    local.get $initial
    local.set $acc
    local.get $self
    struct.get $rec_Dict $f0
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
    ref.cast (ref null $arr_any)
        local.set $p
    local.get $f
    local.set $__fnv1
    local.get $__fnv1
    local.get $acc
    local.get $p
    i32.const 0
    array.get $arr_any
    local.get $p
    i32.const 1
    array.get $arr_any
    local.get $__fnv1
    struct.get $closure $fn ;; the entry
    ref.cast (ref null $sig_3)
    call_ref $sig_3
    local.set $acc
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $acc
    return
  )
  (func $Dict_mapValues (param $self (ref null $rec_Dict)) (param $f (ref null $closure)) (result (ref null $rec_Dict))
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $out (ref null $arr_any))
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $p (ref null $arr_any))
    (local $__fnv1 (ref null $closure))
    array.new_fixed $arr_any 0
    local.set $out
    local.get $self
    struct.get $rec_Dict $f0
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
    ref.cast (ref null $arr_any)
        local.set $p
    local.get $out
    local.get $p
    i32.const 0
    array.get $arr_any
    local.get $f
    local.set $__fnv1
    local.get $__fnv1
    local.get $p
    i32.const 1
    array.get $arr_any
    local.get $__fnv1
    struct.get $closure $fn ;; the entry
    ref.cast (ref null $sig_1)
    call_ref $sig_1
    array.new_fixed $tuple 2
    call $__arr_push_any
    local.set $out
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $out
    call $__new_31
    return
  )
  (func $Dict_empty (result (ref null $rec_Dict))
    (local $__mem0 i32)
    (local $__mem1 i32)
    i32.const 0
    array.new_default $arr_any
    call $__new_31
    return
  )
  (func $Dict_ofEntries (param $entries (ref null $arr_any)) (result (ref null $rec_Dict))
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $out (ref null $rec_Dict))
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $e (ref null $arr_any))
    i32.const 0
    array.new_default $arr_any
    call $__new_31
    local.set $out
    local.get $entries
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
    ref.cast (ref null $arr_any)
        local.set $e
    local.get $out
    local.get $e
    i32.const 0
    array.get $arr_any
    local.get $e
    i32.const 1
    array.get $arr_any
    call $Dict_insert
    local.set $out
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $out
    return
  )
  (func $shown (param $x anyref) (result (ref null $str))
    (local $__gc0 anyref)
    (local $__gc1 (ref null $str))
    (local $__gc2 (ref null $str))
    local.get $x
    local.tee $__gc0
    ref.test (ref null $str)
    local.get $__gc0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    global.get $__s5
    call $__cap_begin
    local.set $__gc1
    local.get $x
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    call $__print_i32_raw
    local.get $__gc1
    call $__cap_end
    call $__str_concat
    global.get $__s5
    call $__str_concat
    return
      )
      (else
        ref.null $str
      )
    )
    drop
    global.get $__s6
    call $__cap_begin
    local.set $__gc2
    local.get $x
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    call $__print_i32_raw
    local.get $__gc2
    call $__cap_end
    call $__str_concat
    return
  )
  (func $reverse (param $o i32) (result i32)
    (local $r i32)
    (local $__case_0 i32)
    local.get $o
    local.set $__case_0
    local.get $__case_0
    i32.const 0 ;; Lt
    i32.eq
    (if (result i32)
      (then
    i32.const 2 ;; Order.Gt
      )
      (else
    local.get $__case_0
    i32.const 2 ;; Gt
    i32.eq
    (if (result i32)
      (then
    i32.const 0 ;; Order.Lt
      )
      (else
    i32.const 1 ;; Order.Eq
      )
    )
      )
    )
    local.set $r
    local.get $r
    return
  )
  (func $main
    (local $d (ref null $rec_Dict))
    (local $__bp_nullish i32)
    (local $__opt0 anyref)
    call $Dict_empty
    global.get $__s7
    i32.const 1
    call $Dict_insert__K_string__V_i32
    local.set $d
    local.get $d
    global.get $__s7
    call $Dict_at__K_string__V_i32
    local.tee $__opt0
    ref.is_null
    i32.eqz
    (if (result i32)
      (then
    local.get $__opt0
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $__bp_nullish
    local.get $__bp_nullish
      )
      (else
    i32.const 0
      )
    )
    call $__print_i32
    local.get $d
    global.get $__s8
    i32.const 2
    call $Dict_insert__K_string__V_i32
    call $Dict_size__K_string__V_i32
    call $__print_i32
  )
  (func $Dict_insert__K_string__V_i32 (param $self (ref null $rec_Dict)) (param $key (ref null $str)) (param $value i32) (result (ref null $rec_Dict))
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $filtered (ref null $arr_any))
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $p (ref null $arr_any))
    (local $__out0 (ref null $arr_any))
    local.get $self
    struct.get $rec_Dict $f0
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    array.new_default $arr_any
    local.set $__out0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
    ref.cast (ref null $arr_any)
        local.set $p
    local.get $p
    i32.const 0
    array.get $arr_any
    ref.cast (ref null $str)
    local.get $key
    call $__str_eq
    i32.eqz
    (if
      (then
    local.get $__out0
    local.get $__acc0
    local.get $__iter0
    local.get $__idx0
    array.get $arr_any
    array.set $arr_any
    local.get $__acc0
    i32.const 1
    i32.add
    local.set $__acc0
      )
    )
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $__out0
    i32.const 0
    local.get $__acc0
    call $__arr_slice_any
    local.set $filtered
    local.get $filtered
    local.get $key
    local.get $value
    struct.new $box_i32
    array.new_fixed $tuple 2
    array.new_fixed $arr_any 1
    call $__arr_concat_any
    call $__new_31
    return
  )
  (func $Dict_at__K_string (param $self (ref null $rec_Dict)) (param $key (ref null $str)) (result anyref)
    (local $found anyref)
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $p (ref null $arr_any))
    ref.null any
    local.set $found
    local.get $self
    struct.get $rec_Dict $f0
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
    ref.cast (ref null $arr_any)
        local.set $p
    local.get $p
    i32.const 0
    array.get $arr_any
    ref.cast (ref null $str)
    local.get $key
    call $__str_eq
    (if (result i32)
      (then
    local.get $p
    i32.const 1
    array.get $arr_any
    local.set $found
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $found
    return
  )
  (func $Dict_at__K_string__V_i32 (param $self (ref null $rec_Dict)) (param $key (ref null $str)) (result anyref)
    (local $found anyref)
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $p (ref null $arr_any))
    ref.null any
    local.set $found
    local.get $self
    struct.get $rec_Dict $f0
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
    ref.cast (ref null $arr_any)
        local.set $p
    local.get $p
    i32.const 0
    array.get $arr_any
    ref.cast (ref null $str)
    local.get $key
    call $__str_eq
    (if (result i32)
      (then
    local.get $p
    i32.const 1
    array.get $arr_any
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    struct.new $box_i32
    local.set $found
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $found
    return
  )
  (func $Dict_size__K_string__V_i32 (param $self (ref null $rec_Dict)) (result i32)
    local.get $self
    struct.get $rec_Dict $f0
    array.len
    return
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
  (func $__arr_push_any (param $xs (ref null $arr_any)) (param $x anyref) (result (ref null $arr_any))
    (local $n i32)
    (local $r (ref null $arr_any))
    local.get $xs
    array.len
    local.set $n
    local.get $n
    i32.const 1
    i32.add
    array.new_default $arr_any
    local.set $r
    local.get $r
    i32.const 0
    local.get $xs
    i32.const 0
    local.get $n
    array.copy $arr_any $arr_any
    local.get $r
    local.get $n
    local.get $x
    array.set $arr_any
    local.get $r
  )
  (func $__arr_join_any (param $xs (ref null $arr_any)) (param $sep (ref null $str)) (result (ref null $str))
    (local $n i32)
    (local $i i32)
    (local $acc (ref null $str))
    local.get $xs
    array.len
    local.set $n
    i32.const 0
    array.new_default $str
    local.set $acc
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $i
    (if
      (then
    local.get $acc
    local.get $sep
    call $__str_concat
    local.set $acc
      )
    )
    local.get $acc
    local.get $xs
    local.get $i
    array.get $arr_any
    ref.cast (ref null $str)
    call $__str_concat
    local.set $acc
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    local.get $acc
  )
  (func $__unk_is_num (param $v anyref) (result i32)
    local.get $v
    ref.is_null
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $v
    ref.test (ref null $box_i32)
    local.get $v
    ref.test (ref null $box_bool)
    i32.eqz
    i32.and
    local.get $v
    ref.test (ref null $box_f64)
    i32.or
  )
  (func $__unk_as_f64 (param $v anyref) (result f64)
    local.get $v
    ref.test (ref null $box_i32)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    f64.convert_i32_s
    return
      )
    )
    local.get $v
    ref.cast (ref null $box_f64)
    struct.get $box_f64 $v
  )
  (func $__unk_eq (param $a anyref) (param $b anyref) (result i32)
    local.get $a
    call $__unk_is_num
    local.get $b
    call $__unk_is_num
    i32.and
    (if
      (then
    local.get $a
    call $__unk_as_f64
    local.get $b
    call $__unk_as_f64
    f64.eq
    return
      )
    )
    local.get $a
    ref.test (ref null $str)
    local.get $a
    ref.is_null
    i32.eqz
    i32.and
    local.get $b
    ref.test (ref null $str)
    i32.and
    local.get $b
    ref.is_null
    i32.eqz
    i32.and
    (if
      (then
    local.get $a
    ref.cast (ref null $str)
    local.get $b
    ref.cast (ref null $str)
    call $__str_eq
    return
      )
    )
    local.get $a
    ref.test (ref null $box_bool)
    local.get $a
    ref.is_null
    i32.eqz
    i32.and
    local.get $b
    ref.test (ref null $box_bool)
    i32.and
    local.get $b
    ref.is_null
    i32.eqz
    i32.and
    (if
      (then
    local.get $a
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.get $b
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    i32.eq
    return
      )
    )
    local.get $a
    local.get $b
    call $__unk_eq_ref
  )
  (func $__arr_slice_any (param $xs (ref null $arr_any)) (param $a i32) (param $b i32) (result (ref null $arr_any))
    (local $len i32)
    (local $from i32)
    (local $to i32)
    (local $n i32)
    (local $r (ref null $arr_any))
    local.get $xs
    array.len
    local.set $len
    local.get $a
    i32.const 0
    i32.lt_s
    (if
      (then
    local.get $len
    local.get $a
    i32.add
    local.set $from
    local.get $from
    i32.const 0
    i32.lt_s
    (if
      (then
    i32.const 0
    local.set $from
      )
    )
      )
      (else
    local.get $a
    local.set $from
    local.get $from
    local.get $len
    i32.gt_s
    (if
      (then
    local.get $len
    local.set $from
      )
    )
      )
    )
    local.get $b
    i32.const 0
    i32.lt_s
    (if
      (then
    local.get $len
    local.get $b
    i32.add
    local.set $to
    local.get $to
    i32.const 0
    i32.lt_s
    (if
      (then
    i32.const 0
    local.set $to
      )
    )
      )
      (else
    local.get $b
    local.set $to
    local.get $to
    local.get $len
    i32.gt_s
    (if
      (then
    local.get $len
    local.set $to
      )
    )
      )
    )
    local.get $to
    local.get $from
    i32.sub
    local.set $n
    local.get $n
    i32.const 0
    i32.lt_s
    (if
      (then
    i32.const 0
    local.set $n
      )
    )
    local.get $n
    array.new_default $arr_any
    local.set $r
    local.get $r
    i32.const 0
    local.get $xs
    local.get $from
    local.get $n
    array.copy $arr_any $arr_any
    local.get $r
  )
  (func $__arr_at_opt_any (param $xs (ref null $arr_any)) (param $i i32) (result anyref)
    local.get $i
    i32.const 0
    i32.lt_s
    (if
      (then
    local.get $i
    local.get $xs
    array.len
    i32.add
    local.set $i
      )
    )
    local.get $i
    i32.const 0
    i32.lt_s
    local.get $i
    local.get $xs
    array.len
    i32.ge_s
    i32.or
    (if (result anyref)
      (then
    ref.null any
      )
      (else
    local.get $xs
    local.get $i
    array.get $arr_any
      )
    )
  )
  (func $__arr_concat_any (param $xs (ref null $arr_any)) (param $ys (ref null $arr_any)) (result (ref null $arr_any))
    (local $la i32)
    (local $lb i32)
    (local $r (ref null $arr_any))
    local.get $xs
    array.len
    local.set $la
    local.get $ys
    array.len
    local.set $lb
    local.get $la
    local.get $lb
    i32.add
    array.new_default $arr_any
    local.set $r
    local.get $r
    i32.const 0
    local.get $xs
    i32.const 0
    local.get $la
    array.copy $arr_any $arr_any
    local.get $r
    local.get $la
    local.get $ys
    i32.const 0
    local.get $lb
    array.copy $arr_any $arr_any
    local.get $r
  )
  (func $__tie2 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $rec_Dict)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    local.get $b
    call $__unk_eq_ref
  )
  (func $__unk_eq_tuple (param $a (ref null $tuple)) (param $b (ref null $tuple)) (result i32)
    (local $i i32)
    local.get $a
    array.len
    local.get $b
    array.len
    i32.ne
    (if
      (then
    i32.const 0
    return
      )
    )
    (block $brk
    (loop $cont
    local.get $i
    local.get $a
    array.len
    i32.ge_u
    br_if $brk
    local.get $a
    local.get $i
    array.get $tuple
    local.get $b
    local.get $i
    array.get $tuple
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    i32.const 1
  )
  (func $__unk_eq_arr_any (param $a (ref null $arr_any)) (param $b (ref null $arr_any)) (result i32)
    (local $i i32)
    local.get $a
    array.len
    local.get $b
    array.len
    i32.ne
    (if
      (then
    i32.const 0
    return
      )
    )
    (block $brk
    (loop $cont
    local.get $i
    local.get $a
    array.len
    i32.ge_u
    br_if $brk
    local.get $a
    local.get $i
    array.get $arr_any
    local.get $b
    local.get $i
    array.get $arr_any
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    i32.const 1
  )
  (func $__unk_eq_s2 (param $a (ref null $rec_Dict)) (param $b (ref null $rec_Dict)) (result i32)
    local.get $a
    struct.get $rec_Dict $f0
    local.get $b
    struct.get $rec_Dict $f0
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    i32.const 1
  )
  (func $__unk_eq_ref (param $a anyref) (param $b anyref) (result i32)
    local.get $a
    ref.is_null
    local.get $b
    ref.is_null
    i32.or
    (if
      (then
    local.get $a
    ref.is_null
    local.get $b
    ref.is_null
    i32.and
    return
      )
    )
    local.get $a
    ref.cast (ref null eq)
    local.get $b
    ref.cast (ref null eq)
    ref.eq
    (if
      (then
    i32.const 1
    return
      )
    )
    local.get $a
    ref.test (ref null $tuple)
    (if
      (then
    local.get $b
    ref.test (ref null $tuple)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $tuple)
    local.get $b
    ref.cast (ref null $tuple)
    call $__unk_eq_tuple
    return
      )
    )
    local.get $a
    ref.test (ref null $arr_any)
    (if
      (then
    local.get $b
    ref.test (ref null $arr_any)
    i32.eqz
    local.get $b
    ref.test (ref null $tuple)
    i32.or
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $arr_any)
    local.get $b
    ref.cast (ref null $arr_any)
    call $__unk_eq_arr_any
    return
      )
    )
    local.get $a
    ref.test (ref null $rec_Dict)
    (if
      (then
    local.get $b
    ref.test (ref null $rec_Dict)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $rec_Dict)
    local.get $b
    ref.cast (ref null $rec_Dict)
    call $__unk_eq_s2
    return
      )
    )
    local.get $a
    ref.test (ref null $__decl)
    local.get $b
    ref.test (ref null $__decl)
    i32.and
    (if
      (then
    local.get $a
    local.get $b
    call $__eq_decl
    return
      )
    )
    i32.const 0
  )
  ;; Scratch layout below the data section (which starts at 256):
  ;;   0..8  WASI iovec   8  newline byte
  ;;  16..32 bool text   64..128 i32 digits
  (func $__print_nl
    i32.const 8
    i32.const 10
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
  )
  ;; separator between the arguments of a multi-argument `@print`
  (func $__print_sp
    i32.const 8
    i32.const 32
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
  )
  (func $__print_i32 (param $n i32)
    local.get $n
    call $__print_i32_raw
    call $__print_nl
  )
  (func $__print_i32_raw (param $n i32)
    (local $buf i32) (local $len i32) (local $neg i32) (local $d i32)
    (local $i i32) (local $j i32) (local $tmp i32)
    i32.const 64
    local.set $buf
    local.get $n
    i32.const 0
    i32.lt_s
    (if
      (then
        i32.const 1
        local.set $neg
        i32.const 0
        local.get $n
        i32.sub
        local.set $n
      )
    )
    (block $done
      (loop $digits
        local.get $n
        i32.const 10
        i32.rem_u
        i32.const 48
        i32.add
        local.set $d
        local.get $buf
        local.get $len
        i32.add
        local.get $d
        i32.store8
        local.get $len
        i32.const 1
        i32.add
        local.set $len
        local.get $n
        i32.const 10
        i32.div_u
        local.set $n
        local.get $n
        i32.const 0
        i32.gt_u
        br_if $digits
      )
    )
    ;; reverse
    i32.const 0
    local.set $i
    local.get $len
    i32.const 1
    i32.sub
    local.set $j
    (block $rdone
      (loop $rev
        local.get $i
        local.get $j
        i32.ge_u
        br_if $rdone
        local.get $buf
        local.get $i
        i32.add
        i32.load8_u
        local.set $tmp
        local.get $buf
        local.get $i
        i32.add
        local.get $buf
        local.get $j
        i32.add
        i32.load8_u
        i32.store8
        local.get $buf
        local.get $j
        i32.add
        local.get $tmp
        i32.store8
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        local.get $j
        i32.const 1
        i32.sub
        local.set $j
        br $rev
      )
    )
    ;; add neg sign + newline
    ;; shift the digits one byte right to make room for '-'
    ;; (dst = buf+1, NOT buf+len: the latter moved them `len`
    ;;  bytes and printed -12 as -21)
    local.get $neg
    (if
      (then
        local.get $buf
        i32.const 1
        i32.add
        local.get $buf
        local.get $len
        call $__memmove
        local.get $buf
        i32.const 45
        i32.store8
        local.get $len
        i32.const 1
        i32.add
        local.set $len
      )
    )
    local.get $buf
    local.get $len
    call $__write_bytes
  )
  (func $__memmove (param $dst i32) (param $src i32) (param $len i32)
    (local $i i32)
    local.get $len
    i32.const 1
    i32.sub
    local.set $i
    (block $done
      (loop $loop
        local.get $i
        i32.const 0
        i32.lt_s
        br_if $done
        local.get $dst
        local.get $i
        i32.add
        local.get $src
        local.get $i
        i32.add
        i32.load8_u
        i32.store8
        local.get $i
        i32.const 1
        i32.sub
        local.set $i
        br $loop
      )
    )
  )
  (func $__str_concat (param $a (ref null $str)) (param $b (ref null $str)) (result (ref null $str))
    (local $r (ref null $str)) (local $alen i32) (local $blen i32)
    local.get $a
    array.len
    local.set $alen
    local.get $b
    array.len
    local.set $blen
    local.get $alen
    local.get $blen
    i32.add
    array.new_default $str
    local.set $r
    local.get $r
    i32.const 0
    local.get $a
    i32.const 0
    local.get $alen
    array.copy $str $str
    local.get $r
    local.get $alen
    local.get $b
    i32.const 0
    local.get $blen
    array.copy $str $str
    local.get $r
  )
  (func $__str_eq (param $a (ref null $str)) (param $b (ref null $str)) (result i32)
    (local $i i32) (local $n i32) (local $an i32) (local $bn i32)
    local.get $a
    ref.is_null
    local.set $an
    local.get $b
    ref.is_null
    local.set $bn
    local.get $an
    local.get $bn
    i32.or
    (if
      (then
        local.get $an
        local.get $bn
        i32.and
        return
      )
    )
    local.get $a
    array.len
    local.set $n
    local.get $n
    local.get $b
    array.len
    i32.ne
    (if
      (then
        i32.const 0
        return
      )
    )
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $a
        local.get $i
        array.get_u $str
        local.get $b
        local.get $i
        array.get_u $str
        i32.ne
        (if
          (then
            i32.const 0
            return
          )
        )
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    i32.const 1
  )
  (func $__write_err (param $p i32) (param $n i32)
    i32.const 0
    local.get $p
    i32.store
    i32.const 4
    local.get $n
    i32.store
    i32.const 2
    i32.const 0
    i32.const 1
    i32.const 8
    call $fd_write
    drop
  )
  (func $__assert_fail (param $where i32) (param $msg i32)
    local.get $where
    i32.const 4
    i32.add
    local.get $where
    i32.load
    call $__write_err
    i32.const 188
    i64.const 8390880602276044858
    i64.store
    i32.const 196
    i64.const 7811882119909502825
    i64.store
    i32.const 204
    i32.const 101
    i32.store8
    i32.const 205
    i32.const 100
    i32.store8
    i32.const 188
    i32.const 18
    call $__write_err
    local.get $msg
    (if
      (then
        i32.const 188
        i32.const 8250
        i32.store
        i32.const 188
        i32.const 2
        call $__write_err
        local.get $msg
        i32.const 4
        i32.add
        local.get $msg
        i32.load
        call $__write_err
      )
    )
    i32.const 188
    i32.const 10
    i32.store8
    i32.const 188
    i32.const 1
    call $__write_err
  )
  (func $__panic_fail (param $msg (ref null $str))
    (local $n i32) (local $p i32) (local $i i32) (local $top i32)
    i32.const 188
    i64.const 9071397899755888
    i64.store
    i32.const 188
    i32.const 7
    call $__write_err
    local.get $msg
    array.len
    local.set $n
    global.get $__heap_ptr
    local.set $top
    local.get $n
    call $__alloc
    local.set $p
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $p
        local.get $i
        i32.add
        local.get $msg
        local.get $i
        array.get_u $str
        i32.store8
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $p
    local.get $n
    call $__write_err
    i32.const 188
    i32.const 10
    i32.store8
    i32.const 188
    i32.const 1
    call $__write_err
    local.get $top
    global.set $__heap_ptr
  )
  (func $__i32_add_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
    (local $r i64)
    local.get $a
    i64.extend_i32_s
    local.get $b
    i64.extend_i32_s
    i64.add
    local.set $r
    local.get $r
    i32.wrap_i64
    i64.extend_i32_s
    local.get $r
    i64.ne
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i32_sub_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
    (local $r i64)
    local.get $a
    i64.extend_i32_s
    local.get $b
    i64.extend_i32_s
    i64.sub
    local.set $r
    local.get $r
    i32.wrap_i64
    i64.extend_i32_s
    local.get $r
    i64.ne
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i32_mul_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
    (local $r i64)
    local.get $a
    i64.extend_i32_s
    local.get $b
    i64.extend_i32_s
    i64.mul
    local.set $r
    local.get $r
    i32.wrap_i64
    i64.extend_i32_s
    local.get $r
    i64.ne
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i64_add_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
    (local $r i64)
    local.get $a
    local.get $b
    i64.add
    local.set $r
    local.get $a
    local.get $r
    i64.xor
    local.get $b
    local.get $r
    i64.xor
    i64.and
    i64.const 0
    i64.lt_s
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
  )
  (func $__i64_sub_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
    (local $r i64)
    local.get $a
    local.get $b
    i64.sub
    local.set $r
    local.get $a
    local.get $b
    i64.xor
    local.get $a
    local.get $r
    i64.xor
    i64.and
    i64.const 0
    i64.lt_s
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
  )
  (func $__i64_mul_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
    (local $r i64)
    local.get $a
    i64.const -1
    i64.eq
    local.get $b
    i64.const -9223372036854775808
    i64.eq
    i32.and
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $a
    local.get $b
    i64.mul
    local.set $r
    local.get $a
    i64.eqz
    i32.eqz
    (if
      (then
        local.get $r
        local.get $a
        i64.div_s
        local.get $b
        i64.ne
        (if
          (then
            local.get $site
            call $__chk_fail
            unreachable
          )
        )
      )
    )
    local.get $r
  )
  (func $__cap_begin (result (ref null $str))
    (local $o (ref null $str))
    global.get $__cap
    ref.cast (ref null $str)
    local.set $o
    i32.const 0
    array.new_default $str
    global.set $__cap
    global.get $__cap_depth
    i32.const 1
    i32.add
    global.set $__cap_depth
    local.get $o
  )
  (func $__cap_end (param $o (ref null $str)) (result (ref null $str))
    (local $s (ref null $str))
    global.get $__cap
    ref.cast (ref null $str)
    local.set $s
    local.get $o
    global.set $__cap
    global.get $__cap_depth
    i32.const 1
    i32.sub
    global.set $__cap_depth
    local.get $s
  )
  (func $__chk_fail (param $site (ref null $str))
    local.get $site
    call $__panic_fail
    unreachable
  )
  (data $__d0 ": ")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "Dict(")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 ", ")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 ")")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (data $__d4 "integer overflow: + on i32 at src/collections.bp:81:53")
  (global $__s4 (mut (ref null $str)) (ref.null $str))
  (data $__d5 "\"")
  (global $__s5 (mut (ref null $str)) (ref.null $str))
  (data $__d6 "")
  (global $__s6 (mut (ref null $str)) (ref.null $str))
  (data $__d7 "a")
  (global $__s7 (mut (ref null $str)) (ref.null $str))
  (data $__d8 "b")
  (global $__s8 (mut (ref null $str)) (ref.null $str))
  (data $__d9 "std@collections.Dict")
  (global $__s9 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 2
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 5
    array.new_data $str $__d1
    global.set $__s1
    i32.const 0
    i32.const 2
    array.new_data $str $__d2
    global.set $__s2
    i32.const 0
    i32.const 1
    array.new_data $str $__d3
    global.set $__s3
    i32.const 0
    i32.const 54
    array.new_data $str $__d4
    global.set $__s4
    i32.const 0
    i32.const 1
    array.new_data $str $__d5
    global.set $__s5
    i32.const 0
    i32.const 0
    array.new_data $str $__d6
    global.set $__s6
    i32.const 0
    i32.const 1
    array.new_data $str $__d7
    global.set $__s7
    i32.const 0
    i32.const 1
    array.new_data $str $__d8
    global.set $__s8
    i32.const 0
    i32.const 20
    array.new_data $str $__d9
    global.set $__s9
    call $__init_types
  )
  (func $__new_31 (param $f0 (ref null $arr_any)) (result (ref null $rec_Dict))
    global.get $__ti_31
    local.get $f0
    struct.new $rec_Dict
  )
  (global $__ti_31 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (elem declare func $__tie2)
  (func $__init_types
    global.get $__s9
    ref.null func
    ref.func $__tie2
    ref.null func
    i32.const 0
    struct.new $__tinfo
    global.set $__ti_31
    global.get $__ti_31
    call $__ti_register
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
1
2
```
