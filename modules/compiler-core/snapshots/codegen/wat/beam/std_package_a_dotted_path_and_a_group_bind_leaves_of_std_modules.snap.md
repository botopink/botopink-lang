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

----- BEAM ASSEMBLY -- std/order.S
```erlang
{module, std@order}.
{exports, [{lt, 0}, {eq, 0}, {gt, 0}, {toInt, 1}, {reverse, 1}]}.
{attributes, []}.
{labels, 18}.
%%% Gleam-style `order` module, inspired by `gleam/order`. A sum type — the
%%% `type Order` (type-exported to importers) plus companion functions.
%%% Construct via the module fns (`order.lt()`); `toInt`/`reverse` operate on
%%% an `Order`. Enums are concrete types, not interfaces.

{function, lt, 0, 3}.
  {label, 2}.
    {line, [{location, "std@order.erl", 1}]}.
    {func_info, {atom, std@order}, {atom, lt}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {atom, std@order@@Order__v__lt}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, eq, 0, 5}.
  {label, 4}.
    {line, [{location, "std@order.erl", 2}]}.
    {func_info, {atom, std@order}, {atom, eq}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {move, {atom, std@order@@Order__v__eq}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, gt, 0, 7}.
  {label, 6}.
    {line, [{location, "std@order.erl", 3}]}.
    {func_info, {atom, std@order}, {atom, gt}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {move, {atom, std@order@@Order__v__gt}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, toInt, 1, 9}.
  {label, 8}.
    {line, [{location, "std@order.erl", 4}]}.
    {func_info, {atom, std@order}, {atom, toInt}, 1}.
  {label, 9}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 13}, [{x, 0}, {atom, std@order@@Order__v__lt}]}.
    {move, {integer, -1}, {x, 0}}.
    {jump, {f, 12}}.
  {label, 13}.
    {test, is_eq, {f, 14}, [{x, 0}, {atom, std@order@@Order__v__eq}]}.
    {move, {integer, 0}, {x, 0}}.
    {jump, {f, 12}}.
  {label, 14}.
    {move, {integer, 1}, {x, 0}}.
    {jump, {f, 12}}.
  {label, 12}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, reverse, 1, 11}.
  {label, 10}.
    {line, [{location, "std@order.erl", 5}]}.
    {func_info, {atom, std@order}, {atom, reverse}, 1}.
  {label, 11}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 16}, [{x, 0}, {atom, std@order@@Order__v__lt}]}.
    {move, {atom, std@order@@Order__v__gt}, {x, 0}}.
    {jump, {f, 15}}.
  {label, 16}.
    {test, is_eq, {f, 17}, [{x, 0}, {atom, std@order@@Order__v__gt}]}.
    {move, {atom, std@order@@Order__v__lt}, {x, 0}}.
    {jump, {f, 15}}.
  {label, 17}.
    {move, {atom, std@order@@Order__v__eq}, {x, 0}}.
    {jump, {f, 15}}.
  {label, 15}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 4}.
    return.
```

----- BEAM ASSEMBLY -- std@order@@Order.S
```erlang
{module, std@order@@Order}.
{exports, [{'__bp_format', 1}]}.
{attributes, []}.
{labels, 7}.

{function, '__bp_format', 1, 3}.
  {label, 2}.
    {line, [{location, "std@order@@Order.erl", 1}]}.
    {func_info, {atom, std@order@@Order}, {atom, '__bp_format'}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 4}, [{x, 0}, {atom, std@order@@Order__v__lt}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Order.Lt">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 4}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 5}, [{x, 0}, {atom, std@order@@Order__v__eq}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Order.Eq">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 5}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 6}, [{x, 0}, {atom, std@order@@Order__v__gt}]}.
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

----- BEAM ASSEMBLY -- std/dict.S
```erlang
{module, std@dict}.
{exports, [{empty, 0}]}.
{attributes, []}.
{labels, 4}.
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

{function, empty, 0, 3}.
  {label, 2}.
    {line, [{location, "std@dict.erl", 12}]}.
    {func_info, {atom, std@dict}, {atom, empty}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, nil, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@dict@@Dict}, {x, 0}]}}.
    {deallocate, 0}.
    return.
% ── option method API over `at`'s `?V` (B1: Option map/flatMap/unwrapOr) ──
% ── empty-collection boundary (B1) ──
```

----- BEAM ASSEMBLY -- std@dict@@Dict.S
```erlang
{module, std@dict@@Dict}.
{exports, [{at, 2}, {hasKey, 2}, {size, 1}, {isEmpty, 1}, {keys, 1}, {values, 1}, {insert, 3}, {delete, 2}, {merge, 2}, {fold, 3}, {mapValues, 2}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 73}.

{function, at, 2, 3}.
  {label, 2}.
    {line, [{location, "std@dict@@Dict.erl", 1}]}.
    {func_info, {atom, std@dict@@Dict}, {atom, at}, 2}.
  {label, 3}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 28}, [{x, 0}, 2, {atom, std@dict@@Dict}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 28}.
    {move, {y, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 25}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, hasKey, 2, 5}.
  {label, 4}.
    {line, [{location, "std@dict@@Dict.erl", 2}]}.
    {func_info, {atom, std@dict@@Dict}, {atom, hasKey}, 2}.
  {label, 5}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 29}, [{x, 0}, 2, {atom, std@dict@@Dict}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 29}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 31}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 35}}.
    {test, is_ne_exact, {f, 37}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 38}}.
  {label, 37}.
    {move, {atom, false}, {x, 0}}.
  {label, 38}.
    {deallocate, 4}.
    return.

