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
) implement Index<K, V>, Display {
    // Decision 8 §7 — `Dict("a": 1, "b": 2)`: the pairs in order, a string
    // key or value quoted, anything else in its own text. `K` and `V` are
    // generic, so which is a string is asked of the value (`is`, decision 8 §4).
    pub fn display(self: Self<K, V>) -> string {
        var parts: string[] = [];
        self.pairs.forEach({ p -> parts.push(shown(p._0) + ": " + shown(p._1)) });
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
}

// One key or value of `Dict.display`: a string quoted, anything else as it
// interpolates.
fn shown<T>(x: T) -> string {
    if (x is string) {
        return "\"" + x + "\"";
    };
    return "${x}";
}

test "dict displays as its pairs, a string quoted (decision 8 §7)" {
    val d = Dict.empty().insert("a", 1).insert("b", 2);
    assert d.display() == "Dict(\"a\": 1, \"b\": 2)";
    val n = Dict.empty().insert(1, "x");
    assert n.display() == "Dict(1: \"x\")";
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
        return if (self.items.indexOf(x) != -1) self else Set(items: self.items.append(
                [x]
            ));
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
        return Set(items: self.items.filter({ x -> other.items.indexOf(x) != -1 }));
    }

    pub fn difference(self: Self<T>, other: Set<T>) -> Set<T> {
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

----- BEAM ASSEMBLY -- std/collections.S
```erlang
{module, std@collections}.
{exports, [{lt, 0}, {eq, 0}, {gt, 0}, {toInt, 1}, {reverse, 1}, {shown, 1}]}.
{attributes, []}.
{labels, 27}.
%%% std/collections — the four collection types, one namespace each (decision
%%% 106): `Dict<K, V>`, `Set<T>`, `Queue<T>` and `Order`. Was the four modules
%%% `dict`, `sets`, `queue` and `order`; the type is the namespace now, so a
%%% constructor is called on the type it builds (decision 111) —
%%% `Dict.empty()`, `Set.empty()` / `Set.fromList(xs)`, `Queue.empty()` /
%%% `Queue.fromList(xs)` — and every other function keeps its name.
% ── Dict<K, V> ──────────────────────────────────────────────────────────────
% `Dict` (was `dict`) — Gleam-inspired — a `type Dict<K, V>` wrapping an
% association list `pairs: Array<#(K, V)>` for full backend portability
% (no host-backing). O(n) read; camelCase convention.
% 
% Instance operations are `self`-methods on the record; `empty` is a
% type-scoped constructor, `Dict.empty()` (records hold state and are
% constructed — unlike interfaces, which are pure behaviour contracts).
% 
% `==` / `!=` on generic K uses structural equality (string/numeric keys —
% the common case). API naming note: `new`/`get` are keyword tokens — use
% `empty`/`at`.
% 
% `Dict<K, V>` answers the ambient `Index<K, V>` of `builtins.d.bp`
% (decision 63, amended), which is what makes `d["k"]` legal: the index
% expression has no typing rule of its own and rewrites to `d.at("k")`. The
% reader was spelled `lookup` until that amendment gave every indexable type
% one method name.
% One key or value of `Dict.display`: a string quoted, anything else as it
% interpolates.

{function, shown, 1, 3}.
  {label, 2}.
    {line, [{location, "std@collections.erl", 14}]}.
    {func_info, {atom, std@collections}, {atom, shown}, 1}.
  {label, 3}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 15}, [{x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 16}}.
  {label, 15}.
    {move, {atom, false}, {x, 0}}.
  {label, 16}.
    {test, is_eq, {f, 14}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"\"">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"\"">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 18}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 3}.
    return.
  {label, 14}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 18}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 3}.
    return.
% ── option method API over `at`'s `?V` (B1: Option map/flatMap/unwrapOr) ──
% ── empty-collection boundary (B1) ──
% ── Set<T> ──────────────────────────────────────────────────────────────────
% `Set` (was `sets`) — Gleam-inspired — a `type Set<T>` wrapping a deduplicated
% `Array<T>` (`items`). Pure botopink — no host backing. O(n) contains;
% uniqueness via `Array.indexOf` (structural equality — string/numeric elems).
% 
% Instance operations are `self`-methods on the record; `empty`/`fromList`
% are type-scoped constructors (`Set.empty()`, `Set.fromList(xs)`). API
% naming note: `new`/`set` are keyword tokens — the constructor is `empty`.
% ── empty-collection boundary (B1) ──
% ── Queue<T> ────────────────────────────────────────────────────────────────
% `Queue` (was `queue`) — Gleam-inspired — a `type Queue<T>` wrapping an `Array<T>`
% (front at index 0). Pure botopink — no host backing. O(n) enqueue (copy),
% O(1) peek.
% 
% Instance operations are `self`-methods on the record; `empty`/`fromList`
% are type-scoped constructors (`Queue.empty()`, `Queue.fromList(xs)`).
% `dequeue` returns `#(Queue<T>, ?T)` (the updated queue + the removed front
% item). API naming note: `new` is a keyword token —
% the constructor is `empty`.
% ── empty-collection boundary (B1) ──
% ── Order ───────────────────────────────────────────────────────────────────
% `Order` (was `order`) — Gleam-style, inspired by `gleam/order`. A sum type — the
% `type Order` (type-exported to importers) plus companion functions.
% Construct via the module fns (`collections.lt()`); `toInt`/`reverse` operate on
% an `Order`. Enums are concrete types, not interfaces.

