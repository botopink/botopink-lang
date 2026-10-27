----- SOURCE CODE -- main.bp
```botopink
type Op(name: string, run: fn() -> i32, twice: fn() -> i32)

fn two() -> i32 {
    return 2;
}

fn main() -> void {
    val op = comptime Op(name: "two" + "!", run: two, twice: { -> two() * 2 });
    print(op.name);
    print(op.run());
    print(op.twice());
}

import {io.terminal.print} from "std";
```

----- COMPTIME WAT -- comptime block
```wat
(func $__bp_lift/2 (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_V i32) (local $s1 i32) (local $t1 i32) (local $s3 i32) (local $s4 i32) (local $s5 i32) (local $V_E i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_V
  local.get $a1
  local.set $s1
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
  i32.const 80
  i32.add
  i32.const 4
  call $rt_atom
  br $L3
  )
  (block $L5
  local.get $t1
  global.get $__lit
  i32.const 88
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L5
  global.get $__lit
  i32.const 88
  i32.add
  i32.const 4
  call $rt_atom
  br $L3
  )
  (block $L6
  local.get $t1
  global.get $__lit
  i32.const 96
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L6
  global.get $__lit
  i32.const 96
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
  local.set $s3
  local.get $s3
  global.get $__lit
  i32.const 104
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
  local.set $s3
  local.get $s3
  global.get $__lit
  i32.const 112
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
  local.set $s3
  local.get $V_V
  local.set $s4
  (block $L27
  (loop $L28
  local.get $s4
  i32.const 12
  call $rt_is
  i32.eqz
  br_if $L27
  local.get $s4
  call $rt_hd
  local.set $s5
  local.get $s4
  call $rt_tl
  local.set $s4
  (block $L29
  local.get $s5
  local.set $V_E
  local.get $V_E
  local.get $s1
  call $__bp_lift/2
  call $rt_pending
  br_if $raise
  local.get $s3
  call $rt_cons
  local.set $s3
  )
  br $L28
  )
  )
  local.get $s3
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
  local.set $s3
  local.get $s3
  global.get $__lit
  i32.const 120
  i32.add
  i32.const 5
  call $rt_bin
  call $rt_nil
  local.set $s3
  local.get $V_V
  call $rt_erlang_tuple_to_list
  call $rt_pending
  br_if $raise
  local.set $s4
  (block $L34
  (loop $L35
  local.get $s4
  i32.const 12
  call $rt_is
  i32.eqz
  br_if $L34
  local.get $s4
  call $rt_hd
  local.set $s5
  local.get $s4
  call $rt_tl
  local.set $s4
  (block $L36
  local.get $s5
  local.set $V_E
  local.get $V_E
  local.get $s1
  call $__bp_lift/2
  call $rt_pending
  br_if $raise
  local.get $s3
  call $rt_cons
  local.set $s3
  )
  br $L35
  )
  )
  local.get $s3
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
  local.set $s3
  local.get $s3
  global.get $__lit
  i32.const 128
  i32.add
  i32.const 6
  call $rt_bin
  i32.const 1
  call $rt_tuple
  local.set $s3
  local.get $s3
  i32.const 0
  local.get $s1
  call $rt_tset
  drop
  local.get $s3
  local.set $s3
  global.get $__tbase
  i32.const 0
  i32.add
  i32.const 2
  local.get $s3
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
  local.set $s3
  local.get $s3
  global.get $__lit
  i32.const 136
  i32.add
  i32.const 2
  call $rt_bin
  local.get $V_V
  local.get $s1
  call $__bp_fn_index/2
  call $rt_pending
  br_if $raise
  call $rt_map_put
  br $L3
  )
  (block $L45
  call $rt_map_empty
  local.set $s1
  local.get $s1
  global.get $__lit
  i32.const 144
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
  (local $s0 i32) (local $s1 i32) (local $s2 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  (block $L3 (result i32)
  (block $L4
  call $rt_map_empty
  local.set $s0
  local.get $s0
  global.get $__lit
  i32.const 152
  i32.add
  i32.const 4
  call $rt_atom
  global.get $__lit
  i32.const 160
  i32.add
  i32.const 3
  call $rt_bin
  global.get $__lit
  i32.const 168
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $L4
  call $rt_map_put
  local.set $s0
  local.get $s0
  global.get $__lit
  i32.const 176
  i32.add
  i32.const 3
  call $rt_atom
  (block $L5 (result i32)
  (block $L6
  call $__bp_fn_0/0
  call $rt_pending
  br_if $L6
  br $L5
  )
  call $rt_class
  local.set $s0
  call $rt_reason
  local.set $s1
  call $rt_clear
  (block $L7 (result i32)
  (block $L8
  local.get $s0
  global.get $__lit
  i32.const 56
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L8
  local.get $s1
  local.set $s2
  global.get $__lit
  i32.const 184
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 8
  call $rt_int
  i64.const 50
  call $rt_int
  local.get $s2
  call $bp_comptime_decorator:__bp_push/4
  call $rt_pending
  br_if $L4
  drop
  global.get $__lit
  i32.const 56
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s2
  call $rt_raise
  drop
  br $L4
  call $rt_nil
  br $L7
  )
  local.get $s0
  local.get $s1
  call $rt_raise
  drop
  br $L4
  )
  br $L5
  )
  call $rt_map_put
  local.set $s0
  local.get $s0
  global.get $__lit
  i32.const 192
  i32.add
  i32.const 5
  call $rt_atom
  (block $L9 (result i32)
  (block $L10
  call $__bp_fn_1/0
  call $rt_pending
  br_if $L10
  br $L9
  )
  call $rt_class
  local.set $s0
  call $rt_reason
  local.set $s1
  call $rt_clear
  (block $L11 (result i32)
  (block $L12
  local.get $s0
  global.get $__lit
  i32.const 56
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L12
  local.get $s1
  local.set $s2
  global.get $__lit
  i32.const 184
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 8
  call $rt_int
  i64.const 62
  call $rt_int
  local.get $s2
  call $bp_comptime_decorator:__bp_push/4
  call $rt_pending
  br_if $L4
  drop
  global.get $__lit
  i32.const 56
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s2
  call $rt_raise
  drop
  br $L4
  call $rt_nil
  br $L11
  )
  local.get $s0
  local.get $s1
  call $rt_raise
  drop
  br $L4
  )
  br $L9
  )
  call $rt_map_put
  br $L3
  )
  call $rt_class
  local.set $s0
  call $rt_reason
  local.set $s1
  call $rt_clear
  (block $L13 (result i32)
  (block $L14
  local.get $s0
  global.get $__lit
  i32.const 56
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L14
  local.get $s1
  local.set $s2
  global.get $__lit
  i32.const 184
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 8
  call $rt_int
  i64.const 23
  call $rt_int
  local.get $s2
  call $bp_comptime_decorator:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 56
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s2
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L13
  )
  local.get $s0
  local.get $s1
  call $rt_raise
  drop
  br $raise
  )
  br $L3
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

(func $__bp_fns/0 (result i32)
  (local $s0 i32) (local $s1 i32) (local $t5 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  i32.const 2
  call $rt_tuple
  local.set $s0
  local.get $s0
  i32.const 0
  i64.const 0
  call $rt_int
  call $rt_tset
  drop
  local.get $s0
  i32.const 1
  call $__bp_fn_0/0
  call $rt_pending
  br_if $raise
  call $rt_tset
  drop
  local.get $s0
  local.set $s0
  i32.const 2
  call $rt_tuple
  local.set $s1
  local.get $s1
  i32.const 0
  i64.const 1
  call $rt_int
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  call $__bp_fn_1/0
  call $rt_pending
  br_if $raise
  call $rt_tset
  drop
  local.get $s1
  local.set $s1
  call $rt_nil
  local.set $t5
  local.get $s1
  local.get $t5
  call $rt_cons
  local.set $s1
  local.get $s0
  local.get $s1
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
  (local $V_F i32) (local $s1 i32) (local $s2 i32) (local $s3 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_F
  local.get $a1
  local.set $s1
  local.get $s1
  local.set $s1
  (block $L3 (result i32)
  (block $L4
  local.get $s1
  i32.const 11
  call $rt_is
  i32.eqz
  br_if $L4
  global.get $__lit
  i32.const 80
  i32.add
  i32.const 4
  call $rt_atom
  br $L3
  )
  (block $L5
  local.get $s1
  i32.const 12
  call $rt_is
  i32.eqz
  br_if $L5
  local.get $s1
  call $rt_hd
  local.set $s2
  local.get $s1
  call $rt_tl
  local.set $s3
  local.get $s2
  call $rt_tuple_arity
  i32.const 2
  i32.ne
  br_if $L5
  local.get $s2
  i32.const 0
  call $rt_elem
  local.set $s3
  local.get $s3
  local.set $s3
  local.get $s2
  i32.const 1
  call $rt_elem
  local.set $s2
  local.get $s2
  local.set $s2
  (block $L6
  (block $L7
  (block $L8
  local.get $s2
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
  local.get $s3
  br $L3
  )
  (block $L9
  local.get $s1
  i32.const 12
  call $rt_is
  i32.eqz
  br_if $L9
  local.get $s1
  call $rt_hd
  local.set $s2
  local.get $s1
  call $rt_tl
  local.set $s2
  local.get $s2
  local.set $s2
  local.get $V_F
  local.get $s2
  call $__bp_fn_index/2
  call $rt_pending
  br_if $raise
  br $L3
  )
  local.get $s1
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
  (local $t1 i32) (local $t2 i32) (local $V___BpF3 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  (block $L3 (result i32)
  (block $L4
  call $two/0
  call $rt_pending
  br_if $L4
  br $L3
  )
  call $rt_class
  local.set $t1
  call $rt_reason
  local.set $t2
  call $rt_clear
  (block $L5 (result i32)
  (block $L6
  local.get $t1
  global.get $__lit
  i32.const 56
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L6
  local.get $t2
  local.set $V___BpF3
  global.get $__lit
  i32.const 184
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 8
  call $rt_int
  i64.const 50
  call $rt_int
  local.get $V___BpF3
  call $bp_comptime_decorator:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 56
  i32.add
  i32.const 5
  call $rt_atom
  local.get $V___BpF3
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L5
  )
  local.get $t1
  local.get $t2
  call $rt_raise
  drop
  br $raise
  )
  br $L3
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
  (local $t1 i32) (local $t2 i32) (local $V___BpF4 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  (block $L3 (result i32)
  (block $L4
  call $two/0
  call $rt_pending
  br_if $L4
  br $L3
  )
  call $rt_class
  local.set $t1
  call $rt_reason
  local.set $t2
  call $rt_clear
  (block $L5 (result i32)
  (block $L6
  local.get $t1
  global.get $__lit
  i32.const 56
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L6
  local.get $t2
  local.set $V___BpF4
  global.get $__lit
  i32.const 184
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 8
  call $rt_int
  i64.const 67
  call $rt_int
  local.get $V___BpF4
  call $bp_comptime_decorator:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 56
  i32.add
  i32.const 5
  call $rt_atom
  local.get $V___BpF4
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L5
  )
  local.get $t1
  local.get $t2
  call $rt_raise
  drop
  br $raise
  )
  br $L3
  )
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
  )
  (rec
    (type $sig_0 (func (param (ref null $closure)) (result anyref)))
  )
  (rec
    (type $rec_Op (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut (ref null $str))) (field $f1 (mut (ref null $closure))) (field $f2 (mut (ref null $closure))))))
    (type $brand_rec_Op (struct (field f64) (field i32) (field i32) (field i64) (field i32) (field f32) (field f32) (field f32) (field i32) (field i32) (field i32) (field f32) (field i64) (field i64) (field i32) (field f32) (field i32) (field f64) (field i64) (field i32) (field f32) (field i64) (field i64) (field i32) (field f32) (field i32) (field i64) (field f64) (field f32) (field i64) (field i32) (field f32)))
  )
  (rec
    (type $env0 (sub final $closure (struct (field $fn funcref) (field $arity i32) (field $mark i32))))
    (type $env1 (sub final $closure (struct (field $fn funcref) (field $arity i32) (field $mark i32))))
  )
  (import "std@__rt" "__ti_register" (func $__ti_register (param structref)))
  (import "std@__rt" "__eq_decl" (func $__eq_decl (param anyref anyref) (result i32)))
  (import "std@__rt" "__write_bytes" (func $__write_bytes (param i32 i32)))
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (import "std@number" "std:number.floatToString" (func $__std_number_floatToString (param f64) (result i32)))
  (import "std@number" "wat:number.i64ToString" (func $__abi___std_number_i64ToString (param i64) (result arrayref)))
  (import "std@number" "wat:number.u64ToString" (func $__abi___std_number_u64ToString (param i64) (result arrayref)))
  (import "std@__rt" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (elem declare func $__fnref_two $__lambda1)
  (func $two (result i32)
    i32.const 2
    return
  )
  (func $main
    (local $__mem0 i32)
    (local $op (ref null $rec_Op))
    (local $__fnv0 (ref null $closure))
    (local $__fnv1 (ref null $closure))
    global.get $__s0
    ref.func $__fnref_two
    i32.const 0 ;; arity
    i32.const 0
    struct.new $env0
    ref.func $__lambda1
    i32.const 0 ;; arity
    i32.const 0
    struct.new $env1
    call $__new_23
    local.set $op
    local.get $op
    struct.get $rec_Op $f0
    call $__print_str
    local.get $op
    struct.get $rec_Op $f1
    local.set $__fnv0
    local.get $__fnv0
    local.get $__fnv0
    struct.get $closure $fn ;; the entry
    ref.cast (ref null $sig_0)
    call_ref $sig_0
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    call $__print_i32
    local.get $op
    struct.get $rec_Op $f2
    local.set $__fnv1
    local.get $__fnv1
    local.get $__fnv1
    struct.get $closure $fn ;; the entry
    ref.cast (ref null $sig_0)
    call_ref $sig_0
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    call $__print_i32
  )
  (func $__fnref_two (type $sig_0) (param $__env (ref null $closure)) (result anyref)
    call $two
    struct.new $box_i32
  )
  (func $__lambda1__b (param $__env (ref null $env1)) (result i32)
    call $two
    i32.const 2
    global.get $__s1
    call $__i32_mul_chk
  )
  (func $__lambda1 (type $sig_0) (param $__env (ref null $closure)) (result anyref)
    local.get $__env
    ref.cast (ref null $env1)
    call $__lambda1__b
    struct.new $box_i32
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
  (func $__pr1 (param $v (ref null $str))
    local.get $v
    call $__print_quoted_raw
  )
  (func $__pr2 (param $v anyref)
    global.get $__s6
    call $__print_str_raw
    local.get $v
    ref.cast (ref null $closure)
    struct.get $closure $arity
    call $__print_i32_raw
  )
  (func $__pr0 (param $v (ref null $rec_Op))
    global.get $__s2
    call $__print_str_raw
    global.get $__s3
    call $__print_str_raw
    global.get $__s4
    call $__print_str_raw
    local.get $v
    struct.get $rec_Op $f0
    call $__pr1
    global.get $__s5
    call $__print_str_raw
    local.get $v
    struct.get $rec_Op $f1
    call $__pr2
    global.get $__s7
    call $__print_str_raw
    local.get $v
    struct.get $rec_Op $f2
    call $__pr2
    global.get $__s8
    call $__print_str_raw
  )
  (func $__tip1 (param $v anyref)
    local.get $v
    ref.cast (ref null $rec_Op)
    call $__pr0
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
  (func $__tie1 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $rec_Op)
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
  (func $__unk_eq_s1 (param $a (ref null $rec_Op)) (param $b (ref null $rec_Op)) (result i32)
    local.get $a
    struct.get $rec_Op $f0
    local.get $b
    struct.get $rec_Op $f0
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_Op $f1
    local.get $b
    struct.get $rec_Op $f1
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_Op $f2
    local.get $b
    struct.get $rec_Op $f2
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
    ref.test (ref null $rec_Op)
    (if
      (then
    local.get $b
    ref.test (ref null $rec_Op)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $rec_Op)
    local.get $b
    ref.cast (ref null $rec_Op)
    call $__unk_eq_s1
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
  (func $__print_str_raw (param $s (ref null $str))
    (local $n i32) (local $p i32) (local $i i32) (local $top i32)
    local.get $s
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
        local.get $s
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
    call $__write_bytes
    local.get $top
    global.set $__heap_ptr
  )
  (func $__print_str (param $s (ref null $str))
    local.get $s
    call $__print_str_raw
    call $__print_nl
  )
  (func $__print_bool (param $b i32)
    local.get $b
    call $__print_bool_raw
    call $__print_nl
  )
  (func $__print_bool_raw (param $b i32)
    local.get $b
    (if
      (then
        ;; "true" as a little-endian i32
        i32.const 16
        i32.const 1702195828
        i32.store
        i32.const 16
        i32.const 4
        call $__write_bytes
      )
      (else
        ;; "fals" + 'e'
        i32.const 16
        i32.const 1936482662
        i32.store
        i32.const 16
        i32.const 101
        i32.store8 offset=4
        i32.const 16
        i32.const 5
        call $__write_bytes
      )
    )
  )
  (func $__print_f64 (param $x f64)
    local.get $x
    call $__print_f64_raw
    call $__print_nl
  )
  (func $__print_f64_raw (param $x f64)
    (local $s i32) (local $top i32)
    global.get $__heap_ptr
    local.set $top
    local.get $x
    call $__std_number_floatToString
    local.set $s
    local.get $s
    i32.const 4
    i32.add
    local.get $s
    i32.load
    call $__write_bytes
    local.get $top
    global.set $__heap_ptr
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
  (func $__print_quoted_raw (param $s (ref null $str))
    (local $n i32) (local $i i32) (local $ch i32) (local $e i32)
    i32.const 8
    i32.const 34
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
    local.get $s
    array.len
    local.set $n
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $s
        local.get $i
        array.get_u $str
        local.set $ch
        i32.const 0
        local.set $e
        local.get $ch
        i32.const 34
        i32.eq
        local.get $ch
        i32.const 92
        i32.eq
        i32.or
        (if
          (then
            local.get $ch
            local.set $e
          )
        )
        local.get $ch
        i32.const 10
        i32.eq
        (if
          (then
            i32.const 110
            local.set $e
          )
        )
        local.get $ch
        i32.const 13
        i32.eq
        (if
          (then
            i32.const 114
            local.set $e
          )
        )
        local.get $ch
        i32.const 9
        i32.eq
        (if
          (then
            i32.const 116
            local.set $e
          )
        )
        local.get $e
        (if
          (then
            i32.const 8
            i32.const 92
            i32.store8
            i32.const 8
            i32.const 1
            call $__write_bytes
            i32.const 8
            local.get $e
            i32.store8
            i32.const 8
            i32.const 1
            call $__write_bytes
          )
          (else
            i32.const 8
            local.get $ch
            i32.store8
            i32.const 8
            i32.const 1
            call $__write_bytes
          )
        )
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    i32.const 8
    i32.const 34
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
  )
  (func $__print_i64_raw (param $v i64)
    local.get $v
    call $__std_number_i64ToString
    call $__print_str_raw
  )
  (func $__print_i64 (param $v i64)
    local.get $v
    call $__print_i64_raw
    call $__print_nl
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
  (func $__print_u64_raw (param $v i64)
    local.get $v
    call $__std_number_u64ToString
    call $__print_str_raw
  )
  (func $__print_u64 (param $v i64)
    local.get $v
    call $__print_u64_raw
    call $__print_nl
  )
  (func $__chk_fail (param $site (ref null $str))
    local.get $site
    call $__panic_fail
    unreachable
  )
  (func $__std_number_i64ToString (param $p0 i64) (result (ref null $str))
    local.get $p0
    call $__abi___std_number_i64ToString
    ref.cast (ref null $str)
  )
  (func $__std_number_u64ToString (param $p0 i64) (result (ref null $str))
    local.get $p0
    call $__abi___std_number_u64ToString
    ref.cast (ref null $str)
  )
  (data $__d0 "two!")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "integer overflow: * on i32 at main.bp:8:73")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 "Op")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 "(")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (data $__d4 "name: ")
  (global $__s4 (mut (ref null $str)) (ref.null $str))
  (data $__d5 ", run: ")
  (global $__s5 (mut (ref null $str)) (ref.null $str))
  (data $__d6 "fn/")
  (global $__s6 (mut (ref null $str)) (ref.null $str))
  (data $__d7 ", twice: ")
  (global $__s7 (mut (ref null $str)) (ref.null $str))
  (data $__d8 ")")
  (global $__s8 (mut (ref null $str)) (ref.null $str))
  (data $__d9 "test@main.Op")
  (global $__s9 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 4
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 42
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
    i32.const 6
    array.new_data $str $__d4
    global.set $__s4
    i32.const 0
    i32.const 7
    array.new_data $str $__d5
    global.set $__s5
    i32.const 0
    i32.const 3
    array.new_data $str $__d6
    global.set $__s6
    i32.const 0
    i32.const 9
    array.new_data $str $__d7
    global.set $__s7
    i32.const 0
    i32.const 1
    array.new_data $str $__d8
    global.set $__s8
    i32.const 0
    i32.const 12
    array.new_data $str $__d9
    global.set $__s9
    call $__init_types
  )
  (func $__new_23 (param $f0 (ref null $str)) (param $f1 (ref null $closure)) (param $f2 (ref null $closure)) (result (ref null $rec_Op))
    global.get $__ti_23
    local.get $f0
    local.get $f1
    local.get $f2
    struct.new $rec_Op
  )
  (global $__ti_23 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (elem declare func $__tip1 $__tie1)
  (func $__init_types
    global.get $__s9
    ref.func $__tip1
    ref.func $__tie1
    ref.null func
    i32.const 0
    struct.new $__tinfo
    global.set $__ti_23
    global.get $__ti_23
    call $__ti_register
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
two!
2
4
```
