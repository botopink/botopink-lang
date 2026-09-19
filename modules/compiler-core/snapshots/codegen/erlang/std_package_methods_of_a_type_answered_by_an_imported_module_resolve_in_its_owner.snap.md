----- SOURCE CODE -- std/dict.bp
```botopink
//// Gleam-inspired `dict` module — a `type Dict<K, V>` wrapping an
//// association list `pairs: Array<#(K, V)>` for full backend portability
//// (no host-backing). O(n) lookup; camelCase convention.
////
//// Instance operations are `self`-methods on the record; `empty` is a
//// top-level constructor (records hold state and are constructed — unlike
//// interfaces, which are pure behaviour contracts).
////
//// `==` / `!=` on generic K uses structural equality (string/numeric keys —
//// the common case). API naming note: `new`/`get` are keyword tokens — use
//// `empty`/`lookup`.

pub type Dict<K, V>(
    pairs: Array<#(K, V)>,
) {
    pub fn lookup(self: Self, key: K) -> ?V {
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

    pub fn fold<A>(self: Self, initial: A, f: fn(acc: A, key: K, value: V) -> A) -> A {
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

test "dict insert and lookup" {
    val d = empty().insert("a", 1);
    assert d.lookup("a").unwrapOr(0) == 1;
    assert d.lookup("z").unwrapOr(-1) == -1;
}

test "dict pipeline: insert chain" {
    val d = empty().insert("x", 10).insert("y", 20).insert("z", 30);
    assert d.lookup("x").unwrapOr(0) == 10;
    assert d.lookup("y").unwrapOr(0) == 20;
    assert d.lookup("z").unwrapOr(0) == 30;
}

test "dict hasKey" {
    val d = empty().insert("k", 99);
    assert d.hasKey("k");
    assert !d.hasKey("missing");
}

test "dict delete removes key" {
    val d = empty().insert("a", 1).insert("b", 2).delete("a");
    assert !d.hasKey("a");
    assert d.lookup("b").unwrapOr(0) == 2;
}

test "dict insert overwrites duplicate" {
    val d = empty().insert("k", 1).insert("k", 99);
    assert d.size() == 1;
    assert d.lookup("k").unwrapOr(0) == 99;
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
    assert m.lookup("k").unwrapOr(0) == 99;
}

test "dict mapValues transforms values" {
    val d = empty().insert("a", 3).insert("b", 7);
    val doubled = d.mapValues({ v -> v * 2 });
    assert doubled.lookup("a").unwrapOr(0) == 6;
    assert doubled.lookup("b").unwrapOr(0) == 14;
}

// ── option method API over `lookup`'s `?V` (B1: Option map/flatMap/unwrapOr) ──

test "option map over a present lookup" {
    val some = empty().insert("a", 1).lookup("a");
    assert some.map({ x -> x + 9 }).unwrapOr(0) == 10;
}

test "option map propagates absence" {
    val none = empty().insert("a", 1).lookup("z");
    assert none.map({ x -> x + 9 }).unwrapOr(-1) == -1;
}

test "option flatMap chains present" {
    val d = empty().insert("a", 1);
    val r = d.lookup("a").flatMap({ x -> d.lookup("a").map({ y -> x + y }) });
    assert r.unwrapOr(0) == 2;
}

test "option flatMap short-circuits on absence" {
    val d = empty().insert("a", 1);
    val r = d.lookup("missing").flatMap({ x -> d.lookup("a") });
    assert r.unwrapOr(-7) == -7;
}

test "option unwrapOr returns present value" {
    assert empty().insert("a", 42).lookup("a").unwrapOr(0) == 42;
}

// ── empty-collection boundary (B1) ──

test "dict empty boundary: size 0, lookup misses" {
    val d: Dict<string, i32> = empty();
    assert d.size() == 0;
    assert !d.hasKey("anything");
    assert d.lookup("anything").unwrapOr(-1) == -1;
    assert d.keys().length == 0;
    assert d.values().length == 0;
}

```

----- ERLANG -- std/dict.erl
```erlang
-module(std@dict).
-compile({no_auto_import,[size/1]}).
-export([empty/0, lookup/2, hasKey/2, size/1, isEmpty/1, keys/1, values/1, insert/3, delete/2, merge/2, fold/3, mapValues/2]).

%%% Gleam-inspired `dict` module — a `type Dict<K, V>` wrapping an

%%% association list `pairs: Array<#(K, V)>` for full backend portability

%%% (no host-backing). O(n) lookup; camelCase convention.

%%% 

%%% Instance operations are `self`-methods on the record; `empty` is a

%%% top-level constructor (records hold state and are constructed — unlike

%%% interfaces, which are pure behaviour contracts).

%%% 

%%% `==` / `!=` on generic K uses structural equality (string/numeric keys —

%%% the common case). API naming note: `new`/`get` are keyword tokens — use

%%% `empty`/`lookup`.

%% type Dict: pairs

lookup(Self, Key) ->
    % NOTE: written with `forEach` + accumulator rather than
    % `.at(0).map(…)` — chained method dispatch on a `?T` (option-map) is
    % not lowered yet (tracked in tasks/v0.beta.4 Part A: primitive/option
    % method dispatch). `.at(0)` here would type as array, not `?T`.
    Found = lists:foldl(fun(P, Found) ->
        case (element(1, P) =:= Key) of
            true -> element(2, P);
            _ -> Found
        end
    end, undefined, maps:get(pairs, Self)),
    Found.

hasKey(Self, Key) ->
    ((fun(__L, __I) -> case ((__I >= 0) andalso (__I < length(__L))) of true -> lists:nth(__I + 1, __L); false -> undefined end end)(lists:filter(fun(P) ->
        (element(1, P) =:= Key)
    end, maps:get(pairs, Self)), 0) =/= undefined).

size(Self) ->
    length(maps:get(pairs, Self)).

isEmpty(Self) ->
    (length(maps:get(pairs, Self)) =:= 0).

keys(Self) ->
    lists:map(fun(P) ->
        element(1, P)
    end, maps:get(pairs, Self)).

values(Self) ->
    lists:map(fun(P) ->
        element(2, P)
    end, maps:get(pairs, Self)).

insert(Self, Key, Value) ->
    Filtered = lists:filter(fun(P) ->
        (element(1, P) =/= Key)
    end, maps:get(pairs, Self)),
    #{pairs => (Filtered ++ [{Key, Value}])}.

delete(Self, Key) ->
    #{pairs => lists:filter(fun(P) ->
        (element(1, P) =/= Key)
    end, maps:get(pairs, Self))}.

merge(Self, Other) ->
    Out = lists:foldl(fun(P, Out) ->
        insert(Out, element(1, P), element(2, P))
    end, Self, maps:get(pairs, Other)),
    Out.

fold(Self, Initial, F) ->
    Acc = lists:foldl(fun(P, Acc) ->
        F(Acc, element(1, P), element(2, P))
    end, Initial, maps:get(pairs, Self)),
    Acc.

mapValues(Self, F) ->
    Out = lists:foldl(fun(P, Out) ->
        (Out ++ [{element(1, P), F(element(2, P))}])
    end, [], maps:get(pairs, Self)),
    #{pairs => Out}.

empty() ->
    #{pairs => []}.













% ── option method API over `lookup`'s `?V` (B1: Option map/flatMap/unwrapOr) ──






% ── empty-collection boundary (B1) ──

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {dict} from "std";

fn main() {
    val d = dict.empty().insert("a", 1);
    @print(d.lookup("a").unwrapOr(0));
    @print(d.insert("b", 2).size());
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% import dict

main() ->
    D = std@dict:insert(std@dict:empty(), <<"a">>, 1),
    '__bp_print'([(fun(O) -> case O of undefined -> (0); V -> V end end)(std@dict:lookup(D, <<"a">>))]),
    '__bp_print'([std@dict:size(std@dict:insert(D, <<"b">>, 2))]).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when is_binary(V) -> V;
'__bp_show'(V, _) when is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when is_list(V) -> [$[, lists:join(",", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when is_tuple(V), tuple_size(V) > 0, is_atom(element(1, V)), element(1, V) =/= true, element(1, V) =/= false, element(1, V) =/= undefined -> io_lib:format("~p", [V]);
'__bp_show'(V, _) when is_tuple(V) -> ["#(", lists:join(",", ['__bp_show'(E, false) || E <- tuple_to_list(V)]), $)];
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

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