{function, lt, 0, 5}.
  {label, 4}.
    {line, [{location, "std@collections.erl", 34}]}.
    {func_info, {atom, std@collections}, {atom, lt}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {move, {atom, std@collections@@Order__v__lt}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, eq, 0, 7}.
  {label, 6}.
    {line, [{location, "std@collections.erl", 35}]}.
    {func_info, {atom, std@collections}, {atom, eq}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {move, {atom, std@collections@@Order__v__eq}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, gt, 0, 9}.
  {label, 8}.
    {line, [{location, "std@collections.erl", 36}]}.
    {func_info, {atom, std@collections}, {atom, gt}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {move, {atom, std@collections@@Order__v__gt}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, toInt, 1, 11}.
  {label, 10}.
    {line, [{location, "std@collections.erl", 37}]}.
    {func_info, {atom, std@collections}, {atom, toInt}, 1}.
  {label, 11}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 22}, [{x, 0}, {atom, std@collections@@Order__v__lt}]}.
    {move, {integer, -1}, {x, 0}}.
    {jump, {f, 21}}.
  {label, 22}.
    {test, is_eq, {f, 23}, [{x, 0}, {atom, std@collections@@Order__v__eq}]}.
    {move, {integer, 0}, {x, 0}}.
    {jump, {f, 21}}.
  {label, 23}.
    {move, {integer, 1}, {x, 0}}.
    {jump, {f, 21}}.
  {label, 21}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, reverse, 1, 13}.
  {label, 12}.
    {line, [{location, "std@collections.erl", 38}]}.
    {func_info, {atom, std@collections}, {atom, reverse}, 1}.
  {label, 13}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 25}, [{x, 0}, {atom, std@collections@@Order__v__lt}]}.
    {move, {atom, std@collections@@Order__v__gt}, {x, 0}}.
    {jump, {f, 24}}.
  {label, 25}.
    {test, is_eq, {f, 26}, [{x, 0}, {atom, std@collections@@Order__v__gt}]}.
    {move, {atom, std@collections@@Order__v__lt}, {x, 0}}.
    {jump, {f, 24}}.
  {label, 26}.
    {move, {atom, std@collections@@Order__v__eq}, {x, 0}}.
    {jump, {f, 24}}.
  {label, 24}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '-bp_stringify-', 1, 18}.
  {label, 17}.
    {line, [{location, "std@collections.erl", 15}]}.
    {func_info, {atom, std@collections}, {atom, '-bp_stringify-'}, 1}.
  {label, 18}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 19}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 19}.
    {test, is_integer, {f, 20}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 20}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 0}.
```

----- BEAM ASSEMBLY -- std@collections@@Dict.S
```erlang
{module, std@collections@@Dict}.
{exports, [{display, 1}, {at, 2}, {hasKey, 2}, {size, 1}, {isEmpty, 1}, {keys, 1}, {values, 1}, {insert, 3}, {delete, 2}, {merge, 2}, {fold, 3}, {mapValues, 2}, {empty, 0}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 86}.

{function, display, 1, 3}.
  {label, 2}.
    {line, [{location, "std@collections@@Dict.erl", 1}]}.
    {func_info, {atom, std@collections@@Dict}, {atom, display}, 1}.
  {label, 3}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 34}, [{x, 0}, 2, {atom, std@collections@@Dict}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 34}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 29}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<")">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 36}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"Dict(">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 31}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 3}.
    return.

{function, at, 2, 5}.
  {label, 4}.
    {line, [{location, "std@collections@@Dict.erl", 2}]}.
    {func_info, {atom, std@collections@@Dict}, {atom, at}, 2}.
  {label, 5}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 41}, [{x, 0}, 2, {atom, std@collections@@Dict}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 41}.
    {move, {y, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 38}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, hasKey, 2, 7}.
  {label, 6}.
    {line, [{location, "std@collections@@Dict.erl", 3}]}.
    {func_info, {atom, std@collections@@Dict}, {atom, hasKey}, 2}.
  {label, 7}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 42}, [{x, 0}, 2, {atom, std@collections@@Dict}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 42}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 44}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 48}}.
    {test, is_ne_exact, {f, 50}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 51}}.
  {label, 50}.
    {move, {atom, false}, {x, 0}}.
  {label, 51}.
    {deallocate, 4}.
    return.

