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

----- WASM TEXT -- std/dict.wat
```wasm
(module
  (memory (export "memory") 1)
  (table funcref (elem))
  (global $__heap_ptr (mut i32) (i32.const 256))
  ;; Gleam-inspired `dict` module — a `type Dict<K, V>` wrapping an
  ;; association list `pairs: Array<#(K, V)>` for full backend portability
  ;; (no host-backing). O(n) read; camelCase convention.
  ;; 
  ;; Instance operations are `self`-methods on the record; `empty` is a
  ;; top-level constructor (records hold state and are constructed — unlike
  ;; interfaces, which are pure behaviour contracts).
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
    i32.const 4
    i32.add
    global.set $__heap_ptr
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
    i32.store
    local.get $__mem0
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
    i32.const 4
    i32.add
    global.set $__heap_ptr
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
    i32.store
    local.get $__mem0
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
    i32.const 4
    i32.add
    global.set $__heap_ptr
    local.get $__mem2
    local.get $out
    i32.store
    local.get $__mem2
    return
  )
  (func $empty (export "empty") (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 4
    i32.add
    global.set $__heap_ptr
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
    i32.store
    local.get $__mem0
    return
  )
  ;; ── option method API over `at`'s `?V` (B1: Option map/flatMap/unwrapOr) ──
  ;; ── empty-collection boundary (B1) ──
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
import {dict} from "std";

fn main() {
    val d = dict.empty().insert("a", 1);
    @print(d.at("a").unwrapOr(0));
    @print(d.insert("b", 2).size());
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (table funcref (elem))
  (data (i32.const 256) "\01\00\00\00a")
  (data (i32.const 264) "\01\00\00\00b")
  (global $__heap_ptr (mut i32) (i32.const 272))
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
    i32.const 4
    i32.add
    global.set $__heap_ptr
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
    i32.store
    local.get $__mem0
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
    i32.const 4
    i32.add
    global.set $__heap_ptr
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
    i32.store
    local.get $__mem0
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
    i32.const 4
    i32.add
    global.set $__heap_ptr
    local.get $__mem2
    local.get $out
    i32.store
    local.get $__mem2
    return
  )
  (func $empty (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 4
    i32.add
    global.set $__heap_ptr
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
    i32.store
    local.get $__mem0
    return
  )
  (func $main
    (local $d i32)
    (local $_res0 i32)
    call $empty
    i32.const 256
    i32.const 1
    call $Dict_insert
    local.set $d
    local.get $d
    i32.const 256
    call $Dict_at
    local.set $_res0
    local.get $_res0 ;; Option (0 = None, else Some payload)
    (if (result i32)
      (then
    local.get $_res0 ;; Some — present value
      )
      (else
    i32.const 0
      )
    )
    call $__print_i32
    local.get $d
    i32.const 264
    i32.const 2
    call $Dict_insert
    call $Dict_size
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
2
```
