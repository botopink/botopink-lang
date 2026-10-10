----- SOURCE CODE -- main.bp
```botopink
pub fn describe(comptime decl: @Decl) {
    val names = decl.fields.map({ f -> f.name });
    val upper = names.map({ n -> n.toUpper() }).join("_");
    val hidden = if (names.contains("secret")) { "hidden"; } else { "open"; };
    val short = decl.name.slice(0, 3);
    val size = if (decl.name.length() == 4) { "four"; } else { "other"; };
    @emit("pub fn describe" + decl.name + "() -> string { return \"" + upper + ":" + hidden + ":" + short + ":" + size + "\"; }");
}

#[describe]
type User(name: string, secret: string, age: i32)

fn main() {
    @print(describeUser());
}
```

----- COMPTIME WAT -- decorator describe
```wat
(func $describe/1 (param $a0 i32) (result i32)
  (local $V_Decl i32) (local $s1 i32) (local $s2 i32) (local $V_Upper i32) (local $V_Short i32) (local $V_Size i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Decl
  global.get $__lit
  i32.const 112
  i32.add
  i32.const 6
  call $rt_atom
  local.get $V_Decl
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $rt_nil
  local.set $s1
  global.get $__tbase
  i32.const 0
  i32.add
  i32.const 1
  local.get $s1
  call $rt_make_fun
  call $__bp_prim_map/2
  call $rt_pending
  br_if $raise
  local.set $s1
  (block $L4
  (block $L3
  local.get $s1
  local.set $s2
  br $L4
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  local.get $s2
  call $rt_nil
  local.set $s1
  global.get $__tbase
  i32.const 1
  i32.add
  i32.const 1
  local.get $s1
  call $rt_make_fun
  call $__bp_prim_map/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 128
  i32.add
  i32.const 1
  call $rt_bin
  call $__bp_prim_join/2
  call $rt_pending
  br_if $raise
  local.set $s1
  (block $L6
  (block $L5
  local.get $s1
  local.set $V_Upper
  br $L6
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  local.get $s2
  global.get $__lit
  i32.const 136
  i32.add
  i32.const 6
  call $rt_bin
  call $__bp_prim_contains/2
  call $rt_pending
  br_if $raise
  local.set $s1
  (block $L7 (result i32)
  (block $L8
  local.get $s1
  global.get $__lit
  i32.const 144
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L8
  global.get $__lit
  i32.const 152
  i32.add
  i32.const 6
  call $rt_bin
  br $L7
  )
  (block $L9
  local.get $s1
  global.get $__lit
  i32.const 160
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L9
  global.get $__lit
  i32.const 168
  i32.add
  i32.const 4
  call $rt_bin
  br $L7
  )
  local.get $s1
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s1
  (block $L11
  (block $L10
  local.get $s1
  local.set $s2
  br $L11
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  global.get $__lit
  i32.const 120
  i32.add
  i32.const 4
  call $rt_atom
  local.get $V_Decl
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  i64.const 0
  call $rt_int
  i64.const 3
  call $rt_int
  call $__bp_prim_slice/3
  call $rt_pending
  br_if $raise
  local.set $s1
  (block $L13
  (block $L12
  local.get $s1
  local.set $V_Short
  br $L13
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  global.get $__lit
  i32.const 120
  i32.add
  i32.const 4
  call $rt_atom
  local.get $V_Decl
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $__bp_prim_length/1
  call $rt_pending
  br_if $raise
  i64.const 4
  call $rt_int
  call $rt_eqx
  call $rt_bool
  local.set $s1
  (block $L14 (result i32)
  (block $L15
  local.get $s1
  global.get $__lit
  i32.const 144
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L15
  global.get $__lit
  i32.const 176
  i32.add
  i32.const 4
  call $rt_bin
  br $L14
  )
  (block $L16
  local.get $s1
  global.get $__lit
  i32.const 160
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L16
  global.get $__lit
  i32.const 184
  i32.add
  i32.const 5
  call $rt_bin
  br $L14
  )
  local.get $s1
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s1
  (block $L18
  (block $L17
  local.get $s1
  local.set $V_Size
  br $L18
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  global.get $__lit
  i32.const 192
  i32.add
  i32.const 15
  call $rt_bin
  global.get $__lit
  i32.const 120
  i32.add
  i32.const 4
  call $rt_atom
  local.get $V_Decl
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 208
  i32.add
  i32.const 23
  call $rt_bin
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  local.get $V_Upper
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 232
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  local.get $s2
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 232
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  local.get $V_Short
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 232
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  local.get $V_Size
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 240
  i32.add
  i32.const 4
  call $rt_bin
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  call $bp_comptime_decorator:emit/1
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

(func $fun1:describe/1 (param $self i32) (param $a0 i32) (result i32)
  (local $V_F i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_F
  global.get $__lit
  i32.const 120
  i32.add
  i32.const 4
  call $rt_atom
  local.get $V_F
  call $rt_maps_get
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

(func $fun2:describe/1 (param $self i32) (param $a0 i32) (result i32)
  (local $V_N i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_N
  local.get $V_N
  call $__bp_prim_toUpper/1
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

(func $__bp_prim_map/2 (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_Recv i32) (local $s1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Recv
  local.get $a1
  local.set $s1
  (block $L3
  (block $L4
  (block $L5
  local.get $V_Recv
  call $rt_erlang_is_list
  call $rt_pending
  br_if $L5
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L4
  br $L3
  )
  call $rt_clear
  )
  br $L2
  )
  local.get $s1
  local.get $V_Recv
  call $rt_lists_map
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L6
  local.get $a0
  local.set $V_Recv
  i32.const 4
  call $rt_tuple
  local.set $s1
  local.get $s1
  i32.const 0
  global.get $__lit
  i32.const 272
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 3
  call $rt_bin
  call $rt_tset
  drop
  local.get $s1
  i32.const 2
  i64.const 1
  call $rt_int
  call $rt_tset
  drop
  local.get $s1
  i32.const 3
  local.get $V_Recv
  call $rt_tset
  drop
  local.get $s1
  call $rt_error
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

(func $__bp_prim_join/2 (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_Recv i32) (local $s1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Recv
  local.get $a1
  local.set $s1
  (block $L3
  (block $L4
  (block $L5
  local.get $V_Recv
  call $rt_erlang_is_list
  call $rt_pending
  br_if $L5
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L4
  br $L3
  )
  call $rt_clear
  )
  br $L2
  )
  local.get $s1
  call $rt_nil
  local.set $s1
  global.get $__tbase
  i32.const 2
  i32.add
  i32.const 1
  local.get $s1
  call $rt_make_fun
  local.get $V_Recv
  call $rt_lists_map
  call $rt_pending
  br_if $raise
  call $rt_lists_join
  call $rt_pending
  br_if $raise
  call $rt_erlang_iolist_to_binary
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L6
  local.get $a0
  local.set $V_Recv
  i32.const 4
  call $rt_tuple
  local.set $s1
  local.get $s1
  i32.const 0
  global.get $__lit
  i32.const 272
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  global.get $__lit
  i32.const 304
  i32.add
  i32.const 4
  call $rt_bin
  call $rt_tset
  drop
  local.get $s1
  i32.const 2
  i64.const 1
  call $rt_int
  call $rt_tset
  drop
  local.get $s1
  i32.const 3
  local.get $V_Recv
  call $rt_tset
  drop
  local.get $s1
  call $rt_error
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

(func $fun3:__bp_prim_join/2 (param $self i32) (param $a0 i32) (result i32)
  (local $s0 i32) (local $s1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $s0
  (block $L3 (result i32)
  (block $L4
  (block $L5
  (block $L6
  (block $L7
  local.get $s0
  call $rt_erlang_is_binary
  call $rt_pending
  br_if $L7
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L6
  br $L5
  )
  call $rt_clear
  )
  br $L4
  )
  local.get $s0
  br $L3
  )
  (block $L8
  (block $L9
  (block $L10
  (block $L11
  local.get $s0
  call $rt_erlang_is_integer
  call $rt_pending
  br_if $L11
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L10
  br $L9
  )
  call $rt_clear
  )
  br $L8
  )
  local.get $s0
  call $rt_erlang_integer_to_binary
  call $rt_pending
  br_if $raise
  br $L3
  )
  (block $L12
  (block $L13
  (block $L14
  (block $L15
  local.get $s0
  call $rt_erlang_is_list
  call $rt_pending
  br_if $L15
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L14
  br $L13
  )
  call $rt_clear
  )
  br $L12
  )
  local.get $s0
  br $L3
  )
  (block $L16
  (block $L17
  (block $L18
  (block $L19
  global.get $__lit
  i32.const 144
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L18
  br $L17
  )
  call $rt_clear
  )
  br $L16
  )
  call $rt_nil
  local.set $s1
  i64.const 112
  call $rt_int
  local.get $s1
  call $rt_cons
  local.set $s1
  i64.const 126
  call $rt_int
  local.get $s1
  call $rt_cons
  local.get $s0
  local.set $s0
  call $rt_nil
  local.set $s1
  local.get $s0
  local.get $s1
  call $rt_cons
  call $rt_io_lib_format
  call $rt_pending
  br_if $raise
  call $rt_erlang_iolist_to_binary
  call $rt_pending
  br_if $raise
  br $L3
  )
  call $rt_if_clause
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

(func $__bp_prim_toUpper/1 (param $a0 i32) (result i32)
  (local $V_Recv i32) (local $t1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Recv
  (block $L3
  (block $L4
  (block $L5
  local.get $V_Recv
  call $rt_erlang_is_binary
  call $rt_pending
  br_if $L5
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L4
  br $L3
  )
  call $rt_clear
  )
  br $L2
  )
  local.get $V_Recv
  call $rt_string_uppercase
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L6
  local.get $a0
  local.set $V_Recv
  i32.const 4
  call $rt_tuple
  local.set $t1
  local.get $t1
  i32.const 0
  global.get $__lit
  i32.const 272
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $t1
  i32.const 1
  global.get $__lit
  i32.const 312
  i32.add
  i32.const 7
  call $rt_bin
  call $rt_tset
  drop
  local.get $t1
  i32.const 2
  i64.const 0
  call $rt_int
  call $rt_tset
  drop
  local.get $t1
  i32.const 3
  local.get $V_Recv
  call $rt_tset
  drop
  local.get $t1
  call $rt_error
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

(func $__bp_prim_contains/2 (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_Recv i32) (local $s1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Recv
  local.get $a1
  local.set $s1
  (block $L3
  (block $L4
  (block $L5
  local.get $V_Recv
  call $rt_erlang_is_list
  call $rt_pending
  br_if $L5
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L4
  br $L3
  )
  call $rt_clear
  )
  br $L2
  )
  local.get $s1
  local.get $V_Recv
  call $rt_lists_member
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L6
  local.get $a0
  local.set $V_Recv
  local.get $a1
  local.set $s1
  (block $L7
  (block $L8
  (block $L9
  local.get $V_Recv
  call $rt_erlang_is_binary
  call $rt_pending
  br_if $L9
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L8
  br $L7
  )
  call $rt_clear
  )
  br $L6
  )
  local.get $V_Recv
  local.get $s1
  call $rt_string_find
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 320
  i32.add
  i32.const 7
  call $rt_atom
  call $rt_eqx
  i32.eqz
  call $rt_bool
  br $L1
  )
  (block $L10
  local.get $a0
  local.set $V_Recv
  i32.const 4
  call $rt_tuple
  local.set $s1
  local.get $s1
  i32.const 0
  global.get $__lit
  i32.const 272
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  global.get $__lit
  i32.const 328
  i32.add
  i32.const 8
  call $rt_bin
  call $rt_tset
  drop
  local.get $s1
  i32.const 2
  i64.const 1
  call $rt_int
  call $rt_tset
  drop
  local.get $s1
  i32.const 3
  local.get $V_Recv
  call $rt_tset
  drop
  local.get $s1
  call $rt_error
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

(func $__bp_prim_slice/3 (param $a0 i32) (param $a1 i32) (param $a2 i32) (result i32)
  (local $V_Recv i32) (local $s1 i32) (local $V_Arg1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Recv
  local.get $a1
  local.set $s1
  local.get $a2
  local.set $V_Arg1
  (block $L3
  (block $L4
  (block $L5
  local.get $V_Recv
  call $rt_erlang_is_list
  call $rt_pending
  br_if $L5
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L4
  br $L3
  )
  call $rt_clear
  )
  br $L2
  )
  local.get $V_Recv
  local.get $s1
  local.get $V_Arg1
  call $array_slice/3
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L6
  local.get $a0
  local.set $V_Recv
  local.get $a1
  local.set $s1
  local.get $a2
  local.set $V_Arg1
  (block $L7
  (block $L8
  (block $L9
  local.get $V_Recv
  call $rt_erlang_is_binary
  call $rt_pending
  br_if $L9
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L8
  br $L7
  )
  call $rt_clear
  )
  br $L6
  )
  local.get $V_Recv
  local.get $s1
  local.get $V_Arg1
  call $string_slice/3
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L10
  local.get $a0
  local.set $V_Recv
  i32.const 4
  call $rt_tuple
  local.set $s1
  local.get $s1
  i32.const 0
  global.get $__lit
  i32.const 272
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  global.get $__lit
  i32.const 336
  i32.add
  i32.const 5
  call $rt_bin
  call $rt_tset
  drop
  local.get $s1
  i32.const 2
  i64.const 2
  call $rt_int
  call $rt_tset
  drop
  local.get $s1
  i32.const 3
  local.get $V_Recv
  call $rt_tset
  drop
  local.get $s1
  call $rt_error
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

(func $__bp_prim_length/1 (param $a0 i32) (result i32)
  (local $V_Recv i32) (local $t1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Recv
  (block $L3
  (block $L4
  (block $L5
  local.get $V_Recv
  call $rt_erlang_is_list
  call $rt_pending
  br_if $L5
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L4
  br $L3
  )
  call $rt_clear
  )
  br $L2
  )
  local.get $V_Recv
  call $rt_erlang_length
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L6
  local.get $a0
  local.set $V_Recv
  (block $L7
  (block $L8
  (block $L9
  local.get $V_Recv
  call $rt_erlang_is_binary
  call $rt_pending
  br_if $L9
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L8
  br $L7
  )
  call $rt_clear
  )
  br $L6
  )
  local.get $V_Recv
  call $rt_unicode_characters_to_list
  call $rt_pending
  br_if $raise
  call $rt_erlang_length
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L10
  local.get $a0
  local.set $V_Recv
  i32.const 4
  call $rt_tuple
  local.set $t1
  local.get $t1
  i32.const 0
  global.get $__lit
  i32.const 272
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $t1
  i32.const 1
  global.get $__lit
  i32.const 344
  i32.add
  i32.const 6
  call $rt_bin
  call $rt_tset
  drop
  local.get $t1
  i32.const 2
  i64.const 0
  call $rt_int
  call $rt_tset
  drop
  local.get $t1
  i32.const 3
  local.get $V_Recv
  call $rt_tset
  drop
  local.get $t1
  call $rt_error
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

(func $array_slice/3 (param $a0 i32) (param $a1 i32) (param $a2 i32) (result i32)
  (local $V_Self i32) (local $V_Start i32) (local $V_End i32) (local $t1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Self
  local.get $a1
  local.set $V_Start
  local.get $a2
  local.set $V_End
  local.get $V_End
  global.get $__lit
  i32.const 248
  i32.add
  i32.const 9
  call $rt_atom
  call $rt_eqx
  i32.eqz
  call $rt_bool
  local.set $t1
  (block $L3 (result i32)
  (block $L4
  local.get $t1
  global.get $__lit
  i32.const 144
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L4
  local.get $V_Self
  local.get $V_Start
  i64.const 1
  call $rt_int
  call $rt_add
  call $rt_pending
  br_if $raise
  local.get $V_End
  local.get $V_Start
  call $rt_sub
  call $rt_pending
  br_if $raise
  call $rt_lists_sublist3
  call $rt_pending
  br_if $raise
  br $L3
  )
  (block $L5
  local.get $t1
  global.get $__lit
  i32.const 160
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L5
  local.get $V_Start
  local.get $V_Self
  call $rt_lists_nthtail
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

(func $string_slice/3 (param $a0 i32) (param $a1 i32) (param $a2 i32) (result i32)
  (local $s0 i32) (local $s1 i32) (local $s2 i32) (local $t1 i32) (local $s4 i32) (local $t4 i32) (local $t5 i32) (local $t7 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $s0
  local.get $a1
  local.set $s1
  local.get $a2
  local.set $s2
  local.get $s2
  global.get $__lit
  i32.const 248
  i32.add
  i32.const 9
  call $rt_atom
  call $rt_eqx
  i32.eqz
  call $rt_bool
  local.set $t1
  (block $L3 (result i32)
  (block $L4
  local.get $t1
  global.get $__lit
  i32.const 144
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L4
  call $rt_nil
  local.set $s4
  global.get $__tbase
  i32.const 3
  i32.add
  i32.const 3
  local.get $s4
  call $rt_make_fun
  local.set $s4
  local.get $s0
  local.set $t4
  local.get $s1
  local.set $t5
  local.get $s2
  local.set $s2
  local.get $s4
  i32.const 3
  call $rt_nil
  call $rt_fun_index
  call $rt_pending
  br_if $raise
  local.set $t7
  local.get $s4
  local.get $t4
  local.get $t5
  local.get $s2
  local.get $t7
  call_indirect (param i32 i32 i32 i32) (result i32)
  call $rt_pending
  br_if $raise
  br $L3
  )
  (block $L5
  local.get $t1
  global.get $__lit
  i32.const 160
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L5
  call $rt_nil
  local.set $s2
  global.get $__tbase
  i32.const 4
  i32.add
  i32.const 2
  local.get $s2
  call $rt_make_fun
  local.set $s2
  local.get $s0
  local.set $s0
  local.get $s1
  local.set $s1
  local.get $s2
  i32.const 2
  call $rt_nil
  call $rt_fun_index
  call $rt_pending
  br_if $raise
  local.set $s4
  local.get $s2
  local.get $s0
  local.get $s1
  local.get $s4
  call_indirect (param i32 i32 i32) (result i32)
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

(func $fun4:string_slice/3 (param $self i32) (param $a0 i32) (param $a1 i32) (param $a2 i32) (result i32)
  (local $s0 i32) (local $s1 i32) (local $s2 i32) (local $V___L i32) (local $V___N i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $s0
  local.get $a1
  local.set $s1
  local.get $a2
  local.set $s2
  local.get $s0
  call $rt_unicode_characters_to_list
  call $rt_pending
  br_if $raise
  local.set $s0
  (block $L4
  (block $L3
  local.get $s0
  local.set $V___L
  br $L4
  )
  local.get $s0
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s0
  drop
  local.get $V___L
  call $rt_erlang_length
  call $rt_pending
  br_if $raise
  local.set $s0
  (block $L6
  (block $L5
  local.get $s0
  local.set $V___N
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
  i64.const 0
  call $rt_int
  call $rt_cmp
  i32.const 0
  i32.lt_s
  call $rt_bool
  local.set $s0
  (block $L7 (result i32)
  (block $L8
  local.get $s0
  global.get $__lit
  i32.const 144
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L8
  local.get $V___N
  local.get $s1
  call $rt_add
  call $rt_pending
  br_if $raise
  i64.const 0
  call $rt_int
  call $rt_erlang_max
  call $rt_pending
  br_if $raise
  br $L7
  )
  (block $L9
  local.get $s0
  global.get $__lit
  i32.const 160
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L9
  local.get $s1
  local.get $V___N
  call $rt_erlang_min
  call $rt_pending
  br_if $raise
  br $L7
  )
  local.get $s0
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s0
  (block $L11
  (block $L10
  local.get $s0
  local.set $s1
  br $L11
  )
  local.get $s0
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s0
  drop
  local.get $s2
  i64.const 0
  call $rt_int
  call $rt_cmp
  i32.const 0
  i32.lt_s
  call $rt_bool
  local.set $s0
  (block $L12 (result i32)
  (block $L13
  local.get $s0
  global.get $__lit
  i32.const 144
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L13
  local.get $V___N
  local.get $s2
  call $rt_add
  call $rt_pending
  br_if $raise
  i64.const 0
  call $rt_int
  call $rt_erlang_max
  call $rt_pending
  br_if $raise
  br $L12
  )
  (block $L14
  local.get $s0
  global.get $__lit
  i32.const 160
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L14
  local.get $s2
  local.get $V___N
  call $rt_erlang_min
  call $rt_pending
  br_if $raise
  br $L12
  )
  local.get $s0
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s0
  (block $L16
  (block $L15
  local.get $s0
  local.set $s2
  br $L16
  )
  local.get $s0
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s0
  drop
  local.get $V___L
  local.get $s1
  i64.const 1
  call $rt_int
  call $rt_add
  call $rt_pending
  br_if $raise
  local.get $s2
  local.get $s1
  call $rt_sub
  call $rt_pending
  br_if $raise
  i64.const 0
  call $rt_int
  call $rt_erlang_max
  call $rt_pending
  br_if $raise
  call $rt_lists_sublist3
  call $rt_pending
  br_if $raise
  call $rt_unicode_characters_to_binary
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

(func $fun5:string_slice/3 (param $self i32) (param $a0 i32) (param $a1 i32) (result i32)
  (local $s0 i32) (local $s1 i32) (local $V___L i32) (local $V___N i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $s0
  local.get $a1
  local.set $s1
  local.get $s0
  call $rt_unicode_characters_to_list
  call $rt_pending
  br_if $raise
  local.set $s0
  (block $L4
  (block $L3
  local.get $s0
  local.set $V___L
  br $L4
  )
  local.get $s0
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s0
  drop
  local.get $V___L
  call $rt_erlang_length
  call $rt_pending
  br_if $raise
  local.set $s0
  (block $L6
  (block $L5
  local.get $s0
  local.set $V___N
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
  i64.const 0
  call $rt_int
  call $rt_cmp
  i32.const 0
  i32.lt_s
  call $rt_bool
  local.set $s0
  (block $L7 (result i32)
  (block $L8
  local.get $s0
  global.get $__lit
  i32.const 144
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L8
  local.get $V___N
  local.get $s1
  call $rt_add
  call $rt_pending
  br_if $raise
  i64.const 0
  call $rt_int
  call $rt_erlang_max
  call $rt_pending
  br_if $raise
  br $L7
  )
  (block $L9
  local.get $s0
  global.get $__lit
  i32.const 160
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L9
  local.get $s1
  local.get $V___N
  call $rt_erlang_min
  call $rt_pending
  br_if $raise
  br $L7
  )
  local.get $s0
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s0
  (block $L11
  (block $L10
  local.get $s0
  local.set $s1
  br $L11
  )
  local.get $s0
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s0
  drop
  local.get $s1
  local.get $V___L
  call $rt_lists_nthtail
  call $rt_pending
  br_if $raise
  call $rt_unicode_characters_to_binary
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

;; main/1 argument — an external term, not part of the module:
;; Arg0 = #{
;;     kind => 'Type',
;;     name => <<"User">>,
;;     fields => [
;;         #{name => <<"name">>, typeName => <<"string">>, annotations => []},
;;         #{name => <<"secret">>, typeName => <<"string">>, annotations => []},
;;         #{name => <<"age">>, typeName => <<"i32">>, annotations => []}
;;     ],
;;     variants => [],
;;     methods => [],
;;     returnType => <<"">>,
;;     annotations => [#{name => <<"describe">>, args => [], decorator => <<"main@@describe">>}],
;;     hooks => [],
;;     params => []
;; }
```