{function, size, 1, 9}.
  {label, 8}.
    {line, [{location, "std@collections@@Dict.erl", 4}]}.
    {func_info, {atom, std@collections@@Dict}, {atom, size}, 1}.
  {label, 9}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 52}, [{x, 0}, 2, {atom, std@collections@@Dict}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 52}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {deallocate, 1}.
    return.

{function, isEmpty, 1, 11}.
  {label, 10}.
    {line, [{location, "std@collections@@Dict.erl", 5}]}.
    {func_info, {atom, std@collections@@Dict}, {atom, isEmpty}, 1}.
  {label, 11}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 53}, [{x, 0}, 2, {atom, std@collections@@Dict}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 53}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 54}, [{x, 0}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 55}}.
  {label, 54}.
    {move, {atom, false}, {x, 0}}.
  {label, 55}.
    {deallocate, 1}.
    return.

{function, keys, 1, 13}.
  {label, 12}.
    {line, [{location, "std@collections@@Dict.erl", 6}]}.
    {func_info, {atom, std@collections@@Dict}, {atom, keys}, 1}.
  {label, 13}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 56}, [{x, 0}, 2, {atom, std@collections@@Dict}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 56}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 58}, 0, 0, {x, 0}, {list, []}}.
    {call_ext_last, 2, {extfunc, lists, map, 2}, 1}.

{function, values, 1, 15}.
  {label, 14}.
    {line, [{location, "std@collections@@Dict.erl", 7}]}.
    {func_info, {atom, std@collections@@Dict}, {atom, values}, 1}.
  {label, 15}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 59}, [{x, 0}, 2, {atom, std@collections@@Dict}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 59}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 61}, 0, 0, {x, 0}, {list, []}}.
    {call_ext_last, 2, {extfunc, lists, map, 2}, 1}.

{function, insert, 3, 17}.
  {label, 16}.
    {line, [{location, "std@collections@@Dict.erl", 8}]}.
    {func_info, {atom, std@collections@@Dict}, {atom, insert}, 3}.
  {label, 17}.
    {allocate, 5, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 62}, [{x, 0}, 2, {atom, std@collections@@Dict}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 62}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 64}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 1}, {y, 2}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@collections@@Dict}, {x, 0}]}}.
    {deallocate, 5}.
    return.

{function, delete, 2, 19}.
  {label, 18}.
    {line, [{location, "std@collections@@Dict.erl", 9}]}.
    {func_info, {atom, std@collections@@Dict}, {atom, delete}, 2}.
  {label, 19}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 67}, [{x, 0}, 2, {atom, std@collections@@Dict}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 67}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 69}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@collections@@Dict}, {x, 0}]}}.
    {deallocate, 2}.
    return.

{function, merge, 2, 21}.
  {label, 20}.
    {line, [{location, "std@collections@@Dict.erl", 10}]}.
    {func_info, {atom, std@collections@@Dict}, {atom, merge}, 2}.
  {label, 21}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 74}, [{x, 0}, 2, {atom, std@collections@@Dict}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 74}.
    {move, {y, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 73}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, fold, 3, 23}.
  {label, 22}.
    {line, [{location, "std@collections@@Dict.erl", 11}]}.
    {func_info, {atom, std@collections@@Dict}, {atom, fold}, 3}.
  {label, 23}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 77}, [{x, 0}, 2, {atom, std@collections@@Dict}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 77}.
    {move, {y, 3}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 76}, 0, 0, {x, 0}, {list, [{y, 2}]}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, mapValues, 2, 25}.
  {label, 24}.
    {line, [{location, "std@collections@@Dict.erl", 12}]}.
    {func_info, {atom, std@collections@@Dict}, {atom, mapValues}, 2}.
  {label, 25}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 80}, [{x, 0}, 2, {atom, std@collections@@Dict}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 80}.
    {move, {y, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 79}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@collections@@Dict}, {y, 2}]}}.
    {deallocate, 3}.
    return.

