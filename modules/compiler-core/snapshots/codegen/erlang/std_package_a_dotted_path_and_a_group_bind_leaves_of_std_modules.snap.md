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

----- ERLANG -- std/order.erl
```erlang
-module(std@order).
-export([lt/0, eq/0, gt/0, toInt/1, reverse/1]).

%%% Gleam-style `order` module, inspired by `gleam/order`. A sum type — the

%%% `type Order` (type-exported to importers) plus companion functions.

%%% Construct via the module fns (`order.lt()`); `toInt`/`reverse` operate on

%%% an `Order`. Enums are concrete types, not interfaces.

%% type Order
%%   Lt
%%   Eq
%%   Gt

lt() ->
    std@order__t__order__v__lt.

eq() ->
    std@order__t__order__v__eq.

gt() ->
    std@order__t__order__v__gt.

toInt(O) ->
    N = case O of
        std@order__t__order__v__lt ->
            (-1);
        std@order__t__order__v__eq ->
            0;
        _ ->
            1
    end,
    N.

reverse(O) ->
    R = case O of
        std@order__t__order__v__lt ->
            std@order__t__order__v__gt;
        std@order__t__order__v__gt ->
            std@order__t__order__v__lt;
        _ ->
            std@order__t__order__v__eq
    end,
    R.



```

----- ERLANG -- std@order__t__order.erl
```erlang
-module(std@order__t__order).
-export(['__bp_format'/1]).

'__bp_format'(std@order__t__order__v__lt) -> {variant, "Order.Lt", []};
'__bp_format'(std@order__t__order__v__eq) -> {variant, "Order.Eq", []};
'__bp_format'(std@order__t__order__v__gt) -> {variant, "Order.Gt", []}.
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

----- ERLANG -- std/dict.erl
```erlang
-module(std@dict).
-export([empty/0]).

%%% Gleam-inspired `dict` module — a `type Dict<K, V>` wrapping an

%%% association list `pairs: Array<#(K, V)>` for full backend portability

%%% (no host-backing). O(n) read; camelCase convention.

%%% 

%%% Instance operations are `self`-methods on the record; `empty` is a

%%% top-level constructor (records hold state and are constructed — unlike

%%% interfaces, which are pure behaviour contracts).

%%% 

%%% `==` / `!=` on generic K uses structural equality (string/numeric keys —

%%% the common case). API naming note: `new`/`get` are keyword tokens — use

%%% `empty`/`at`.

%%% 

%%% `Dict<K, V>` answers the ambient `Index<K, V>` of `builtins.d.bp`

%%% (decision 63, amended), which is what makes `d["k"]` legal: the index

%%% expression has no typing rule of its own and rewrites to `d.at("k")`. The

%%% reader was spelled `lookup` until that amendment gave every indexable type

%%% one method name.

%% type Dict: pairs

empty() ->
    {std@dict__t__dict, []}.













% ── option method API over `at`'s `?V` (B1: Option map/flatMap/unwrapOr) ──






% ── empty-collection boundary (B1) ──

```

----- ERLANG -- std@dict__t__dict.erl
```erlang
-module(std@dict__t__dict).
-compile({no_auto_import,[size/1]}).
-export([at/2, hasKey/2, size/1, isEmpty/1, keys/1, values/1, insert/3, delete/2, merge/2, fold/3, mapValues/2, '__bp_get'/2, '__bp_format'/1]).

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
    {std@dict__t__dict, (Filtered ++ [{Key, Value}])}.

delete(Self, Key) ->
    {std@dict__t__dict, lists:filter(fun(P) ->
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
    {std@dict__t__dict, Out}.

'__bp_get'(V, pairs) -> element(2, V).

'__bp_format'(V) -> {record, "Dict", [{"pairs", element(2, V)}]}.
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

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% import Dict, newDict, gt, reverse, toInt

main() ->
    D = std@dict:empty(),
    '__bp_print'([std@dict__t__dict:size(std@dict__t__dict:insert(D, <<"a">>, 1))]),
    '__bp_print'([std@order:toInt(std@order:reverse(std@order:gt()))]).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when is_binary(V) -> V;
'__bp_show'(V, _) when is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when is_tuple(V), tuple_size(V) > 0, is_atom(element(1, V)), element(1, V) =/= true, element(1, V) =/= false, element(1, V) =/= undefined -> '__bp_tagged'(element(1, V), V);
'__bp_show'(V, _) when is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- tuple_to_list(V)]), $)];
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
-1
```