----- COMPTIME REPLY -- decorator describe
```json
{
  "contributions": [
    {
      "kind": "emit",
      "source": "pub fn describeUser() -> string { return \"NAME_SECRET_AGE:hidden:Use:four\"; }"
    }
  ],
  "kind": "ok"
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([describeUser/0]).

%% behavior String

%% behavior Array

array_range(Start, Stop) ->
    case (Start >= Stop) of
        true ->
            [];
        false ->
            Head = Start,
            [Head] ++ (array_range((Start + 1), Stop))
    end.

array_repeat(Value, Times) ->
    case (Times =< 0) of
        true ->
            [];
        false ->
            Head = Value,
            [Head] ++ (array_repeat(Value, (Times - 1)))
    end.

%% type User: name, secret, age

main() ->
    '__bp_print'([describeUser()]).

describeUser() ->
    <<"NAME_SECRET_AGE:hidden:Use:four">>.

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

----- ERLANG -- test@main@@User.erl
```erlang
-module(test@main@@User).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> erlang:element(2, V);
'__bp_get'(V, secret) -> erlang:element(3, V);
'__bp_get'(V, age) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "User", [{"name", erlang:element(2, V)}, {"secret", erlang:element(3, V)}, {"age", erlang:element(4, V)}]}.
```

----- RUN LOG -----
```logs
NAME_SECRET_AGE:hidden:Use:four
```