{function, empty, 0, 27}.
  {label, 26}.
    {line, [{location, "std@collections@@Dict.erl", 13}]}.
    {func_info, {atom, std@collections@@Dict}, {atom, empty}, 0}.
  {label, 27}.
    {allocate, 0, 0}.
    {move, nil, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@collections@@Dict}, {x, 0}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_get', 2, 82}.
  {label, 81}.
    {line, [{location, "std@collections@@Dict.erl", 14}]}.
    {func_info, {atom, std@collections@@Dict}, {atom, '__bp_get'}, 2}.
  {label, 82}.
    {test, is_eq_exact, {f, 83}, [{x, 1}, {atom, pairs}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 83}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 85}.
  {label, 84}.
    {line, [{location, "std@collections@@Dict.erl", 14}]}.
    {func_info, {atom, std@collections@@Dict}, {atom, '__bp_format'}, 1}.
  {label, 85}.
    {allocate, 0, 1}.
    {call, 1, {f, 3}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, text}, {x, 0}]}}.
    {deallocate, 0}.
    return.

{function, '-bp_stringify-', 1, 31}.
  {label, 30}.
    {line, [{location, "std@collections@@Dict.erl", 2}]}.
    {func_info, {atom, std@collections@@Dict}, {atom, '-bp_stringify-'}, 1}.
  {label, 31}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 32}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 32}.
    {test, is_integer, {f, 33}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 33}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 0}.

{function, '-/1-fun-0-', 2, 29}.
  {label, 28}.
    {line, [{location, "std@collections@@Dict.erl", 2}]}.
    {func_info, {atom, std@collections@@Dict}, {atom, '-/1-fun-0-'}, 2}.
  {label, 29}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {call_ext, 1, {extfunc, std@collections, shown, 1}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<": ">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {call_ext, 1, {extfunc, std@collections, shown, 1}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 31}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '-bp_join-', 2, 36}.
  {label, 35}.
    {line, [{location, "std@collections@@Dict.erl", 2}]}.
    {func_info, {atom, std@collections@@Dict}, {atom, '-bp_join-'}, 2}.
  {label, 36}.
    {allocate, 1, 2}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 31}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 1}.

{function, '-/2-fun-1-', 3, 38}.
  {label, 37}.
    {line, [{location, "std@collections@@Dict.erl", 3}]}.
    {func_info, {atom, std@collections@@Dict}, {atom, '-/2-fun-1-'}, 3}.
  {label, 38}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 39}, [{x, 0}, {y, 2}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 40}}.
  {label, 39}.
  {label, 40}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '-/2-fun-2-', 2, 44}.
  {label, 43}.
    {line, [{location, "std@collections@@Dict.erl", 4}]}.
    {func_info, {atom, std@collections@@Dict}, {atom, '-/2-fun-2-'}, 2}.
  {label, 44}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 45}, [{x, 0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 46}}.
  {label, 45}.
    {move, {atom, false}, {x, 0}}.
  {label, 46}.
    {deallocate, 2}.
    return.

{function, '-bp_at-', 2, 48}.
  {label, 47}.
    {line, [{location, "std@collections@@Dict.erl", 4}]}.
    {func_info, {atom, std@collections@@Dict}, {atom, '-bp_at-'}, 2}.
  {label, 48}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {test, is_ge, {f, 49}, [{y, 0}, {integer, 0}]}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_lt, {f, 49}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 49}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-/1-fun-3-', 1, 58}.
  {label, 57}.
    {line, [{location, "std@collections@@Dict.erl", 7}]}.
    {func_info, {atom, std@collections@@Dict}, {atom, '-/1-fun-3-'}, 1}.
  {label, 58}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {deallocate, 1}.
    return.

{function, '-/1-fun-4-', 1, 61}.
  {label, 60}.
    {line, [{location, "std@collections@@Dict.erl", 8}]}.
    {func_info, {atom, std@collections@@Dict}, {atom, '-/1-fun-4-'}, 1}.
  {label, 61}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {deallocate, 1}.
    return.

{function, '-/3-fun-5-', 2, 64}.
  {label, 63}.
    {line, [{location, "std@collections@@Dict.erl", 9}]}.
    {func_info, {atom, std@collections@@Dict}, {atom, '-/3-fun-5-'}, 2}.
  {label, 64}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_ne_exact, {f, 65}, [{x, 0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 66}}.
  {label, 65}.
    {move, {atom, false}, {x, 0}}.
  {label, 66}.
    {deallocate, 2}.
    return.

{function, '-/2-fun-6-', 2, 69}.
  {label, 68}.
    {line, [{location, "std@collections@@Dict.erl", 10}]}.
    {func_info, {atom, std@collections@@Dict}, {atom, '-/2-fun-6-'}, 2}.
  {label, 69}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_ne_exact, {f, 70}, [{x, 0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 71}}.
  {label, 70}.
    {move, {atom, false}, {x, 0}}.
  {label, 71}.
    {deallocate, 2}.
    return.

