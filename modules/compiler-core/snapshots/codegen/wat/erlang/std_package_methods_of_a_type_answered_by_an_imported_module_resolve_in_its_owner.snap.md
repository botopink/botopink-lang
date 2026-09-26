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

----- ERLANG -- std/collections.erl
```erlang
-module(std@collections).
-export([lt/0, eq/0, gt/0, toInt/1, reverse/1]).

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

%% type Dict: pairs













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

%% type Set: items










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

%% type Queue: items








% ── empty-collection boundary (B1) ──


% ── Order ───────────────────────────────────────────────────────────────────

% `Order` (was `order`) — Gleam-style, inspired by `gleam/order`. A sum type — the

% `type Order` (type-exported to importers) plus companion functions.

% Construct via the module fns (`collections.lt()`); `toInt`/`reverse` operate on

% an `Order`. Enums are concrete types, not interfaces.

%% type Order
%%   Lt
%%   Eq
%%   Gt

lt() ->
    std@collections@@Order__v__lt.

eq() ->
    std@collections@@Order__v__eq.

gt() ->
    std@collections@@Order__v__gt.

toInt(O) ->
    N = case O of
        std@collections@@Order__v__lt ->
            (-1);
        std@collections@@Order__v__eq ->
            0;
        _ ->
            1
    end,
    N.

reverse(O) ->
    R = case O of
        std@collections@@Order__v__lt ->
            std@collections@@Order__v__gt;
        std@collections@@Order__v__gt ->
            std@collections@@Order__v__lt;
        _ ->
            std@collections@@Order__v__eq
    end,
    R.



```

----- ERLANG -- std@collections@@Dict.erl
```erlang
-module(std@collections@@Dict).
-compile({no_auto_import,[size/1]}).
-export([at/2, hasKey/2, size/1, isEmpty/1, keys/1, values/1, insert/3, delete/2, merge/2, fold/3, mapValues/2, empty/0, '__bp_get'/2, '__bp_format'/1]).

at(Self, Key) ->
    % NOTE: written with `forEach` + accumulator rather than
    % `.at(0).map(…)` — chained method dispatch on a `?T` (option-map) is
    % not lowered yet (tracked in tasks/v0.beta.4 Part A: primitive/option
    % method dispatch). `.at(0)` here would type as array, not `?T`.
    Found = lists:foldl(fun(P, Found) ->
        case (element(1, P) =:= Key) of
            true -> element(2, P);
            _ -> Found
        end
    end, undefined, element(2, Self)),
    Found.

hasKey(Self, Key) ->
    ((fun(__L, __I) -> case ((__I >= 0) andalso (__I < length(__L))) of true -> lists:nth(__I + 1, __L); false -> undefined end end)(lists:filter(fun(P) ->
        (element(1, P) =:= Key)
    end, element(2, Self)), 0) =/= undefined).

size(Self) ->
    length(element(2, Self)).

isEmpty(Self) ->
    (length(element(2, Self)) =:= 0).

keys(Self) ->
    lists:map(fun(P) ->
        element(1, P)
    end, element(2, Self)).

values(Self) ->
    lists:map(fun(P) ->
        element(2, P)
    end, element(2, Self)).

insert(Self, Key, Value) ->
    Filtered = lists:filter(fun(P) ->
        (element(1, P) =/= Key)
    end, element(2, Self)),
    {std@collections@@Dict, (Filtered ++ [{Key, Value}])}.

delete(Self, Key) ->
    {std@collections@@Dict, lists:filter(fun(P) ->
        (element(1, P) =/= Key)
    end, element(2, Self))}.

merge(Self, Other) ->
    Out = lists:foldl(fun(P, Out) ->
        insert(Out, element(1, P), element(2, P))
    end, Self, element(2, Other)),
    Out.

fold(Self, Initial, F) ->
    Acc = lists:foldl(fun(P, Acc) ->
        F(Acc, element(1, P), element(2, P))
    end, Initial, element(2, Self)),
    Acc.

mapValues(Self, F) ->
    Out = lists:foldl(fun(P, Out) ->
        (Out ++ [{element(1, P), F(element(2, P))}])
    end, [], element(2, Self)),
    {std@collections@@Dict, Out}.

empty() ->
    {std@collections@@Dict, []}.

'__bp_get'(V, pairs) -> element(2, V).

'__bp_format'(V) -> {record, "Dict", [{"pairs", element(2, V)}]}.
```

