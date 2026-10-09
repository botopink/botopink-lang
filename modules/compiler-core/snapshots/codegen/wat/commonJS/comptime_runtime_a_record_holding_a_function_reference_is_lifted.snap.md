----- SOURCE CODE -- main.bp
```botopink
type Op(name: string, run: fn() -> i32, twice: fn() -> i32)

fn two() -> i32 {
    return 2;
}

fn main() {
    val op = comptime Op(name: "two" + "!", run: two, twice: { -> two() * 2 });
    @print(op.name);
    @print(op.run());
    @print(op.twice());
}
```

----- COMPTIME WAT -- comptime block
```wat
(func $__bp_lift/2 (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_V i32) (local $V_R i32) (local $t1 i32) (local $t2 i32) (local $t3 i32) (local $t4 i32) (local $t5 i32) (local $t6 i32) (local $V_E i32) (local $t7 i32) (local $t8 i32) (local $t9 i32) (local $t10 i32) (local $t11 i32) (local $t12 i32) (local $t13 i32) (local $t14 i32) (local $t15 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_V
  local.get $a1
  local.set $V_R
  local.get $V_V
  local.set $t1
  (block $L3 (result i32)
  (block $L4
  local.get $t1
  global.get $__lit
  i32.const 32
  i32.add
  i32.const 9
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L4
  global.get $__lit
  i32.const 48
  i32.add
  i32.const 4
  call $rt_atom
  br $L3
  )
  (block $L5
  local.get $t1
  global.get $__lit
  i32.const 56
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L5
  global.get $__lit
  i32.const 56
  i32.add
  i32.const 4
  call $rt_atom
  br $L3
  )
  (block $L6
  local.get $t1
  global.get $__lit
  i32.const 64
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L6
  global.get $__lit
  i32.const 64
  i32.add
  i32.const 5
  call $rt_atom
  br $L3
  )
  (block $L7
  (block $L8
  (block $L9
  (block $L10
  local.get $V_V
  call $rt_erlang_is_integer
  call $rt_pending
  br_if $L10
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L9
  br $L8
  )
  call $rt_clear
  )
  br $L7
  )
  local.get $V_V
  br $L3
  )
  (block $L11
  (block $L12
  (block $L13
  (block $L14
  local.get $V_V
  call $rt_erlang_is_float
  call $rt_pending
  br_if $L14
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L13
  br $L12
  )
  call $rt_clear
  )
  br $L11
  )
  call $rt_map_empty
  local.set $t2
  local.get $t2
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_bin
  local.get $V_V
  call $rt_map_put
  br $L3
  )
  (block $L15
  (block $L16
  (block $L17
  (block $L18
  local.get $V_V
  call $rt_erlang_is_binary
  call $rt_pending
  br_if $L18
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L17
  br $L16
  )
  call $rt_clear
  )
  br $L15
  )
  local.get $V_V
  br $L3
  )
  (block $L19
  (block $L20
  (block $L21
  (block $L22
  local.get $V_V
  call $rt_erlang_is_atom
  call $rt_pending
  br_if $L22
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L21
  br $L20
  )
  call $rt_clear
  )
  br $L19
  )
  call $rt_map_empty
  local.set $t3
  local.get $t3
  global.get $__lit
  i32.const 80
  i32.add
  i32.const 4
  call $rt_bin
  local.get $V_V
  call $rt_erlang_atom_to_binary
  call $rt_pending
  br_if $raise
  call $rt_map_put
  br $L3
  )
  (block $L23
  (block $L24
  (block $L25
  (block $L26
  local.get $V_V
  call $rt_erlang_is_list
  call $rt_pending
  br_if $L26
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L25
  br $L24
  )
  call $rt_clear
  )
  br $L23
  )
  call $rt_nil
  local.set $t4
  local.get $V_V
  local.set $t5
  (block $L27
  (loop $L28
  local.get $t5
  i32.const 12
  call $rt_is
  i32.eqz
  br_if $L27
  local.get $t5
  call $rt_hd
  local.set $t6
  local.get $t5
  call $rt_tl
  local.set $t5
  (block $L29
  local.get $t6
  local.set $V_E
  local.get $V_E
  local.get $V_R
  call $__bp_lift/2
  call $rt_pending
  br_if $raise
  local.get $t4
  call $rt_cons
  local.set $t4
  )
  br $L28
  )
  )
  local.get $t4
  call $rt_lists_reverse
  br $L3
  )
  (block $L30
  (block $L31
  (block $L32
  (block $L33
  local.get $V_V
  call $rt_erlang_is_tuple
  call $rt_pending
  br_if $L33
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L32
  br $L31
  )
  call $rt_clear
  )
  br $L30
  )
  call $rt_map_empty
  local.set $t7
  local.get $t7
  global.get $__lit
  i32.const 88
  i32.add
  i32.const 5
  call $rt_bin
  call $rt_nil
  local.set $t8
  local.get $V_V
  call $rt_erlang_tuple_to_list
  call $rt_pending
  br_if $raise
  local.set $t9
  (block $L34
  (loop $L35
  local.get $t9
  i32.const 12
  call $rt_is
  i32.eqz
  br_if $L34
  local.get $t9
  call $rt_hd
  local.set $t10
  local.get $t9
  call $rt_tl
  local.set $t9
  (block $L36
  local.get $t10
  local.set $V_E
  local.get $V_E
  local.get $V_R
  call $__bp_lift/2
  call $rt_pending
  br_if $raise
  local.get $t8
  call $rt_cons
  local.set $t8
  )
  br $L35
  )
  )
  local.get $t8
  call $rt_lists_reverse
  call $rt_map_put
  br $L3
  )
  (block $L37
  (block $L38
  (block $L39
  (block $L40
  local.get $V_V
  call $rt_erlang_is_map
  call $rt_pending
  br_if $L40
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L39
  br $L38
  )
  call $rt_clear
  )
  br $L37
  )
  call $rt_map_empty
  local.set $t11
  local.get $t11
  global.get $__lit
  i32.const 96
  i32.add
  i32.const 6
  call $rt_bin
  i32.const 1
  call $rt_tuple
  local.set $t12
  local.get $t12
  i32.const 0
  local.get $V_R
  call $rt_tset
  drop
  local.get $t12
  local.set $t13
  global.get $__tbase
  i32.const 0
  i32.add
  i32.const 2
  local.get $t13
  call $rt_make_fun
  local.get $V_V
  call $rt_maps_map
  call $rt_pending
  br_if $raise
  call $rt_map_put
  br $L3
  )
  (block $L41
  (block $L42
  (block $L43
  (block $L44
  local.get $V_V
  call $rt_erlang_is_function
  call $rt_pending
  br_if $L44
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L43
  br $L42
  )
  call $rt_clear
  )
  br $L41
  )
  call $rt_map_empty
  local.set $t14
  local.get $t14
  global.get $__lit
  i32.const 104
  i32.add
  i32.const 2
  call $rt_bin
  local.get $V_V
  local.get $V_R
  call $__bp_fn_index/2
  call $rt_pending
  br_if $raise
  call $rt_map_put
  br $L3
  )
  (block $L45
  call $rt_map_empty
  local.set $t15
  local.get $t15
  global.get $__lit
  i32.const 112
  i32.add
  i32.const 8
  call $rt_bin
  local.get $V_V
  call $bp_comptime_decorator:__bp_text/1
  call $rt_pending
  br_if $raise
  call $rt_map_put
  br $L3
  )
  local.get $t1
  call $rt_case_clause
  drop
  br $raise
  )
  br $L1
  )
  call $rt_function_clause
  drop
  br $raise
  )
  return
  )
  i32.const 0
)

(func $fun1:__bp_lift/2 (param $self i32) (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_R i32) (local $V_X i32)
  (block $raise
  local.get $self
  call $rt_fun_env
  i32.const 0
  call $rt_elem
  local.set $V_R
  (block $L1 (result i32)
  (block $L2
  local.get $a1
  local.set $V_X
  local.get $V_X
  local.get $V_R
  call $__bp_lift/2
  call $rt_pending
  br_if $raise
  br $L1
  )
  call $rt_function_clause
  drop
  br $raise
  )
  return
  )
  i32.const 0
)

(func $__bp_ct_value/0 (result i32)
  (local $t1 i32) (local $t2 i32) (local $t3 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  call $rt_map_empty
  local.set $t1
  local.get $t1
  global.get $__lit
  i32.const 120
  i32.add
  i32.const 4
  call $rt_atom
  global.get $__lit
  i32.const 128
  i32.add
  i32.const 3
  call $rt_bin
  global.get $__lit
  i32.const 136
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  call $rt_map_put
  local.set $t2
  local.get $t2
  global.get $__lit
  i32.const 144
  i32.add
  i32.const 3
  call $rt_atom
  call $__bp_fn_0/0
  call $rt_pending
  br_if $raise
  call $rt_map_put
  local.set $t3
  local.get $t3
  global.get $__lit
  i32.const 152
  i32.add
  i32.const 5
  call $rt_atom
  call $__bp_fn_1/0
  call $rt_pending
  br_if $raise
  call $rt_map_put
  br $L1
  )
  call $rt_function_clause
  drop
  br $raise
  )
  return
  )
  i32.const 0
)

(func $__bp_fns/0 (result i32)
  (local $t1 i32) (local $t2 i32) (local $t3 i32) (local $t4 i32) (local $t5 i32) (local $t6 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  i32.const 2
  call $rt_tuple
  local.set $t2
  local.get $t2
  i32.const 0
  i64.const 0
  call $rt_int
  call $rt_tset
  drop
  local.get $t2
  i32.const 1
  call $__bp_fn_0/0
  call $rt_pending
  br_if $raise
  call $rt_tset
  drop
  local.get $t2
  local.set $t1
  i32.const 2
  call $rt_tuple
  local.set $t4
  local.get $t4
  i32.const 0
  i64.const 1
  call $rt_int
  call $rt_tset
  drop
  local.get $t4
  i32.const 1
  call $__bp_fn_1/0
  call $rt_pending
  br_if $raise
  call $rt_tset
  drop
  local.get $t4
  local.set $t3
  call $rt_nil
  local.set $t5
  local.get $t3
  local.get $t5
  call $rt_cons
  local.set $t6
  local.get $t1
  local.get $t6
  call $rt_cons
  br $L1
  )
  call $rt_function_clause
  drop
  br $raise
  )
  return
  )
  i32.const 0
)

(func $__bp_fn_index/2 (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_F i32) (local $V_R i32) (local $t1 i32) (local $t2 i32) (local $t3 i32) (local $t4 i32) (local $V_I i32) (local $t5 i32) (local $V_G i32) (local $t6 i32) (local $t7 i32) (local $V_Rest i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_F
  local.get $a1
  local.set $V_R
  local.get $V_R
  local.set $t1
  (block $L3 (result i32)
  (block $L4
  local.get $t1
  i32.const 11
  call $rt_is
  i32.eqz
  br_if $L4
  global.get $__lit
  i32.const 48
  i32.add
  i32.const 4
  call $rt_atom
  br $L3
  )
  (block $L5
  local.get $t1
  i32.const 12
  call $rt_is
  i32.eqz
  br_if $L5
  local.get $t1
  call $rt_hd
  local.set $t2
  local.get $t1
  call $rt_tl
  local.set $t3
  local.get $t2
  call $rt_tuple_arity
  i32.const 2
  i32.ne
  br_if $L5
  local.get $t2
  i32.const 0
  call $rt_elem
  local.set $t4
  local.get $t4
  local.set $V_I
  local.get $t2
  i32.const 1
  call $rt_elem
  local.set $t5
  local.get $t5
  local.set $V_G
  (block $L6
  (block $L7
  (block $L8
  local.get $V_G
  local.get $V_F
  call $rt_eqx
  call $rt_bool
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L7
  br $L6
  )
  call $rt_clear
  )
  br $L5
  )
  local.get $V_I
  br $L3
  )
  (block $L9
  local.get $t1
  i32.const 12
  call $rt_is
  i32.eqz
  br_if $L9
  local.get $t1
  call $rt_hd
  local.set $t6
  local.get $t1
  call $rt_tl
  local.set $t7
  local.get $t7
  local.set $V_Rest
  local.get $V_F
  local.get $V_Rest
  call $__bp_fn_index/2
  call $rt_pending
  br_if $raise
  br $L3
  )
  local.get $t1
  call $rt_case_clause
  drop
  br $raise
  )
  br $L1
  )
  call $rt_function_clause
  drop
  br $raise
  )
  return
  )
  i32.const 0
)

(func $__bp_fn_0/0 (result i32)
  (local $t1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  call $rt_nil
  local.set $t1
  global.get $__tbase
  i32.const 1
  i32.add
  i32.const 0
  local.get $t1
  call $rt_make_fun
  br $L1
  )
  call $rt_function_clause
  drop
  br $raise
  )
  return
  )
  i32.const 0
)

(func $fun2:__bp_fn_0/0 (param $self i32) (result i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  call $two/0
  call $rt_pending
  br_if $raise
  br $L1
  )
  call $rt_function_clause
  drop
  br $raise
  )
  return
  )
  i32.const 0
)

(func $__bp_fn_1/0 (result i32)
  (local $t1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  call $rt_nil
  local.set $t1
  global.get $__tbase
  i32.const 2
  i32.add
  i32.const 0
  local.get $t1
  call $rt_make_fun
  br $L1
  )
  call $rt_function_clause
  drop
  br $raise
  )
  return
  )
  i32.const 0
)

(func $fun3:__bp_fn_1/0 (param $self i32) (result i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  call $two/0
  call $rt_pending
  br_if $raise
  i64.const 2
  call $rt_int
  call $rt_mul
  call $rt_pending
  br_if $raise
  br $L1
  )
  call $rt_function_clause
  drop
  br $raise
  )
  return
  )
  i32.const 0
)

(func $two/0 (result i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  i64.const 2
  call $rt_int
  br $L1
  )
  call $rt_function_clause
  drop
  br $raise
  )
  return
  )
  i32.const 0
)
```

----- COMPTIME REPLY -- comptime block
```json
{
  "kind": "value",
  "value": {
    "record": {
      "name": "two!",
      "run": {
        "fn": 0
      },
      "twice": {
        "fn": 1
      }
    }
  }
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

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what); }

class Op {
    constructor(name, run, twice) {
        this.name = name;
        this.run = run;
        this.twice = twice;
    }
}
Op.prototype.__bp = "Op";

function two() {
    return 2;
}

function main() {
    const op = new Op("two!", two, () => {
    return __bp_int((two() * 2), -2147483648, 2147483647, "* on i32 at main.bp:8:73");
});
    __bp_print(op.name);
    __bp_print(op.run());
    __bp_print(op.twice());
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
two!
2
4
```