{function, size, 1, 7}.
  {label, 6}.
    {line, [{location, "std@dict@@Dict.erl", 3}]}.
    {func_info, {atom, std@dict@@Dict}, {atom, size}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 39}, [{x, 0}, 2, {atom, std@dict@@Dict}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 39}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {deallocate, 1}.
    return.

{function, isEmpty, 1, 9}.
  {label, 8}.
    {line, [{location, "std@dict@@Dict.erl", 4}]}.
    {func_info, {atom, std@dict@@Dict}, {atom, isEmpty}, 1}.
  {label, 9}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 40}, [{x, 0}, 2, {atom, std@dict@@Dict}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 40}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 41}, [{x, 0}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 42}}.
  {label, 41}.
    {move, {atom, false}, {x, 0}}.
  {label, 42}.
    {deallocate, 1}.
    return.

{function, keys, 1, 11}.
  {label, 10}.
    {line, [{location, "std@dict@@Dict.erl", 5}]}.
    {func_info, {atom, std@dict@@Dict}, {atom, keys}, 1}.
  {label, 11}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 43}, [{x, 0}, 2, {atom, std@dict@@Dict}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 43}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 45}, 0, 0, {x, 0}, {list, []}}.
    {call_ext_last, 2, {extfunc, lists, map, 2}, 1}.

{function, values, 1, 13}.
  {label, 12}.
    {line, [{location, "std@dict@@Dict.erl", 6}]}.
    {func_info, {atom, std@dict@@Dict}, {atom, values}, 1}.
  {label, 13}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 46}, [{x, 0}, 2, {atom, std@dict@@Dict}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 46}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 48}, 0, 0, {x, 0}, {list, []}}.
    {call_ext_last, 2, {extfunc, lists, map, 2}, 1}.

{function, insert, 3, 15}.
  {label, 14}.
    {line, [{location, "std@dict@@Dict.erl", 7}]}.
    {func_info, {atom, std@dict@@Dict}, {atom, insert}, 3}.
  {label, 15}.
    {allocate, 5, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 49}, [{x, 0}, 2, {atom, std@dict@@Dict}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 49}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 51}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
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
    {put_tuple2, {x, 0}, {list, [{atom, std@dict@@Dict}, {x, 0}]}}.
    {deallocate, 5}.
    return.

{function, delete, 2, 17}.
  {label, 16}.
    {line, [{location, "std@dict@@Dict.erl", 8}]}.
    {func_info, {atom, std@dict@@Dict}, {atom, delete}, 2}.
  {label, 17}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 54}, [{x, 0}, 2, {atom, std@dict@@Dict}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 54}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 56}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@dict@@Dict}, {x, 0}]}}.
    {deallocate, 2}.
    return.

{function, merge, 2, 19}.
  {label, 18}.
    {line, [{location, "std@dict@@Dict.erl", 9}]}.
    {func_info, {atom, std@dict@@Dict}, {atom, merge}, 2}.
  {label, 19}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 61}, [{x, 0}, 2, {atom, std@dict@@Dict}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 61}.
    {move, {y, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 60}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, fold, 3, 21}.
  {label, 20}.
    {line, [{location, "std@dict@@Dict.erl", 10}]}.
    {func_info, {atom, std@dict@@Dict}, {atom, fold}, 3}.
  {label, 21}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 64}, [{x, 0}, 2, {atom, std@dict@@Dict}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 64}.
    {move, {y, 3}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 63}, 0, 0, {x, 0}, {list, [{y, 2}]}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, mapValues, 2, 23}.
  {label, 22}.
    {line, [{location, "std@dict@@Dict.erl", 11}]}.
    {func_info, {atom, std@dict@@Dict}, {atom, mapValues}, 2}.
  {label, 23}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 67}, [{x, 0}, 2, {atom, std@dict@@Dict}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 67}.
    {move, {y, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 66}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@dict@@Dict}, {y, 2}]}}.
    {deallocate, 3}.
    return.

