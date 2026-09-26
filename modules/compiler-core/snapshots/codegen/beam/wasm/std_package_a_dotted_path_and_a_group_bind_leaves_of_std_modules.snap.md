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

----- WASM TEXT -- std/collections.wat
```wasm
(module
  (memory (export "memory") 1)
  (table funcref (elem))
  (data (i32.const 256) "\0e\00\00\00R\04Dict\01\05pairsi")
  (data (i32.const 276) "\0d\00\00\00R\03Set\01\05itemsi")
  (data (i32.const 296) "\0f\00\00\00R\05Queue\01\05itemsi")
  (global $__heap_ptr (mut i32) (i32.const 316))
  ;; std/collections — the four collection types, one namespace each (decision
  ;; 106): `Dict<K, V>`, `Set<T>`, `Queue<T>` and `Order`. Was the four modules
  ;; `dict`, `sets`, `queue` and `order`; the type is the namespace now, so a
  ;; constructor is called on the type it builds (decision 111) —
  ;; `Dict.empty()`, `Set.empty()` / `Set.fromList(xs)`, `Queue.empty()` /
  ;; `Queue.fromList(xs)` — and every other function keeps its name.
  ;; ── Dict<K, V> ──────────────────────────────────────────────────────────────
  ;; `Dict` (was `dict`) — Gleam-inspired — a `type Dict<K, V>` wrapping an
  ;; association list `pairs: Array<#(K, V)>` for full backend portability
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
  ;; `Dict<K, V>` answers the ambient `Index<K, V>` of `builtins.d.bp`
  ;; (decision 63, amended), which is what makes `d["k"]` legal: the index
  ;; expression has no typing rule of its own and rewrites to `d.at("k")`. The
  ;; reader was spelled `lookup` until that amendment gave every indexable type
  ;; one method name.
  (func $Dict_at (param $self i32) (param $key i32) (result i32)
    (local $found i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $p i32)
    i32.const 0
    local.set $found
    local.get $self
    i32.load ;; .pairs
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
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
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $p
    local.get $p
    i32.load
    local.get $key
    i32.eq
    (if (result i32)
      (then
    local.get $p
    i32.load offset=4
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
  (func $Dict_hasKey (param $self i32) (param $key i32) (result i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $__out0 i32)
    (local $p i32)
    local.get $self
    i32.load ;; .pairs
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    call $__arr_new
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
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $p
    local.get $p
    i32.load
    local.get $key
    i32.eq
    (if
      (then
    local.get $__out0
    local.get $__acc0
    i32.const 4
    i32.mul
    i32.add
    local.get $__iter0
    local.get $__idx0
    i32.const 4
    i32.mul
    i32.add
    i32.load offset=4
    i32.store offset=4
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
    local.get $__acc0
    i32.store ;; kept count
    local.get $__out0
    i32.const 0
    call $__arr_at_box
    i32.const 0
    i32.ne
    return
  )
  (func $Dict_size (param $self i32) (result i32)
    local.get $self
    i32.load ;; .pairs
    i32.load ;; .length
    return
  )
  (func $Dict_isEmpty (param $self i32) (result i32)
    local.get $self
    i32.load ;; .pairs
    i32.load ;; .length
    i32.const 0
    i32.eq
    return
  )
  (func $Dict_keys (param $self i32) (result i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $__out0 i32)
    (local $p i32)
    local.get $self
    i32.load ;; .pairs
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    call $__arr_new
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
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $p
    local.get $__out0
    local.get $__idx0
    i32.const 4
    i32.mul
    i32.add
    local.get $p
    i32.load
    i32.store offset=4
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
  (func $Dict_values (param $self i32) (result i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $__out0 i32)
    (local $p i32)
    local.get $self
    i32.load ;; .pairs
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    call $__arr_new
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
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $p
    local.get $__out0
    local.get $__idx0
    i32.const 4
    i32.mul
    i32.add
    local.get $p
    i32.load offset=4
    i32.store offset=4
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
  (func $Dict_insert (param $self i32) (param $key i32) (param $value i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $filtered i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $__out0 i32)
    (local $p i32)
    local.get $self
    i32.load ;; .pairs
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    call $__arr_new
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
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $p
    local.get $p
    i32.load
    local.get $key
    i32.ne
    (if
      (then
    local.get $__out0
    local.get $__acc0
    i32.const 4
    i32.mul
    i32.add
    local.get $__iter0
    local.get $__idx0
    i32.const 4
    i32.mul
    i32.add
    i32.load offset=4
    i32.store offset=4
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
    local.get $__acc0
    i32.store ;; kept count
    local.get $__out0
    local.set $filtered
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 260
    i32.store
    local.get $__mem0
    local.get $filtered
    global.get $__heap_ptr
    local.set $__mem1
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem1
    i32.const 1
    i32.store
    local.get $__mem1
    global.get $__heap_ptr
    local.set $__mem2
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem2
    local.get $key
    i32.store
    local.get $__mem2
    local.get $value
    i32.store offset=4
    local.get $__mem2
    i32.store offset=4
    local.get $__mem1
    call $__arr_concat
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  (func $Dict_delete (param $self i32) (param $key i32) (result i32)
    (local $__mem0 i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $__out0 i32)
    (local $p i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 260
    i32.store
    local.get $__mem0
    local.get $self
    i32.load ;; .pairs
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    call $__arr_new
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
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $p
    local.get $p
    i32.load
    local.get $key
    i32.ne
    (if
      (then
    local.get $__out0
    local.get $__acc0
    i32.const 4
    i32.mul
    i32.add
    local.get $__iter0
    local.get $__idx0
    i32.const 4
    i32.mul
    i32.add
    i32.load offset=4
    i32.store offset=4
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
    local.get $__acc0
    i32.store ;; kept count
    local.get $__out0
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  (func $Dict_merge (param $self i32) (param $other i32) (result i32)
    (local $out i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $p i32)
    local.get $self
    local.set $out
    local.get $other
    i32.load ;; .pairs
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
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
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $p
    local.get $out
    local.get $p
    i32.load
    local.get $p
    i32.load offset=4
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
  (func $Dict_fold (param $self i32) (param $initial i32) (param $f i32) (result i32)
    (local $acc i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $p i32)
    (local $__fnv1 i32)
    local.get $initial
    local.set $acc
    local.get $self
    i32.load ;; .pairs
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
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
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $p
    local.get $f
    local.set $__fnv1
    local.get $__fnv1
    local.get $acc
    local.get $p
    i32.load
    local.get $p
    i32.load offset=4
    local.get $__fnv1
    i32.load ;; table index
    call_indirect (param i32 i32 i32 i32) (result i32)
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
  (func $Dict_mapValues (param $self i32) (param $f i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $out i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $p i32)
    (local $__fnv1 i32)
    (local $__mem2 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 4
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 0
    i32.store
    local.get $__mem0
    local.set $out
    local.get $self
    i32.load ;; .pairs
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
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
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $p
    local.get $out
    global.get $__heap_ptr
    local.set $__mem1
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem1
    local.get $p
    i32.load
    i32.store
    local.get $__mem1
    local.get $f
    local.set $__fnv1
    local.get $__fnv1
    local.get $p
    i32.load offset=4
    local.get $__fnv1
    i32.load ;; table index
    call_indirect (param i32 i32) (result i32)
    i32.store offset=4
    local.get $__mem1
    call $__arr_push
    local.set $out
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    global.get $__heap_ptr
    local.set $__mem2
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem2
    i32.const 260
    i32.store
    local.get $__mem2
    local.get $out
    i32.store offset=4
    local.get $__mem2
    i32.const 4
    i32.add
    return
  )
  (func $Dict_empty (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 260
    i32.store
    local.get $__mem0
    global.get $__heap_ptr
    local.set $__mem1
    global.get $__heap_ptr
    i32.const 4
    i32.add
    global.set $__heap_ptr
    local.get $__mem1
    i32.const 0
    i32.store
    local.get $__mem1
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  ;; ── option method API over `at`'s `?V` (B1: Option map/flatMap/unwrapOr) ──
  ;; ── empty-collection boundary (B1) ──
  ;; ── Set<T> ──────────────────────────────────────────────────────────────────
  ;; `Set` (was `sets`) — Gleam-inspired — a `type Set<T>` wrapping a deduplicated
  ;; `Array<T>` (`items`). Pure botopink — no host backing. O(n) contains;
  ;; uniqueness via `Array.indexOf` (structural equality — string/numeric elems).
  ;; 
  ;; Instance operations are `self`-methods on the record; `empty`/`fromList`
  ;; are type-scoped constructors (`Set.empty()`, `Set.fromList(xs)`). API
  ;; naming note: `new`/`set` are keyword tokens — the constructor is `empty`.
  (func $Set_contains (param $self i32) (param $x i32) (result i32)
    local.get $self
    i32.load ;; .items
    local.get $x
    call $__arr_index_of_i32
    i32.const 0
    i32.const 1
    i32.sub
    i32.ne
    return
  )
  (func $Set_size (param $self i32) (result i32)
    local.get $self
    i32.load ;; .items
    i32.load ;; .length
    return
  )
  (func $Set_isEmpty (param $self i32) (result i32)
    local.get $self
    i32.load ;; .items
    i32.load ;; .length
    i32.const 0
    i32.eq
    return
  )
  (func $Set_toList (param $self i32) (result i32)
    local.get $self
    i32.load ;; .items
    return
  )
  (func $Set_insert (param $self i32) (param $x i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    local.get $self
    i32.load ;; .items
    local.get $x
    call $__arr_index_of_i32
    i32.const 0
    i32.const 1
    i32.sub
    i32.ne
    (if (result i32)
      (then
    local.get $self
      )
      (else
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 280
    i32.store
    local.get $__mem0
    local.get $self
    i32.load ;; .items
    global.get $__heap_ptr
    local.set $__mem1
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem1
    i32.const 1
    i32.store
    local.get $__mem1
    local.get $x
    i32.store offset=4
    local.get $__mem1
    call $__arr_concat
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
      )
    )
    return
  )
  (func $Set_delete (param $self i32) (param $x i32) (result i32)
    (local $__mem0 i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $__out0 i32)
    (local $item i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 280
    i32.store
    local.get $__mem0
    local.get $self
    i32.load ;; .items
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    call $__arr_new
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
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $item
    local.get $item
    local.get $x
    i32.ne
    (if
      (then
    local.get $__out0
    local.get $__acc0
    i32.const 4
    i32.mul
    i32.add
    local.get $__iter0
    local.get $__idx0
    i32.const 4
    i32.mul
    i32.add
    i32.load offset=4
    i32.store offset=4
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
    local.get $__acc0
    i32.store ;; kept count
    local.get $__out0
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  (func $Set_union (param $self i32) (param $other i32) (result i32)
    (local $out i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $x i32)
    local.get $self
    local.set $out
    local.get $other
    i32.load ;; .items
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
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
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
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
  (func $Set_intersection (param $self i32) (param $other i32) (result i32)
    (local $__mem0 i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $__out0 i32)
    (local $x i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 280
    i32.store
    local.get $__mem0
    local.get $self
    i32.load ;; .items
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    call $__arr_new
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
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $x
    local.get $other
    i32.load ;; .items
    local.get $x
    call $__arr_index_of_i32
    i32.const 0
    i32.const 1
    i32.sub
    i32.ne
    (if
      (then
    local.get $__out0
    local.get $__acc0
    i32.const 4
    i32.mul
    i32.add
    local.get $__iter0
    local.get $__idx0
    i32.const 4
    i32.mul
    i32.add
    i32.load offset=4
    i32.store offset=4
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
    local.get $__acc0
    i32.store ;; kept count
    local.get $__out0
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  (func $Set_difference (param $self i32) (param $other i32) (result i32)
    (local $__mem0 i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $__out0 i32)
    (local $x i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 280
    i32.store
    local.get $__mem0
    local.get $self
    i32.load ;; .items
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    call $__arr_new
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
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $x
    local.get $other
    i32.load ;; .items
    local.get $x
    call $__arr_index_of_i32
    i32.const 0
    i32.const 1
    i32.sub
    i32.eq
    (if
      (then
    local.get $__out0
    local.get $__acc0
    i32.const 4
    i32.mul
    i32.add
    local.get $__iter0
    local.get $__idx0
    i32.const 4
    i32.mul
    i32.add
    i32.load offset=4
    i32.store offset=4
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
    local.get $__acc0
    i32.store ;; kept count
    local.get $__out0
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  (func $Set_empty (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 280
    i32.store
    local.get $__mem0
    global.get $__heap_ptr
    local.set $__mem1
    global.get $__heap_ptr
    i32.const 4
    i32.add
    global.set $__heap_ptr
    local.get $__mem1
    i32.const 0
    i32.store
    local.get $__mem1
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  (func $Set_fromList (param $xs i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $out i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $x i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 280
    i32.store
    local.get $__mem0
    global.get $__heap_ptr
    local.set $__mem1
    global.get $__heap_ptr
    i32.const 4
    i32.add
    global.set $__heap_ptr
    local.get $__mem1
    i32.const 0
    i32.store
    local.get $__mem1
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
    local.set $out
    local.get $xs
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
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
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
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
  ;; `Queue` (was `queue`) — Gleam-inspired — a `type Queue<T>` wrapping an `Array<T>`
  ;; (front at index 0). Pure botopink — no host backing. O(n) enqueue (copy),
  ;; O(1) peek.
  ;; 
  ;; Instance operations are `self`-methods on the record; `empty`/`fromList`
  ;; are type-scoped constructors (`Queue.empty()`, `Queue.fromList(xs)`).
  ;; `dequeue` returns `#(Queue<T>, ?T)` (the updated queue + the removed front
  ;; item). API naming note: `new` is a keyword token —
  ;; the constructor is `empty`.
  (func $Queue_size (param $self i32) (result i32)
    local.get $self
    i32.load ;; .items
    i32.load ;; .length
    return
  )
  (func $Queue_isEmpty (param $self i32) (result i32)
    local.get $self
    i32.load ;; .items
    i32.load ;; .length
    i32.const 0
    i32.eq
    return
  )
  (func $Queue_enqueue (param $self i32) (param $item i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 300
    i32.store
    local.get $__mem0
    local.get $self
    i32.load ;; .items
    global.get $__heap_ptr
    local.set $__mem1
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem1
    i32.const 1
    i32.store
    local.get $__mem1
    local.get $item
    i32.store offset=4
    local.get $__mem1
    call $__arr_concat
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  (func $Queue_dequeue (param $self i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $head i32)
    (local $rest i32)
    local.get $self
    i32.load ;; .items
    i32.const 0
    call $__arr_at_box
    local.set $head
    local.get $self
    i32.load ;; .items
    i32.const 1
    local.get $self
    i32.load ;; .items
    i32.load ;; .length
    call $__arr_slice
    local.set $rest
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    global.get $__heap_ptr
    local.set $__mem1
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem1
    i32.const 300
    i32.store
    local.get $__mem1
    local.get $rest
    i32.store offset=4
    local.get $__mem1
    i32.const 4
    i32.add
    i32.store
    local.get $__mem0
    local.get $head
    i32.store offset=4
    local.get $__mem0
    return
  )
  (func $Queue_peek (param $self i32) (result i32)
    local.get $self
    i32.load ;; .items
    i32.const 0
    call $__arr_at_box
    return
  )
  (func $Queue_toList (param $self i32) (result i32)
    local.get $self
    i32.load ;; .items
    return
  )
  (func $Queue_empty (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 300
    i32.store
    local.get $__mem0
    global.get $__heap_ptr
    local.set $__mem1
    global.get $__heap_ptr
    i32.const 4
    i32.add
    global.set $__heap_ptr
    local.get $__mem1
    i32.const 0
    i32.store
    local.get $__mem1
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  (func $Queue_fromList (param $xs i32) (result i32)
    (local $__mem0 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 300
    i32.store
    local.get $__mem0
    local.get $xs
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
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
    i32.sub
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
  (func $__alloc (param $n i32) (result i32)
    (local $p i32)
    global.get $__heap_ptr
    local.set $p
    global.get $__heap_ptr
    local.get $n
    i32.add
    i32.const 3
    i32.add
    i32.const -4
    i32.and
    global.set $__heap_ptr
    local.get $p
  )
  (func $__arr_new (param $n i32) (result i32)
    (local $p i32)
    local.get $n
    i32.const 1
    i32.add
    i32.const 4
    i32.mul
    call $__alloc
    local.set $p
    local.get $p
    local.get $n
    i32.store
    local.get $p
  )
  (func $__arr_slice (param $xs i32) (param $a i32) (param $b i32) (result i32)
    (local $n i32) (local $cnt i32) (local $p i32)
    local.get $xs
    i32.load
    local.set $n
    local.get $a
    i32.const 0
    i32.lt_s
    (if
      (then
        local.get $n
        local.get $a
        i32.add
        local.set $a
        local.get $a
        i32.const 0
        i32.lt_s
        (if
          (then
            i32.const 0
            local.set $a
          )
        )
      )
      (else
        local.get $a
        local.get $n
        i32.gt_s
        (if
          (then
            local.get $n
            local.set $a
          )
        )
      )
    )
    local.get $b
    i32.const 0
    i32.lt_s
    (if
      (then
        local.get $n
        local.get $b
        i32.add
        local.set $b
        local.get $b
        i32.const 0
        i32.lt_s
        (if
          (then
            i32.const 0
            local.set $b
          )
        )
      )
      (else
        local.get $b
        local.get $n
        i32.gt_s
        (if
          (then
            local.get $n
            local.set $b
          )
        )
      )
    )
    local.get $b
    local.get $a
    i32.sub
    local.set $cnt
    local.get $cnt
    i32.const 0
    i32.lt_s
    (if
      (then
        i32.const 0
        local.set $cnt
      )
    )
    local.get $cnt
    call $__arr_new
    local.set $p
    local.get $p
    i32.const 4
    i32.add
    local.get $xs
    i32.const 4
    i32.add
    local.get $a
    i32.const 4
    i32.mul
    i32.add
    local.get $cnt
    i32.const 4
    i32.mul
    memory.copy
    local.get $p
  )
  (func $__arr_push (param $xs i32) (param $x i32) (result i32)
    (local $n i32) (local $p i32)
    local.get $xs
    i32.load
    local.set $n
    local.get $n
    i32.const 1
    i32.add
    call $__arr_new
    local.set $p
    local.get $p
    i32.const 4
    i32.add
    local.get $xs
    i32.const 4
    i32.add
    local.get $n
    i32.const 4
    i32.mul
    memory.copy
    local.get $p
    i32.const 4
    i32.add
    local.get $n
    i32.const 4
    i32.mul
    i32.add
    local.get $x
    i32.store
    local.get $p
  )
  (func $__arr_concat (param $a i32) (param $b i32) (result i32)
    (local $na i32) (local $nb i32) (local $p i32)
    local.get $a
    i32.load
    local.set $na
    local.get $b
    i32.load
    local.set $nb
    local.get $na
    local.get $nb
    i32.add
    call $__arr_new
    local.set $p
    local.get $p
    i32.const 4
    i32.add
    local.get $a
    i32.const 4
    i32.add
    local.get $na
    i32.const 4
    i32.mul
    memory.copy
    local.get $p
    i32.const 4
    i32.add
    local.get $na
    i32.const 4
    i32.mul
    i32.add
    local.get $b
    i32.const 4
    i32.add
    local.get $nb
    i32.const 4
    i32.mul
    memory.copy
    local.get $p
  )
  (func $__arr_index_of_i32 (param $xs i32) (param $x i32) (result i32)
    (local $n i32) (local $i i32)
    local.get $xs
    i32.load
    local.set $n
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $xs
        i32.const 4
        i32.add
        local.get $i
        i32.const 4
        i32.mul
        i32.add
        i32.load
        local.get $x
        i32.eq
        (if
          (then
            local.get $i
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
    i32.const -1
  )
  (func $__box_i32 (param $v i32) (result i32)
    (local $p i32)
    i32.const 4
    call $__alloc
    local.set $p
    local.get $p
    local.get $v
    i32.store
    local.get $p
  )
  (func $__arr_at_box (param $xs i32) (param $i i32) (result i32)
    local.get $i
    i32.const 0
    i32.lt_s
    local.get $i
    local.get $xs
    i32.load
    i32.ge_s
    i32.or
    (if
      (then
        i32.const 0
        return
      )
    )
    local.get $xs
    i32.const 4
    i32.add
    local.get $i
    i32.const 4
    i32.mul
    i32.add
    i32.load
    call $__box_i32
  )
)
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {collections.Dict, collections: {gt, reverse, toInt as rank}} from "std";

fn main() {
    val d: Dict<string, i32> = Dict.empty();
    @print(d.insert("a", 1).size());
    @print(rank(reverse(gt())));
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (table funcref (elem))
  (data (i32.const 256) "\0e\00\00\00R\04Dict\01\05pairsi")
  (data (i32.const 276) "\0d\00\00\00R\03Set\01\05itemsi")
  (data (i32.const 296) "\0f\00\00\00R\05Queue\01\05itemsi")
  (data (i32.const 316) "\01\00\00\00a")
  (global $__heap_ptr (mut i32) (i32.const 324))
  (func $Dict_at (param $self i32) (param $key i32) (result i32)
    (local $found i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $p i32)
    i32.const 0
    local.set $found
    local.get $self
    i32.load ;; .pairs
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
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
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $p
    local.get $p
    i32.load
    local.get $key
    i32.eq
    (if (result i32)
      (then
    local.get $p
    i32.load offset=4
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
  (func $Dict_hasKey (param $self i32) (param $key i32) (result i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $__out0 i32)
    (local $p i32)
    local.get $self
    i32.load ;; .pairs
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    call $__arr_new
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
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $p
    local.get $p
    i32.load
    local.get $key
    i32.eq
    (if
      (then
    local.get $__out0
    local.get $__acc0
    i32.const 4
    i32.mul
    i32.add
    local.get $__iter0
    local.get $__idx0
    i32.const 4
    i32.mul
    i32.add
    i32.load offset=4
    i32.store offset=4
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
    local.get $__acc0
    i32.store ;; kept count
    local.get $__out0
    i32.const 0
    call $__arr_at_box
    i32.const 0
    i32.ne
    return
  )
  (func $Dict_size (param $self i32) (result i32)
    local.get $self
    i32.load ;; .pairs
    i32.load ;; .length
    return
  )
  (func $Dict_isEmpty (param $self i32) (result i32)
    local.get $self
    i32.load ;; .pairs
    i32.load ;; .length
    i32.const 0
    i32.eq
    return
  )
  (func $Dict_keys (param $self i32) (result i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $__out0 i32)
    (local $p i32)
    local.get $self
    i32.load ;; .pairs
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    call $__arr_new
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
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $p
    local.get $__out0
    local.get $__idx0
    i32.const 4
    i32.mul
    i32.add
    local.get $p
    i32.load
    i32.store offset=4
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
  (func $Dict_values (param $self i32) (result i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $__out0 i32)
    (local $p i32)
    local.get $self
    i32.load ;; .pairs
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    call $__arr_new
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
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $p
    local.get $__out0
    local.get $__idx0
    i32.const 4
    i32.mul
    i32.add
    local.get $p
    i32.load offset=4
    i32.store offset=4
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
  (func $Dict_insert (param $self i32) (param $key i32) (param $value i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $filtered i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $__out0 i32)
    (local $p i32)
    local.get $self
    i32.load ;; .pairs
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    call $__arr_new
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
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $p
    local.get $p
    i32.load
    local.get $key
    i32.ne
    (if
      (then
    local.get $__out0
    local.get $__acc0
    i32.const 4
    i32.mul
    i32.add
    local.get $__iter0
    local.get $__idx0
    i32.const 4
    i32.mul
    i32.add
    i32.load offset=4
    i32.store offset=4
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
    local.get $__acc0
    i32.store ;; kept count
    local.get $__out0
    local.set $filtered
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 260
    i32.store
    local.get $__mem0
    local.get $filtered
    global.get $__heap_ptr
    local.set $__mem1
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem1
    i32.const 1
    i32.store
    local.get $__mem1
    global.get $__heap_ptr
    local.set $__mem2
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem2
    local.get $key
    i32.store
    local.get $__mem2
    local.get $value
    i32.store offset=4
    local.get $__mem2
    i32.store offset=4
    local.get $__mem1
    call $__arr_concat
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  (func $Dict_delete (param $self i32) (param $key i32) (result i32)
    (local $__mem0 i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $__out0 i32)
    (local $p i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 260
    i32.store
    local.get $__mem0
    local.get $self
    i32.load ;; .pairs
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    call $__arr_new
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
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $p
    local.get $p
    i32.load
    local.get $key
    i32.ne
    (if
      (then
    local.get $__out0
    local.get $__acc0
    i32.const 4
    i32.mul
    i32.add
    local.get $__iter0
    local.get $__idx0
    i32.const 4
    i32.mul
    i32.add
    i32.load offset=4
    i32.store offset=4
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
    local.get $__acc0
    i32.store ;; kept count
    local.get $__out0
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  (func $Dict_merge (param $self i32) (param $other i32) (result i32)
    (local $out i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $p i32)
    local.get $self
    local.set $out
    local.get $other
    i32.load ;; .pairs
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
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
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $p
    local.get $out
    local.get $p
    i32.load
    local.get $p
    i32.load offset=4
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
  (func $Dict_fold (param $self i32) (param $initial i32) (param $f i32) (result i32)
    (local $acc i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $p i32)
    (local $__fnv1 i32)
    local.get $initial
    local.set $acc
    local.get $self
    i32.load ;; .pairs
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
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
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $p
    local.get $f
    local.set $__fnv1
    local.get $__fnv1
    local.get $acc
    local.get $p
    i32.load
    local.get $p
    i32.load offset=4
    local.get $__fnv1
    i32.load ;; table index
    call_indirect (param i32 i32 i32 i32) (result i32)
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
  (func $Dict_mapValues (param $self i32) (param $f i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $out i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $p i32)
    (local $__fnv1 i32)
    (local $__mem2 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 4
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 0
    i32.store
    local.get $__mem0
    local.set $out
    local.get $self
    i32.load ;; .pairs
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
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
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $p
    local.get $out
    global.get $__heap_ptr
    local.set $__mem1
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem1
    local.get $p
    i32.load
    i32.store
    local.get $__mem1
    local.get $f
    local.set $__fnv1
    local.get $__fnv1
    local.get $p
    i32.load offset=4
    local.get $__fnv1
    i32.load ;; table index
    call_indirect (param i32 i32) (result i32)
    i32.store offset=4
    local.get $__mem1
    call $__arr_push
    local.set $out
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    global.get $__heap_ptr
    local.set $__mem2
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem2
    i32.const 260
    i32.store
    local.get $__mem2
    local.get $out
    i32.store offset=4
    local.get $__mem2
    i32.const 4
    i32.add
    return
  )
  (func $Dict_empty (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 260
    i32.store
    local.get $__mem0
    global.get $__heap_ptr
    local.set $__mem1
    global.get $__heap_ptr
    i32.const 4
    i32.add
    global.set $__heap_ptr
    local.get $__mem1
    i32.const 0
    i32.store
    local.get $__mem1
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  (func $Set_contains (param $self i32) (param $x i32) (result i32)
    local.get $self
    i32.load ;; .items
    local.get $x
    call $__arr_index_of_i32
    i32.const 0
    i32.const 1
    i32.sub
    i32.ne
    return
  )
  (func $Set_size (param $self i32) (result i32)
    local.get $self
    i32.load ;; .items
    i32.load ;; .length
    return
  )
  (func $Set_isEmpty (param $self i32) (result i32)
    local.get $self
    i32.load ;; .items
    i32.load ;; .length
    i32.const 0
    i32.eq
    return
  )
  (func $Set_toList (param $self i32) (result i32)
    local.get $self
    i32.load ;; .items
    return
  )
  (func $Set_insert (param $self i32) (param $x i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    local.get $self
    i32.load ;; .items
    local.get $x
    call $__arr_index_of_i32
    i32.const 0
    i32.const 1
    i32.sub
    i32.ne
    (if (result i32)
      (then
    local.get $self
      )
      (else
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 280
    i32.store
    local.get $__mem0
    local.get $self
    i32.load ;; .items
    global.get $__heap_ptr
    local.set $__mem1
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem1
    i32.const 1
    i32.store
    local.get $__mem1
    local.get $x
    i32.store offset=4
    local.get $__mem1
    call $__arr_concat
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
      )
    )
    return
  )
  (func $Set_delete (param $self i32) (param $x i32) (result i32)
    (local $__mem0 i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $__out0 i32)
    (local $item i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 280
    i32.store
    local.get $__mem0
    local.get $self
    i32.load ;; .items
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    call $__arr_new
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
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $item
    local.get $item
    local.get $x
    i32.ne
    (if
      (then
    local.get $__out0
    local.get $__acc0
    i32.const 4
    i32.mul
    i32.add
    local.get $__iter0
    local.get $__idx0
    i32.const 4
    i32.mul
    i32.add
    i32.load offset=4
    i32.store offset=4
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
    local.get $__acc0
    i32.store ;; kept count
    local.get $__out0
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  (func $Set_union (param $self i32) (param $other i32) (result i32)
    (local $out i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $x i32)
    local.get $self
    local.set $out
    local.get $other
    i32.load ;; .items
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
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
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
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
  (func $Set_intersection (param $self i32) (param $other i32) (result i32)
    (local $__mem0 i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $__out0 i32)
    (local $x i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 280
    i32.store
    local.get $__mem0
    local.get $self
    i32.load ;; .items
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    call $__arr_new
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
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $x
    local.get $other
    i32.load ;; .items
    local.get $x
    call $__arr_index_of_i32
    i32.const 0
    i32.const 1
    i32.sub
    i32.ne
    (if
      (then
    local.get $__out0
    local.get $__acc0
    i32.const 4
    i32.mul
    i32.add
    local.get $__iter0
    local.get $__idx0
    i32.const 4
    i32.mul
    i32.add
    i32.load offset=4
    i32.store offset=4
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
    local.get $__acc0
    i32.store ;; kept count
    local.get $__out0
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  (func $Set_difference (param $self i32) (param $other i32) (result i32)
    (local $__mem0 i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $__out0 i32)
    (local $x i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 280
    i32.store
    local.get $__mem0
    local.get $self
    i32.load ;; .items
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    call $__arr_new
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
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $x
    local.get $other
    i32.load ;; .items
    local.get $x
    call $__arr_index_of_i32
    i32.const 0
    i32.const 1
    i32.sub
    i32.eq
    (if
      (then
    local.get $__out0
    local.get $__acc0
    i32.const 4
    i32.mul
    i32.add
    local.get $__iter0
    local.get $__idx0
    i32.const 4
    i32.mul
    i32.add
    i32.load offset=4
    i32.store offset=4
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
    local.get $__acc0
    i32.store ;; kept count
    local.get $__out0
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  (func $Set_empty (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 280
    i32.store
    local.get $__mem0
    global.get $__heap_ptr
    local.set $__mem1
    global.get $__heap_ptr
    i32.const 4
    i32.add
    global.set $__heap_ptr
    local.get $__mem1
    i32.const 0
    i32.store
    local.get $__mem1
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  (func $Set_fromList (param $xs i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $out i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $x i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 280
    i32.store
    local.get $__mem0
    global.get $__heap_ptr
    local.set $__mem1
    global.get $__heap_ptr
    i32.const 4
    i32.add
    global.set $__heap_ptr
    local.get $__mem1
    i32.const 0
    i32.store
    local.get $__mem1
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
    local.set $out
    local.get $xs
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
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
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
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
  (func $Queue_size (param $self i32) (result i32)
    local.get $self
    i32.load ;; .items
    i32.load ;; .length
    return
  )
  (func $Queue_isEmpty (param $self i32) (result i32)
    local.get $self
    i32.load ;; .items
    i32.load ;; .length
    i32.const 0
    i32.eq
    return
  )
  (func $Queue_enqueue (param $self i32) (param $item i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 300
    i32.store
    local.get $__mem0
    local.get $self
    i32.load ;; .items
    global.get $__heap_ptr
    local.set $__mem1
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem1
    i32.const 1
    i32.store
    local.get $__mem1
    local.get $item
    i32.store offset=4
    local.get $__mem1
    call $__arr_concat
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  (func $Queue_dequeue (param $self i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $head i32)
    (local $rest i32)
    local.get $self
    i32.load ;; .items
    i32.const 0
    call $__arr_at_box
    local.set $head
    local.get $self
    i32.load ;; .items
    i32.const 1
    local.get $self
    i32.load ;; .items
    i32.load ;; .length
    call $__arr_slice
    local.set $rest
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    global.get $__heap_ptr
    local.set $__mem1
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem1
    i32.const 300
    i32.store
    local.get $__mem1
    local.get $rest
    i32.store offset=4
    local.get $__mem1
    i32.const 4
    i32.add
    i32.store
    local.get $__mem0
    local.get $head
    i32.store offset=4
    local.get $__mem0
    return
  )
  (func $Queue_peek (param $self i32) (result i32)
    local.get $self
    i32.load ;; .items
    i32.const 0
    call $__arr_at_box
    return
  )
  (func $Queue_toList (param $self i32) (result i32)
    local.get $self
    i32.load ;; .items
    return
  )
  (func $Queue_empty (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 300
    i32.store
    local.get $__mem0
    global.get $__heap_ptr
    local.set $__mem1
    global.get $__heap_ptr
    i32.const 4
    i32.add
    global.set $__heap_ptr
    local.get $__mem1
    i32.const 0
    i32.store
    local.get $__mem1
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  (func $Queue_fromList (param $xs i32) (result i32)
    (local $__mem0 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 300
    i32.store
    local.get $__mem0
    local.get $xs
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  (func $lt (result i32)
    i32.const 0 ;; Order.Lt
    return
  )
  (func $eq (result i32)
    i32.const 1 ;; Order.Eq
    return
  )
  (func $gt (result i32)
    i32.const 2 ;; Order.Gt
    return
  )
  (func $toInt (param $o i32) (result i32)
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
    i32.sub
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
    (local $d i32)
    call $Dict_empty
    local.set $d
    local.get $d
    i32.const 316
    i32.const 1
    call $Dict_insert
    call $Dict_size
    call $__print_i32
    call $gt
    call $reverse
    call $toInt
    call $__print_i32
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
  ;; Scratch layout below the data section (which starts at 256):
  ;;   0..8  WASI iovec   8  newline byte
  ;;  16..32 bool text   32..64 float fraction   64..128 i32 digits
  (func $__write_bytes (param $p i32) (param $n i32)
    i32.const 0
    local.get $p
    i32.store
    i32.const 4
    local.get $n
    i32.store
    i32.const 1
    i32.const 0
    i32.const 1
    i32.const 8
    call $fd_write
    drop
  )
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
  (func $__alloc (param $n i32) (result i32)
    (local $p i32)
    global.get $__heap_ptr
    local.set $p
    global.get $__heap_ptr
    local.get $n
    i32.add
    i32.const 3
    i32.add
    i32.const -4
    i32.and
    global.set $__heap_ptr
    local.get $p
  )
  (func $__arr_new (param $n i32) (result i32)
    (local $p i32)
    local.get $n
    i32.const 1
    i32.add
    i32.const 4
    i32.mul
    call $__alloc
    local.set $p
    local.get $p
    local.get $n
    i32.store
    local.get $p
  )
  (func $__arr_slice (param $xs i32) (param $a i32) (param $b i32) (result i32)
    (local $n i32) (local $cnt i32) (local $p i32)
    local.get $xs
    i32.load
    local.set $n
    local.get $a
    i32.const 0
    i32.lt_s
    (if
      (then
        local.get $n
        local.get $a
        i32.add
        local.set $a
        local.get $a
        i32.const 0
        i32.lt_s
        (if
          (then
            i32.const 0
            local.set $a
          )
        )
      )
      (else
        local.get $a
        local.get $n
        i32.gt_s
        (if
          (then
            local.get $n
            local.set $a
          )
        )
      )
    )
    local.get $b
    i32.const 0
    i32.lt_s
    (if
      (then
        local.get $n
        local.get $b
        i32.add
        local.set $b
        local.get $b
        i32.const 0
        i32.lt_s
        (if
          (then
            i32.const 0
            local.set $b
          )
        )
      )
      (else
        local.get $b
        local.get $n
        i32.gt_s
        (if
          (then
            local.get $n
            local.set $b
          )
        )
      )
    )
    local.get $b
    local.get $a
    i32.sub
    local.set $cnt
    local.get $cnt
    i32.const 0
    i32.lt_s
    (if
      (then
        i32.const 0
        local.set $cnt
      )
    )
    local.get $cnt
    call $__arr_new
    local.set $p
    local.get $p
    i32.const 4
    i32.add
    local.get $xs
    i32.const 4
    i32.add
    local.get $a
    i32.const 4
    i32.mul
    i32.add
    local.get $cnt
    i32.const 4
    i32.mul
    memory.copy
    local.get $p
  )
  (func $__arr_push (param $xs i32) (param $x i32) (result i32)
    (local $n i32) (local $p i32)
    local.get $xs
    i32.load
    local.set $n
    local.get $n
    i32.const 1
    i32.add
    call $__arr_new
    local.set $p
    local.get $p
    i32.const 4
    i32.add
    local.get $xs
    i32.const 4
    i32.add
    local.get $n
    i32.const 4
    i32.mul
    memory.copy
    local.get $p
    i32.const 4
    i32.add
    local.get $n
    i32.const 4
    i32.mul
    i32.add
    local.get $x
    i32.store
    local.get $p
  )
  (func $__arr_concat (param $a i32) (param $b i32) (result i32)
    (local $na i32) (local $nb i32) (local $p i32)
    local.get $a
    i32.load
    local.set $na
    local.get $b
    i32.load
    local.set $nb
    local.get $na
    local.get $nb
    i32.add
    call $__arr_new
    local.set $p
    local.get $p
    i32.const 4
    i32.add
    local.get $a
    i32.const 4
    i32.add
    local.get $na
    i32.const 4
    i32.mul
    memory.copy
    local.get $p
    i32.const 4
    i32.add
    local.get $na
    i32.const 4
    i32.mul
    i32.add
    local.get $b
    i32.const 4
    i32.add
    local.get $nb
    i32.const 4
    i32.mul
    memory.copy
    local.get $p
  )
  (func $__arr_index_of_i32 (param $xs i32) (param $x i32) (result i32)
    (local $n i32) (local $i i32)
    local.get $xs
    i32.load
    local.set $n
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $xs
        i32.const 4
        i32.add
        local.get $i
        i32.const 4
        i32.mul
        i32.add
        i32.load
        local.get $x
        i32.eq
        (if
          (then
            local.get $i
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
    i32.const -1
  )
  (func $__box_i32 (param $v i32) (result i32)
    (local $p i32)
    i32.const 4
    call $__alloc
    local.set $p
    local.get $p
    local.get $v
    i32.store
    local.get $p
  )
  (func $__arr_at_box (param $xs i32) (param $i i32) (result i32)
    local.get $i
    i32.const 0
    i32.lt_s
    local.get $i
    local.get $xs
    i32.load
    i32.ge_s
    i32.or
    (if
      (then
        i32.const 0
        return
      )
    )
    local.get $xs
    i32.const 4
    i32.add
    local.get $i
    i32.const 4
    i32.mul
    i32.add
    i32.load
    call $__box_i32
  )
)
```

----- RUN LOG -----
```logs
1
-1
```