{function, '-/2-fun-7-', 2, 73}.
  {label, 72}.
    {line, [{location, "std@collections@@Dict.erl", 11}]}.
    {func_info, {atom, std@collections@@Dict}, {atom, '-/2-fun-7-'}, 2}.
  {label, 73}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {y, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call, 3, {f, 17}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '-/3-fun-8-', 3, 76}.
  {label, 75}.
    {line, [{location, "std@collections@@Dict.erl", 12}]}.
    {func_info, {atom, std@collections@@Dict}, {atom, '-/3-fun-8-'}, 3}.
  {label, 76}.
    {allocate, 6, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {y, 3}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 3}}.
    {call_fun, 3}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 6}.
    return.

{function, '-/2-fun-9-', 3, 79}.
  {label, 78}.
    {line, [{location, "std@collections@@Dict.erl", 13}]}.
    {func_info, {atom, std@collections@@Dict}, {atom, '-/2-fun-9-'}, 3}.
  {label, 79}.
    {allocate, 7, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {y, 2}, {x, 1}}.
    {call_fun, 1}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{y, 3}, {x, 0}]}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 7}.
    return.
```

----- BEAM ASSEMBLY -- std@collections@@Set.S
```erlang
{module, std@collections@@Set}.
{exports, [{contains, 2}, {size, 1}, {isEmpty, 1}, {toList, 1}, {insert, 2}, {delete, 2}, {union, 2}, {intersection, 2}, {difference, 2}, {empty, 0}, {fromList, 1}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 67}.

{function, contains, 2, 3}.
  {label, 2}.
    {line, [{location, "std@collections@@Set.erl", 15}]}.
    {func_info, {atom, std@collections@@Set}, {atom, contains}, 2}.
  {label, 3}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 24}, [{x, 0}, 2, {atom, std@collections@@Set}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 24}.
    {move, {y, 1}, {x, 1}}.
    {move, {integer, 0}, {x, 2}}.
    {call, 3, {f, 26}}.
    {test, is_ne_exact, {f, 29}, [{x, 0}, {integer, -1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 30}}.
  {label, 29}.
    {move, {atom, false}, {x, 0}}.
  {label, 30}.
    {deallocate, 2}.
    return.

{function, size, 1, 5}.
  {label, 4}.
    {line, [{location, "std@collections@@Set.erl", 16}]}.
    {func_info, {atom, std@collections@@Set}, {atom, size}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 31}, [{x, 0}, 2, {atom, std@collections@@Set}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 31}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {deallocate, 1}.
    return.

{function, isEmpty, 1, 7}.
  {label, 6}.
    {line, [{location, "std@collections@@Set.erl", 17}]}.
    {func_info, {atom, std@collections@@Set}, {atom, isEmpty}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 32}, [{x, 0}, 2, {atom, std@collections@@Set}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 32}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 33}, [{x, 0}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 34}}.
  {label, 33}.
    {move, {atom, false}, {x, 0}}.
  {label, 34}.
    {deallocate, 1}.
    return.

{function, toList, 1, 9}.
  {label, 8}.
    {line, [{location, "std@collections@@Set.erl", 18}]}.
    {func_info, {atom, std@collections@@Set}, {atom, toList}, 1}.
  {label, 9}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 35}, [{x, 0}, 2, {atom, std@collections@@Set}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 35}.
    {deallocate, 1}.
    return.

{function, insert, 2, 11}.
  {label, 10}.
    {line, [{location, "std@collections@@Set.erl", 19}]}.
    {func_info, {atom, std@collections@@Set}, {atom, insert}, 2}.
  {label, 11}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 37}, [{x, 0}, 2, {atom, std@collections@@Set}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 37}.
    {move, {y, 1}, {x, 1}}.
    {move, {integer, 0}, {x, 2}}.
    {call, 3, {f, 26}}.
    {test, is_ne_exact, {f, 36}, [{x, 0}, {integer, -1}]}.
    {move, {y, 0}, {x, 0}}.
    {jump, {f, 38}}.
  {label, 36}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 39}, [{x, 0}, 2, {atom, std@collections@@Set}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 39}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@collections@@Set}, {x, 0}]}}.
  {label, 38}.
    {deallocate, 3}.
    return.

{function, delete, 2, 13}.
  {label, 12}.
    {line, [{location, "std@collections@@Set.erl", 20}]}.
    {func_info, {atom, std@collections@@Set}, {atom, delete}, 2}.
  {label, 13}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 40}, [{x, 0}, 2, {atom, std@collections@@Set}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 40}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 42}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@collections@@Set}, {x, 0}]}}.
    {deallocate, 2}.
    return.

