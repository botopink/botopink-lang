----- SOURCE CODE -- main.bp
```botopink
fn add(a: i32, b: i32) -> i32 {
    return a + b;
}

fn two() -> i32 {
    return 2;
}

fn main() {
    val a = comptime two();
    @print(a);
    val d = comptime {
        var d = 0;
        for ([1, 2, 3]) { b -> d = add(d, b); }
        break d;
    };
    @print(d);
}
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
  local.set $s3
  local.get $s3
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
  local.set $s3
  local.get $s3
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
  i32.const 88
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
  i32.const 96
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
  i32.const 104
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

(func $__bp_fns/0 (result i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  call $rt_nil
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
  i32.const 48
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
  "value": 2
}
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
  local.set $s3
  local.get $s3
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
  local.set $s3
  local.get $s3
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
  i32.const 88
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
  i32.const 96
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
  i32.const 104
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
  (local $s0 i32) (local $s1 i32) (local $s2 i32) (local $t6 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  i64.const 0
  call $rt_int
  local.set $s0
  (block $L4
  (block $L3
  local.get $s0
  local.set $s1
  br $L4
  )
  local.get $s0
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s0
  drop
  call $rt_nil
  local.set $s0
  global.get $__tbase
  i32.const 1
  i32.add
  i32.const 2
  local.get $s0
  call $rt_make_fun
  local.get $s1
  i64.const 1
  call $rt_int
  local.set $s0
  i64.const 2
  call $rt_int
  local.set $s1
  i64.const 3
  call $rt_int
  local.set $s2
  call $rt_nil
  local.set $t6
  local.get $s2
  local.get $t6
  call $rt_cons
  local.set $s2
  local.get $s1
  local.get $s2
  call $rt_cons
  local.set $s1
  local.get $s0
  local.get $s1
  call $rt_cons
  call $rt_lists_foldl
  call $rt_pending
  br_if $raise
  local.set $s0
  (block $L6
  (block $L5
  local.get $s0
  local.set $s1
  br $L6
  )
  local.get $s0
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s0
  drop
  local.get $s1
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

(func $fun2:__bp_ct_value/0 (param $self i32) (param $a0 i32) (param $a1 i32) (result i32)
  (local $s0 i32) (local $s1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $s0
  local.get $a1
  local.set $s1
  local.get $s1
  local.get $s0
  call $add/2
  call $rt_pending
  br_if $raise
  local.set $s0
  (block $L4
  (block $L3
  local.get $s0
  local.set $s1
  br $L4
  )
  local.get $s0
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s0
  drop
  local.get $s1
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
  (block $raise
  (block $L1 (result i32)
  (block $L2
  call $rt_nil
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
  i32.const 48
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

(func $add/2 (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_A i32) (local $V_B i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_A
  local.get $a1
  local.set $V_B
  local.get $V_A
  local.get $V_B
  call $bp_comptime_decorator:__bp_add/2
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
```

----- COMPTIME REPLY -- comptime block
```json
{
  "kind": "value",
  "value": 6
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).

add(A, B) ->
    '__bp_int'((A + B), -2147483648, 2147483647, <<"integer overflow: + on i32 at main.bp:2:14">>).

two() ->
    2.

main() ->
    A = 2,
    '__bp_print'([A]),
    D = 6,
    '__bp_print'([D]).

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when erlang:is_binary(V) -> V;
'__bp_show'(V, _) when erlang:is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when erlang:is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when erlang:is_tuple(V), erlang:tuple_size(V) > 0, erlang:is_atom(erlang:element(1, V)), erlang:element(1, V) =/= true, erlang:element(1, V) =/= false, erlang:element(1, V) =/= undefined -> '__bp_tagged'(erlang:element(1, V), V);
'__bp_show'(V, _) when erlang:is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- erlang:tuple_to_list(V)]), $)];
'__bp_show'(undefined, _) -> "null";
'__bp_show'(V, _) when erlang:is_atom(V), V =/= true, V =/= false, V =/= undefined -> '__bp_tagged'(V, V);
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'__bp_tagged'(A, V) ->
    M = case string:split(erlang:atom_to_list(A), "__v__") of [P, _] -> erlang:list_to_atom(P); _ -> A end,
    case code:ensure_loaded(M) =:= {module, M} andalso erlang:function_exported(M, '__bp_format', 1) of true -> '__bp_render'(erlang:apply(M, '__bp_format', [V])); false -> io_lib:format("~p", [V]) end.

'__bp_render'({text, T}) -> T;
'__bp_render'({variant, N, []}) -> N;
'__bp_render'({_, N, Fs}) -> [N, $(, lists:join(", ", [[K, ": ", '__bp_show'(Val, false)] || {K, Val} <- Fs]), $)].

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
2
6
```