----- ERLANG -- std@collections@@Set.erl
```erlang
-module(std@collections@@Set).
-compile({no_auto_import,[size/1]}).
-export([contains/2, size/1, isEmpty/1, toList/1, insert/2, delete/2, union/2, intersection/2, difference/2, empty/0, fromList/1, '__bp_get'/2, '__bp_format'/1]).

contains(Self, X) ->
    ((fun(__L, __X) -> __Find = fun __F(__I, [__H | __T]) -> case (__H =:= __X) of true -> __I; false -> __F(__I + 1, __T) end; __F(_, []) -> -1 end, __Find(0, __L) end)(element(2, Self), X) =/= (-1)).

size(Self) ->
    length(element(2, Self)).

isEmpty(Self) ->
    (length(element(2, Self)) =:= 0).

toList(Self) ->
    element(2, Self).

insert(Self, X) ->
    case ((fun(__L, __X) -> __Find = fun __F(__I, [__H | __T]) -> case (__H =:= __X) of true -> __I; false -> __F(__I + 1, __T) end; __F(_, []) -> -1 end, __Find(0, __L) end)(element(2, Self), X) =/= (-1)) of
        true ->
            Self;
        false ->
            {std@collections@@Set, (element(2, Self) ++ [X])}
    end.

delete(Self, X) ->
    {std@collections@@Set, lists:filter(fun(Item) ->
        (Item =/= X)
    end, element(2, Self))}.

union(Self, Other) ->
    Out = lists:foldl(fun(X, Out) ->
        insert(Out, X)
    end, Self, element(2, Other)),
    Out.

intersection(Self, Other) ->
    {std@collections@@Set, lists:filter(fun(X) ->
        ((fun(__L, __X) -> __Find = fun __F(__I, [__H | __T]) -> case (__H =:= __X) of true -> __I; false -> __F(__I + 1, __T) end; __F(_, []) -> -1 end, __Find(0, __L) end)(element(2, Other), X) =/= (-1))
    end, element(2, Self))}.

difference(Self, Other) ->
    {std@collections@@Set, lists:filter(fun(X) ->
        ((fun(__L, __X) -> __Find = fun __F(__I, [__H | __T]) -> case (__H =:= __X) of true -> __I; false -> __F(__I + 1, __T) end; __F(_, []) -> -1 end, __Find(0, __L) end)(element(2, Other), X) =:= (-1))
    end, element(2, Self))}.

empty() ->
    {std@collections@@Set, []}.

fromList(Xs) ->
    Out = lists:foldl(fun(X, Out) ->
        insert(Out, X)
    end, {std@collections@@Set, []}, Xs),
    Out.

'__bp_get'(V, items) -> element(2, V).

'__bp_format'(V) -> {record, "Set", [{"items", element(2, V)}]}.
```

----- ERLANG -- std@collections@@Queue.erl
```erlang
-module(std@collections@@Queue).
-compile({no_auto_import,[size/1]}).
-export([size/1, isEmpty/1, enqueue/2, dequeue/1, peek/1, toList/1, empty/0, fromList/1, '__bp_get'/2, '__bp_format'/1]).

size(Self) ->
    length(element(2, Self)).

isEmpty(Self) ->
    (length(element(2, Self)) =:= 0).

enqueue(Self, Item) ->
    {std@collections@@Queue, (element(2, Self) ++ [Item])}.

dequeue(Self) ->
    Head = (fun(__L, __I) -> case ((__I >= 0) andalso (__I < length(__L))) of true -> lists:nth(__I + 1, __L); false -> undefined end end)(element(2, Self), 0),
    Rest = array_slice(element(2, Self), 1, length(element(2, Self))),
    {{std@collections@@Queue, Rest}, Head}.

peek(Self) ->
    (fun(__L, __I) -> case ((__I >= 0) andalso (__I < length(__L))) of true -> lists:nth(__I + 1, __L); false -> undefined end end)(element(2, Self), 0).

toList(Self) ->
    element(2, Self).

empty() ->
    {std@collections@@Queue, []}.

fromList(Xs) ->
    {std@collections@@Queue, Xs}.

'__bp_get'(V, items) -> element(2, V).

'__bp_format'(V) -> {record, "Queue", [{"items", element(2, V)}]}.

array_slice(Self, Start, End) ->
    case (End =/= undefined) of
        true ->
            lists:sublist(Self, (Start) + 1, ((End) - (Start)));
        false ->
            lists:nthtail(Start, Self)
    end.
```

----- ERLANG -- std@collections@@Order.erl
```erlang
-module(std@collections@@Order).
-export(['__bp_format'/1]).

'__bp_format'(std@collections@@Order__v__lt) -> {variant, "Order.Lt", []};
'__bp_format'(std@collections@@Order__v__eq) -> {variant, "Order.Eq", []};
'__bp_format'(std@collections@@Order__v__gt) -> {variant, "Order.Gt", []}.
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

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).

%% import Dict

main() ->
    D = std@collections@@Dict:insert(std@collections@@Dict:empty(), <<"a">>, 1),
    '__bp_print'([(fun(__BpO) -> case __BpO of undefined -> (0); __BpV0 -> __BpV0 end end)(std@collections@@Dict:at(D, <<"a">>))]),
    '__bp_print'([std@collections@@Dict:size(std@collections@@Dict:insert(D, <<"b">>, 2))]).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when is_binary(V) -> V;
'__bp_show'(V, _) when is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when is_tuple(V), tuple_size(V) > 0, is_atom(element(1, V)), element(1, V) =/= true, element(1, V) =/= false, element(1, V) =/= undefined -> '__bp_tagged'(element(1, V), V);
'__bp_show'(V, _) when is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- tuple_to_list(V)]), $)];
'__bp_show'(undefined, _) -> "null";
'__bp_show'(V, _) when is_atom(V), V =/= true, V =/= false, V =/= undefined -> '__bp_tagged'(V, V);
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'__bp_tagged'(A, V) ->
    M = case string:split(atom_to_list(A), "__v__") of [P, _] -> list_to_atom(P); _ -> A end,
    case code:ensure_loaded(M) =:= {module, M} andalso erlang:function_exported(M, '__bp_format', 1) of true -> '__bp_render'(apply(M, '__bp_format', [V])); false -> io_lib:format("~p", [V]) end.

'__bp_render'({text, T}) -> T;
'__bp_render'({variant, N, []}) -> N;
'__bp_render'({_, N, Fs}) -> [N, $(, lists:join(", ", [[K, ": ", '__bp_show'(Val, false)] || {K, Val} <- Fs]), $)].

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
1
2
```