{function, union, 2, 15}.
  {label, 14}.
    {line, [{location, "std@collections@@Set.erl", 21}]}.
    {func_info, {atom, std@collections@@Set}, {atom, union}, 2}.
  {label, 15}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 47}, [{x, 0}, 2, {atom, std@collections@@Set}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 47}.
    {move, {y, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 46}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, intersection, 2, 17}.
  {label, 16}.
    {line, [{location, "std@collections@@Set.erl", 22}]}.
    {func_info, {atom, std@collections@@Set}, {atom, intersection}, 2}.
  {label, 17}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 48}, [{x, 0}, 2, {atom, std@collections@@Set}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 48}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 50}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@collections@@Set}, {x, 0}]}}.
    {deallocate, 2}.
    return.

{function, difference, 2, 19}.
  {label, 18}.
    {line, [{location, "std@collections@@Set.erl", 23}]}.
    {func_info, {atom, std@collections@@Set}, {atom, difference}, 2}.
  {label, 19}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 54}, [{x, 0}, 2, {atom, std@collections@@Set}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 54}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 56}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@collections@@Set}, {x, 0}]}}.
    {deallocate, 2}.
    return.

{function, empty, 0, 21}.
  {label, 20}.
    {line, [{location, "std@collections@@Set.erl", 24}]}.
    {func_info, {atom, std@collections@@Set}, {atom, empty}, 0}.
  {label, 21}.
    {allocate, 0, 0}.
    {move, nil, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@collections@@Set}, {x, 0}]}}.
    {deallocate, 0}.
    return.

{function, fromList, 1, 23}.
  {label, 22}.
    {line, [{location, "std@collections@@Set.erl", 25}]}.
    {func_info, {atom, std@collections@@Set}, {atom, fromList}, 1}.
  {label, 23}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@collections@@Set}, {x, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 61}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_get', 2, 63}.
  {label, 62}.
    {line, [{location, "std@collections@@Set.erl", 26}]}.
    {func_info, {atom, std@collections@@Set}, {atom, '__bp_get'}, 2}.
  {label, 63}.
    {test, is_eq_exact, {f, 64}, [{x, 1}, {atom, items}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 64}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 66}.
  {label, 65}.
    {line, [{location, "std@collections@@Set.erl", 26}]}.
    {func_info, {atom, std@collections@@Set}, {atom, '__bp_format'}, 1}.
  {label, 66}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"items">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Set">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.

{function, '-bp_indexOf-', 3, 26}.
  {label, 25}.
    {line, [{location, "std@collections@@Set.erl", 16}]}.
    {func_info, {atom, std@collections@@Set}, {atom, '-bp_indexOf-'}, 3}.
  {label, 26}.
    {test, is_nonempty_list, {f, 27}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 3}, {x, 4}}.
    {test, is_eq, {f, 28}, [{x, 3}, {x, 1}]}.
    {move, {x, 2}, {x, 0}}.
    return.
  {label, 28}.
    {move, {x, 4}, {x, 0}}.
    {gc_bif, '+', {f, 0}, 3, [{x, 2}, {integer, 1}], {x, 2}}.
    {call_only, 3, {f, 26}}.
  {label, 27}.
    {move, {integer, -1}, {x, 0}}.
    return.

{function, '-shown/2-fun-0-', 2, 42}.
  {label, 41}.
    {line, [{location, "std@collections@@Set.erl", 21}]}.
    {func_info, {atom, std@collections@@Set}, {atom, '-shown/2-fun-0-'}, 2}.
  {label, 42}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ne_exact, {f, 43}, [{y, 0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 44}}.
  {label, 43}.
    {move, {atom, false}, {x, 0}}.
  {label, 44}.
    {deallocate, 2}.
    return.

