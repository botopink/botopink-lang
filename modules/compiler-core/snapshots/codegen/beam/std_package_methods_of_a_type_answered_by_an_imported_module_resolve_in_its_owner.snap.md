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

----- BEAM ASSEMBLY -- std/dict.S
```erlang
{module, std@dict}.
{exports, [{'Dict_lookup', 2}, {'Dict_hasKey', 2}, {'Dict_size', 1}, {'Dict_isEmpty', 1}, {'Dict_keys', 1}, {'Dict_values', 1}, {'Dict_insert', 3}, {'Dict_delete', 2}, {'Dict_merge', 2}, {'Dict_fold', 3}, {'Dict_mapValues', 2}, {empty, 0}]}.
{attributes, []}.
{labels, 70}.
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

{function, 'Dict_lookup', 2, 3}.
  {label, 2}.
    {line, [{location, "std@dict.erl", 1}]}.
    {func_info, {atom, std@dict}, {atom, 'Dict_lookup'}, 2}.
  {label, 3}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_map, {f, 30}, [{x, 0}]}.
    {get_map_elements, {f, 30}, {x, 0}, {list, [{atom, pairs}, {x, 0}]}}.
  {label, 30}.
    {move, {y, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 27}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, 'Dict_hasKey', 2, 5}.
  {label, 4}.
    {line, [{location, "std@dict.erl", 2}]}.
    {func_info, {atom, std@dict}, {atom, 'Dict_hasKey'}, 2}.
  {label, 5}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_map, {f, 31}, [{x, 0}]}.
    {get_map_elements, {f, 31}, {x, 0}, {list, [{atom, pairs}, {x, 0}]}}.
  {label, 31}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 33}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 37}}.
    {test, is_ne_exact, {f, 39}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 40}}.
  {label, 39}.
    {move, {atom, false}, {x, 0}}.
  {label, 40}.
    {deallocate, 4}.
    return.

{function, 'Dict_size', 1, 7}.
  {label, 6}.
    {line, [{location, "std@dict.erl", 3}]}.
    {func_info, {atom, std@dict}, {atom, 'Dict_size'}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_map, {f, 41}, [{x, 0}]}.
    {get_map_elements, {f, 41}, {x, 0}, {list, [{atom, pairs}, {x, 0}]}}.
  {label, 41}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {deallocate, 1}.
    return.

{function, 'Dict_isEmpty', 1, 9}.
  {label, 8}.
    {line, [{location, "std@dict.erl", 4}]}.
    {func_info, {atom, std@dict}, {atom, 'Dict_isEmpty'}, 1}.
  {label, 9}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_map, {f, 42}, [{x, 0}]}.
    {get_map_elements, {f, 42}, {x, 0}, {list, [{atom, pairs}, {x, 0}]}}.
  {label, 42}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_eq, {f, 43}, [{x, 0}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 44}}.
  {label, 43}.
    {move, {atom, false}, {x, 0}}.
  {label, 44}.
    {deallocate, 1}.
    return.

{function, 'Dict_keys', 1, 11}.
  {label, 10}.
    {line, [{location, "std@dict.erl", 5}]}.
    {func_info, {atom, std@dict}, {atom, 'Dict_keys'}, 1}.
  {label, 11}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_map, {f, 45}, [{x, 0}]}.
    {get_map_elements, {f, 45}, {x, 0}, {list, [{atom, pairs}, {x, 0}]}}.
  {label, 45}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 47}, 0, 0, {x, 0}, {list, []}}.
    {call_ext_last, 2, {extfunc, lists, map, 2}, 1}.

{function, 'Dict_values', 1, 13}.
  {label, 12}.
    {line, [{location, "std@dict.erl", 6}]}.
    {func_info, {atom, std@dict}, {atom, 'Dict_values'}, 1}.
  {label, 13}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_map, {f, 48}, [{x, 0}]}.
    {get_map_elements, {f, 48}, {x, 0}, {list, [{atom, pairs}, {x, 0}]}}.
  {label, 48}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 50}, 0, 0, {x, 0}, {list, []}}.
    {call_ext_last, 2, {extfunc, lists, map, 2}, 1}.

{function, 'Dict_insert', 3, 15}.
  {label, 14}.
    {line, [{location, "std@dict.erl", 7}]}.
    {func_info, {atom, std@dict}, {atom, 'Dict_insert'}, 3}.
  {label, 15}.
    {allocate, 5, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_map, {f, 51}, [{x, 0}]}.
    {get_map_elements, {f, 51}, {x, 0}, {list, [{atom, pairs}, {x, 0}]}}.
  {label, 51}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 53}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
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
    {put_map_assoc, {f, 0}, {literal, #{}}, {x, 0}, 1, {list, [{atom, pairs}, {x, 0}]}}.
    {deallocate, 5}.
    return.

{function, 'Dict_delete', 2, 17}.
  {label, 16}.
    {line, [{location, "std@dict.erl", 8}]}.
    {func_info, {atom, std@dict}, {atom, 'Dict_delete'}, 2}.
  {label, 17}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_map, {f, 56}, [{x, 0}]}.
    {get_map_elements, {f, 56}, {x, 0}, {list, [{atom, pairs}, {x, 0}]}}.
  {label, 56}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 58}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {put_map_assoc, {f, 0}, {literal, #{}}, {x, 0}, 1, {list, [{atom, pairs}, {x, 0}]}}.
    {deallocate, 2}.
    return.

{function, 'Dict_merge', 2, 19}.
  {label, 18}.
    {line, [{location, "std@dict.erl", 9}]}.
    {func_info, {atom, std@dict}, {atom, 'Dict_merge'}, 2}.
  {label, 19}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_map, {f, 63}, [{x, 0}]}.
    {get_map_elements, {f, 63}, {x, 0}, {list, [{atom, pairs}, {x, 0}]}}.
  {label, 63}.
    {move, {y, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 62}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, 'Dict_fold', 3, 21}.
  {label, 20}.
    {line, [{location, "std@dict.erl", 10}]}.
    {func_info, {atom, std@dict}, {atom, 'Dict_fold'}, 3}.
  {label, 21}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_map, {f, 66}, [{x, 0}]}.
    {get_map_elements, {f, 66}, {x, 0}, {list, [{atom, pairs}, {x, 0}]}}.
  {label, 66}.
    {move, {y, 3}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 65}, 0, 0, {x, 0}, {list, [{y, 2}]}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, 'Dict_mapValues', 2, 23}.
  {label, 22}.
    {line, [{location, "std@dict.erl", 11}]}.
    {func_info, {atom, std@dict}, {atom, 'Dict_mapValues'}, 2}.
  {label, 23}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_map, {f, 69}, [{x, 0}]}.
    {get_map_elements, {f, 69}, {x, 0}, {list, [{atom, pairs}, {x, 0}]}}.
  {label, 69}.
    {move, {y, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 68}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 2}}.
    {put_map_assoc, {f, 0}, {literal, #{}}, {x, 0}, 0, {list, [{atom, pairs}, {y, 2}]}}.
    {deallocate, 3}.
    return.

{function, empty, 0, 25}.
  {label, 24}.
    {line, [{location, "std@dict.erl", 12}]}.
    {func_info, {atom, std@dict}, {atom, empty}, 0}.
  {label, 25}.
    {allocate, 0, 0}.
    {move, nil, {x, 0}}.
    {put_map_assoc, {f, 0}, {literal, #{}}, {x, 0}, 1, {list, [{atom, pairs}, {x, 0}]}}.
    {deallocate, 0}.
    return.
% ── option method API over `lookup`'s `?V` (B1: Option map/flatMap/unwrapOr) ──
% ── empty-collection boundary (B1) ──

{function, '-/2-fun-0-', 3, 27}.
  {label, 26}.
    {line, [{location, "std@dict.erl", 2}]}.
    {func_info, {atom, std@dict}, {atom, '-/2-fun-0-'}, 3}.
  {label, 27}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq, {f, 28}, [{x, 0}, {y, 2}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 29}}.
  {label, 28}.
  {label, 29}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '-/2-fun-1-', 2, 33}.
  {label, 32}.
    {line, [{location, "std@dict.erl", 3}]}.
    {func_info, {atom, std@dict}, {atom, '-/2-fun-1-'}, 2}.
  {label, 33}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq, {f, 34}, [{x, 0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 35}}.
  {label, 34}.
    {move, {atom, false}, {x, 0}}.
  {label, 35}.
    {deallocate, 2}.
    return.

{function, '-bp_at-', 2, 37}.
  {label, 36}.
    {line, [{location, "std@dict.erl", 3}]}.
    {func_info, {atom, std@dict}, {atom, '-bp_at-'}, 2}.
  {label, 37}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {test, is_ge, {f, 38}, [{y, 0}, {integer, 0}]}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_lt, {f, 38}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 38}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-/1-fun-2-', 1, 47}.
  {label, 46}.
    {line, [{location, "std@dict.erl", 6}]}.
    {func_info, {atom, std@dict}, {atom, '-/1-fun-2-'}, 1}.
  {label, 47}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {deallocate, 1}.
    return.

{function, '-/1-fun-3-', 1, 50}.
  {label, 49}.
    {line, [{location, "std@dict.erl", 7}]}.
    {func_info, {atom, std@dict}, {atom, '-/1-fun-3-'}, 1}.
  {label, 50}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {deallocate, 1}.
    return.

{function, '-/3-fun-4-', 2, 53}.
  {label, 52}.
    {line, [{location, "std@dict.erl", 8}]}.
    {func_info, {atom, std@dict}, {atom, '-/3-fun-4-'}, 2}.
  {label, 53}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_ne_exact, {f, 54}, [{x, 0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 55}}.
  {label, 54}.
    {move, {atom, false}, {x, 0}}.
  {label, 55}.
    {deallocate, 2}.
    return.

{function, '-/2-fun-5-', 2, 58}.
  {label, 57}.
    {line, [{location, "std@dict.erl", 9}]}.
    {func_info, {atom, std@dict}, {atom, '-/2-fun-5-'}, 2}.
  {label, 58}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_ne_exact, {f, 59}, [{x, 0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 60}}.
  {label, 59}.
    {move, {atom, false}, {x, 0}}.
  {label, 60}.
    {deallocate, 2}.
    return.

{function, '-/2-fun-6-', 2, 62}.
  {label, 61}.
    {line, [{location, "std@dict.erl", 10}]}.
    {func_info, {atom, std@dict}, {atom, '-/2-fun-6-'}, 2}.
  {label, 62}.
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

{function, '-/3-fun-7-', 3, 65}.
  {label, 64}.
    {line, [{location, "std@dict.erl", 11}]}.
    {func_info, {atom, std@dict}, {atom, '-/3-fun-7-'}, 3}.
  {label, 65}.
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

{function, '-/2-fun-8-', 3, 68}.
  {label, 67}.
    {line, [{location, "std@dict.erl", 12}]}.
    {func_info, {atom, std@dict}, {atom, '-/2-fun-8-'}, 3}.
  {label, 68}.
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
import {dict} from "std";

fn main() {
    val d = dict.empty().insert("a", 1);
    @print(d.lookup("a").unwrapOr(0));
    @print(d.insert("b", 2).size());
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 23}.

{function, main, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 3}.
    {allocate, 5, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {call_ext, 0, {extfunc, std@dict, empty, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {move, {integer, 1}, {x, 2}}.
    {move, {x, 1}, {x, 3}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 3}, {x, 0}}.
    {call_ext, 3, {extfunc, std@dict, 'Dict_insert', 3}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, std@dict, 'Dict_lookup', 2}}.
    {test, is_eq, {f, 8}, [{x, 0}, {atom, undefined}]}.
    {move, {integer, 0}, {x, 0}}.
    {jump, {f, 9}}.
  {label, 8}.
  {label, 9}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 11}}.
    {move, {literal, <<"b">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 3, {extfunc, std@dict, 'Dict_insert', 3}}.
    {call_ext, 1, {extfunc, std@dict, 'Dict_size', 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 11}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '_botopink_main', 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '_botopink_main'}, 0}.
  {label, 5}.
    {call_only, 0, {f, 3}}.

{function, main, 1, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, main}, 1}.
  {label, 7}.
    {call_only, 0, {f, 5}}.

{function, '__bp_print', 1, 11}.
  {label, 10}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '__bp_print'}, 1}.
  {label, 11}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 15}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 15}.
  {label, 14}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '-bp_show_top-'}, 1}.
  {label, 15}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 13}}.

{function, '-bp_show_elem-', 1, 17}.
  {label, 16}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 17}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 13}}.

{function, '__bp_show', 2, 13}.
  {label, 12}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '__bp_show'}, 2}.
  {label, 13}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 19}, [{x, 0}]}.
    {test, is_eq, {f, 18}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 18}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 19}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 20}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 17}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 20}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 22}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 21}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 21}, [{x, 0}]}.
    {test, is_ne_exact, {f, 21}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 21}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 21}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 22}}.
  {label, 21}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 17}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 22}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
```

----- RUN LOG -----
```logs
1
2
```