{function, '__bp_get', 2, 69}.
  {label, 68}.
    {line, [{location, "std@dict@@Dict.erl", 12}]}.
    {func_info, {atom, std@dict@@Dict}, {atom, '__bp_get'}, 2}.
  {label, 69}.
    {test, is_eq_exact, {f, 70}, [{x, 1}, {atom, pairs}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 70}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 72}.
  {label, 71}.
    {line, [{location, "std@dict@@Dict.erl", 12}]}.
    {func_info, {atom, std@dict@@Dict}, {atom, '__bp_format'}, 1}.
  {label, 72}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"pairs">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Dict">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.

{function, '-/2-fun-0-', 3, 25}.
  {label, 24}.
    {line, [{location, "std@dict@@Dict.erl", 2}]}.
    {func_info, {atom, std@dict@@Dict}, {atom, '-/2-fun-0-'}, 3}.
  {label, 25}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 26}, [{x, 0}, {y, 2}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 27}}.
  {label, 26}.
  {label, 27}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '-/2-fun-1-', 2, 31}.
  {label, 30}.
    {line, [{location, "std@dict@@Dict.erl", 3}]}.
    {func_info, {atom, std@dict@@Dict}, {atom, '-/2-fun-1-'}, 2}.
  {label, 31}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 32}, [{x, 0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 33}}.
  {label, 32}.
    {move, {atom, false}, {x, 0}}.
  {label, 33}.
    {deallocate, 2}.
    return.

{function, '-bp_at-', 2, 35}.
  {label, 34}.
    {line, [{location, "std@dict@@Dict.erl", 3}]}.
    {func_info, {atom, std@dict@@Dict}, {atom, '-bp_at-'}, 2}.
  {label, 35}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {test, is_ge, {f, 36}, [{y, 0}, {integer, 0}]}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_lt, {f, 36}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 36}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-/1-fun-2-', 1, 45}.
  {label, 44}.
    {line, [{location, "std@dict@@Dict.erl", 6}]}.
    {func_info, {atom, std@dict@@Dict}, {atom, '-/1-fun-2-'}, 1}.
  {label, 45}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {deallocate, 1}.
    return.

{function, '-/1-fun-3-', 1, 48}.
  {label, 47}.
    {line, [{location, "std@dict@@Dict.erl", 7}]}.
    {func_info, {atom, std@dict@@Dict}, {atom, '-/1-fun-3-'}, 1}.
  {label, 48}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {deallocate, 1}.
    return.

{function, '-/3-fun-4-', 2, 51}.
  {label, 50}.
    {line, [{location, "std@dict@@Dict.erl", 8}]}.
    {func_info, {atom, std@dict@@Dict}, {atom, '-/3-fun-4-'}, 2}.
  {label, 51}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_ne_exact, {f, 52}, [{x, 0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 53}}.
  {label, 52}.
    {move, {atom, false}, {x, 0}}.
  {label, 53}.
    {deallocate, 2}.
    return.

{function, '-/2-fun-5-', 2, 56}.
  {label, 55}.
    {line, [{location, "std@dict@@Dict.erl", 9}]}.
    {func_info, {atom, std@dict@@Dict}, {atom, '-/2-fun-5-'}, 2}.
  {label, 56}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_ne_exact, {f, 57}, [{x, 0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 58}}.
  {label, 57}.
    {move, {atom, false}, {x, 0}}.
  {label, 58}.
    {deallocate, 2}.
    return.

{function, '-/2-fun-6-', 2, 60}.
  {label, 59}.
    {line, [{location, "std@dict@@Dict.erl", 10}]}.
    {func_info, {atom, std@dict@@Dict}, {atom, '-/2-fun-6-'}, 2}.
  {label, 60}.
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
    {call, 3, {f, 15}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '-/3-fun-7-', 3, 63}.
  {label, 62}.
    {line, [{location, "std@dict@@Dict.erl", 11}]}.
    {func_info, {atom, std@dict@@Dict}, {atom, '-/3-fun-7-'}, 3}.
  {label, 63}.
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

{function, '-/2-fun-8-', 3, 66}.
  {label, 65}.
    {line, [{location, "std@dict@@Dict.erl", 12}]}.
    {func_info, {atom, std@dict@@Dict}, {atom, '-/2-fun-8-'}, 3}.
  {label, 66}.
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

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 33}.

{function, main, 0, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, main}, 0}.
  {label, 3}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {call_ext, 0, {extfunc, std@dict, empty, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 3, {extfunc, std@dict@@Dict, insert, 3}}.
    {call_ext, 1, {extfunc, std@dict@@Dict, size, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 9}}.
    {call_ext, 0, {extfunc, std@order, gt, 0}}.
    {call_ext, 1, {extfunc, std@order, reverse, 1}}.
    {call_ext, 1, {extfunc, std@order, toInt, 1}}.
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
    {test, is_ne_exact, {f, 28}, [{x, 0}, {atom, undefined}]}.
  {label, 27}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 17}, 2}.
  {label, 28}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.

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
    {test, is_nonempty_list, {f, 29}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 29}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 29}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 30}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 19}, 3}.
  {label, 30}.
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
    {test, is_eq_exact, {f, 31}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 31}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 32}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 32}.
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