{function, '-shown/2-fun-1-', 2, 46}.
  {label, 45}.
    {line, [{location, "std@collections@@Set.erl", 22}]}.
    {func_info, {atom, std@collections@@Set}, {atom, '-shown/2-fun-1-'}, 2}.
  {label, 46}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call, 2, {f, 11}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-shown/2-fun-2-', 2, 50}.
  {label, 49}.
    {line, [{location, "std@collections@@Set.erl", 23}]}.
    {func_info, {atom, std@collections@@Set}, {atom, '-shown/2-fun-2-'}, 2}.
  {label, 50}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 51}, [{x, 0}, 2, {atom, std@collections@@Set}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 51}.
    {move, {y, 0}, {x, 1}}.
    {move, {integer, 0}, {x, 2}}.
    {call, 3, {f, 26}}.
    {test, is_ne_exact, {f, 52}, [{x, 0}, {integer, -1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 53}}.
  {label, 52}.
    {move, {atom, false}, {x, 0}}.
  {label, 53}.
    {deallocate, 2}.
    return.

{function, '-shown/2-fun-3-', 2, 56}.
  {label, 55}.
    {line, [{location, "std@collections@@Set.erl", 24}]}.
    {func_info, {atom, std@collections@@Set}, {atom, '-shown/2-fun-3-'}, 2}.
  {label, 56}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 57}, [{x, 0}, 2, {atom, std@collections@@Set}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 57}.
    {move, {y, 0}, {x, 1}}.
    {move, {integer, 0}, {x, 2}}.
    {call, 3, {f, 26}}.
    {test, is_eq_exact, {f, 58}, [{x, 0}, {integer, -1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 59}}.
  {label, 58}.
    {move, {atom, false}, {x, 0}}.
  {label, 59}.
    {deallocate, 2}.
    return.

{function, '-shown/1-fun-4-', 2, 61}.
  {label, 60}.
    {line, [{location, "std@collections@@Set.erl", 26}]}.
    {func_info, {atom, std@collections@@Set}, {atom, '-shown/1-fun-4-'}, 2}.
  {label, 61}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call, 2, {f, 11}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- std@collections@@Queue.S
```erlang
{module, std@collections@@Queue}.
{exports, [{size, 1}, {isEmpty, 1}, {enqueue, 2}, {dequeue, 1}, {peek, 1}, {toList, 1}, {empty, 0}, {fromList, 1}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 38}.

{function, size, 1, 3}.
  {label, 2}.
    {line, [{location, "std@collections@@Queue.erl", 26}]}.
    {func_info, {atom, std@collections@@Queue}, {atom, size}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 18}, [{x, 0}, 2, {atom, std@collections@@Queue}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 18}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {deallocate, 1}.
    return.

{function, isEmpty, 1, 5}.
  {label, 4}.
    {line, [{location, "std@collections@@Queue.erl", 27}]}.
    {func_info, {atom, std@collections@@Queue}, {atom, isEmpty}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 19}, [{x, 0}, 2, {atom, std@collections@@Queue}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 19}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 20}, [{x, 0}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 21}}.
  {label, 20}.
    {move, {atom, false}, {x, 0}}.
  {label, 21}.
    {deallocate, 1}.
    return.

{function, enqueue, 2, 7}.
  {label, 6}.
    {line, [{location, "std@collections@@Queue.erl", 28}]}.
    {func_info, {atom, std@collections@@Queue}, {atom, enqueue}, 2}.
  {label, 7}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 22}, [{x, 0}, 2, {atom, std@collections@@Queue}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 22}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@collections@@Queue}, {x, 0}]}}.
    {deallocate, 3}.
    return.

{function, dequeue, 1, 9}.
  {label, 8}.
    {line, [{location, "std@collections@@Queue.erl", 29}]}.
    {func_info, {atom, std@collections@@Queue}, {atom, dequeue}, 1}.
  {label, 9}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 23}, [{x, 0}, 2, {atom, std@collections@@Queue}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 23}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 25}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 27}, [{x, 0}, 2, {atom, std@collections@@Queue}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 27}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 28}, [{x, 0}, 2, {atom, std@collections@@Queue}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 28}.
    {gc_bif, length, {f, 0}, 2, [{x, 0}], {x, 0}}.
    {test, is_ne_exact, {f, 29}, [{x, 0}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 2, [{integer, 1}, {integer, 1}], {x, 2}}.
    {gc_bif, '-', {f, 0}, 3, [{x, 0}, {integer, 1}], {x, 3}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 3}, {x, 2}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 30}}.
  {label, 29}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 30}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@collections@@Queue}, {y, 2}]}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{x, 0}, {y, 1}]}}.
    {deallocate, 3}.
    return.

{function, peek, 1, 11}.
  {label, 10}.
    {line, [{location, "std@collections@@Queue.erl", 30}]}.
    {func_info, {atom, std@collections@@Queue}, {atom, peek}, 1}.
  {label, 11}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 31}, [{x, 0}, 2, {atom, std@collections@@Queue}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 31}.
    {move, {integer, 0}, {x, 1}}.
    {call_last, 2, {f, 25}, 1}.

{function, toList, 1, 13}.
  {label, 12}.
    {line, [{location, "std@collections@@Queue.erl", 31}]}.
    {func_info, {atom, std@collections@@Queue}, {atom, toList}, 1}.
  {label, 13}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 32}, [{x, 0}, 2, {atom, std@collections@@Queue}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 32}.
    {deallocate, 1}.
    return.

{function, empty, 0, 15}.
  {label, 14}.
    {line, [{location, "std@collections@@Queue.erl", 32}]}.
    {func_info, {atom, std@collections@@Queue}, {atom, empty}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, nil, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@collections@@Queue}, {x, 0}]}}.
    {deallocate, 0}.
    return.

{function, fromList, 1, 17}.
  {label, 16}.
    {line, [{location, "std@collections@@Queue.erl", 33}]}.
    {func_info, {atom, std@collections@@Queue}, {atom, fromList}, 1}.
  {label, 17}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@collections@@Queue}, {y, 0}]}}.
    {deallocate, 1}.
    return.

{function, '__bp_get', 2, 34}.
  {label, 33}.
    {line, [{location, "std@collections@@Queue.erl", 34}]}.
    {func_info, {atom, std@collections@@Queue}, {atom, '__bp_get'}, 2}.
  {label, 34}.
    {test, is_eq_exact, {f, 35}, [{x, 1}, {atom, items}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 35}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 37}.
  {label, 36}.
    {line, [{location, "std@collections@@Queue.erl", 34}]}.
    {func_info, {atom, std@collections@@Queue}, {atom, '__bp_format'}, 1}.
  {label, 37}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"items">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Queue">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.

{function, '-bp_at-', 2, 25}.
  {label, 24}.
    {line, [{location, "std@collections@@Queue.erl", 30}]}.
    {func_info, {atom, std@collections@@Queue}, {atom, '-bp_at-'}, 2}.
  {label, 25}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {test, is_ge, {f, 26}, [{y, 0}, {integer, 0}]}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_lt, {f, 26}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 26}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- std@collections@@Order.S
```erlang
{module, std@collections@@Order}.
{exports, [{'__bp_format', 1}]}.
{attributes, []}.
{labels, 7}.

{function, '__bp_format', 1, 3}.
  {label, 2}.
    {line, [{location, "std@collections@@Order.erl", 34}]}.
    {func_info, {atom, std@collections@@Order}, {atom, '__bp_format'}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 4}, [{x, 0}, {atom, std@collections@@Order__v__lt}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Order.Lt">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 4}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 5}, [{x, 0}, {atom, std@collections@@Order__v__eq}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Order.Eq">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 5}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 6}, [{x, 0}, {atom, std@collections@@Order__v__gt}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Order.Gt">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 6}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Order">>}, nil]}}.
    {deallocate, 2}.
    return.
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

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 34}.

{function, main, 0, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, main}, 0}.
  {label, 3}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {call_ext, 0, {extfunc, std@collections@@Dict, empty, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 3, {extfunc, std@collections@@Dict, insert, 3}}.
    {call_ext, 1, {extfunc, std@collections@@Dict, size, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 9}}.
    {call_ext, 0, {extfunc, std@collections, gt, 0}}.
    {call_ext, 1, {extfunc, std@collections, reverse, 1}}.
    {call_ext, 1, {extfunc, std@collections, toInt, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 9}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '_botopink_main', 0, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '_botopink_main'}, 0}.
  {label, 5}.
    {call_only, 0, {f, 3}}.

{function, main, 1, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, main}, 1}.
  {label, 7}.
    {call_only, 0, {f, 5}}.

{function, '__bp_print', 1, 9}.
  {label, 8}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '__bp_print'}, 1}.
  {label, 9}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 13}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 13}.
  {label, 12}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 13}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 11}}.

{function, '-bp_show_elem-', 1, 15}.
  {label, 14}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 15}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 11}}.

{function, '__bp_show', 2, 11}.
  {label, 10}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '__bp_show'}, 2}.
  {label, 11}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 23}, [{x, 0}]}.
    {test, is_eq, {f, 22}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 22}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 23}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 24}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 15}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 93}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 91}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 24}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 26}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 25}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 25}, [{x, 0}]}.
    {test, is_ne_exact, {f, 25}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 25}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 25}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 27}}.
  {label, 25}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 15}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 40}, {x, 0}, {x, 0}}.
    {put_list, {integer, 35}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 26}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 28}, [{x, 0}]}.
    {test, is_ne_exact, {f, 28}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 28}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 29}, [{x, 0}, {atom, undefined}]}.
  {label, 27}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 17}, 2}.
  {label, 28}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 29}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 17}.
  {label, 16}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '__bp_tagged'}, 2}.
  {label, 17}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 30}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 30}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 30}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 31}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 19}, 3}.
  {label, 31}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 19}.
  {label, 18}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '__bp_render'}, 1}.
  {label, 19}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 32}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 32}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 33}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 33}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 21}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {y, 1}, {x, 1}, {x, 1}}.
    {put_list, {integer, 40}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_render_pair-', 1, 21}.
  {label, 20}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 21}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 11}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 6, 1}.
    {put_list, {y, 1}, nil, {x, 1}}.
    {put_list, {literal, <<": ">>}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
1
-1
```
