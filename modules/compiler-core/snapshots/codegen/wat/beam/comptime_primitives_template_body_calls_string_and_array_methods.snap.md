----- SOURCE CODE -- main.bp
```botopink
pub fn shout(comptime q: @Expr<string>) -> @Expr<string> {
    val t = q.text().trim();
    val words = t.split(" ").map({ w -> w.toUpper() });
    val lead = t.slice(0, 5);
    val rest = t.slice(6, t.length);
    val all = words.append(["END"]).reverse();
    val at = if (words.at(1) == "BIG") { "at"; } else { "-"; };
    val big = if (t.contains("big")) { "contains"; } else { "-"; };
    val greet = if (lead.startsWith("hel")) { "startsWith"; } else { "-"; };
    val where = if (words.indexOf("WORLD") == 2) { "indexOf"; } else { "-"; };
    return q.build("\"" + all.join(",") + "|" + lead + "|" + rest + "|" + at + "|" + big + "|" + greet + "|" + where + "\"");
}

val s = shout " hello big world ";

fn main() {
    @print(s);
}
```

----- COMPTIME WAT -- template shout
```wat
(func $shout/1 (param $a0 i32) (result i32)
  (local $V_Q i32) (local $t1 i32) (local $V_T i32) (local $t2 i32) (local $t3 i32) (local $V_Words i32) (local $t4 i32) (local $V_Lead i32) (local $t5 i32) (local $V_Rest i32) (local $t6 i32) (local $t7 i32) (local $t8 i32) (local $V_All i32) (local $t9 i32) (local $t10 i32) (local $V_At i32) (local $t11 i32) (local $t12 i32) (local $V_Big i32) (local $t13 i32) (local $t14 i32) (local $V_Greet i32) (local $t15 i32) (local $t16 i32) (local $V_Where i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Q
  local.get $V_Q
  call $bp_comptime_template:text/1
  call $rt_pending
  br_if $raise
  call $__bp_prim_trim/1
  call $rt_pending
  br_if $raise
  local.set $t1
  (block $L4
  (block $L3
  local.get $t1
  local.set $V_T
  br $L4
  )
  local.get $t1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t1
  drop
  local.get $V_T
  global.get $__lit
  i32.const 224
  i32.add
  i32.const 1
  call $rt_bin
  call $__bp_prim_split/2
  call $rt_pending
  br_if $raise
  call $rt_nil
  local.set $t2
  global.get $__tbase
  i32.const 0
  i32.add
  i32.const 1
  local.get $t2
  call $rt_make_fun
  call $__bp_prim_map/2
  call $rt_pending
  br_if $raise
  local.set $t3
  (block $L6
  (block $L5
  local.get $t3
  local.set $V_Words
  br $L6
  )
  local.get $t3
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t3
  drop
  local.get $V_T
  i64.const 0
  call $rt_int
  i64.const 5
  call $rt_int
  call $__bp_prim_slice/3
  call $rt_pending
  br_if $raise
  local.set $t4
  (block $L8
  (block $L7
  local.get $t4
  local.set $V_Lead
  br $L8
  )
  local.get $t4
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t4
  drop
  local.get $V_T
  i64.const 6
  call $rt_int
  local.get $V_T
  global.get $__lit
  i32.const 232
  i32.add
  i32.const 6
  call $rt_atom
  call $bp_comptime_template:__bp_len/2
  call $rt_pending
  br_if $raise
  call $__bp_prim_slice/3
  call $rt_pending
  br_if $raise
  local.set $t5
  (block $L10
  (block $L9
  local.get $t5
  local.set $V_Rest
  br $L10
  )
  local.get $t5
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t5
  drop
  local.get $V_Words
  global.get $__lit
  i32.const 240
  i32.add
  i32.const 3
  call $rt_bin
  local.set $t6
  call $rt_nil
  local.set $t7
  local.get $t6
  local.get $t7
  call $rt_cons
  call $__bp_prim_append/2
  call $rt_pending
  br_if $raise
  call $__bp_prim_reverse/1
  call $rt_pending
  br_if $raise
  local.set $t8
  (block $L12
  (block $L11
  local.get $t8
  local.set $V_All
  br $L12
  )
  local.get $t8
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t8
  drop
  local.get $V_Words
  i64.const 1
  call $rt_int
  call $__bp_prim_at/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 248
  i32.add
  i32.const 3
  call $rt_bin
  call $rt_eqx
  call $rt_bool
  local.set $t9
  (block $L13 (result i32)
  (block $L14
  local.get $t9
  global.get $__lit
  i32.const 256
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L14
  global.get $__lit
  i32.const 264
  i32.add
  i32.const 2
  call $rt_bin
  br $L13
  )
  (block $L15
  local.get $t9
  global.get $__lit
  i32.const 272
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L15
  global.get $__lit
  i32.const 280
  i32.add
  i32.const 1
  call $rt_bin
  br $L13
  )
  local.get $t9
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $t10
  (block $L17
  (block $L16
  local.get $t10
  local.set $V_At
  br $L17
  )
  local.get $t10
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t10
  drop
  local.get $V_T
  global.get $__lit
  i32.const 288
  i32.add
  i32.const 3
  call $rt_bin
  call $__bp_prim_contains/2
  call $rt_pending
  br_if $raise
  local.set $t11
  (block $L18 (result i32)
  (block $L19
  local.get $t11
  global.get $__lit
  i32.const 256
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L19
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 8
  call $rt_bin
  br $L18
  )
  (block $L20
  local.get $t11
  global.get $__lit
  i32.const 272
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L20
  global.get $__lit
  i32.const 280
  i32.add
  i32.const 1
  call $rt_bin
  br $L18
  )
  local.get $t11
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $t12
  (block $L22
  (block $L21
  local.get $t12
  local.set $V_Big
  br $L22
  )
  local.get $t12
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t12
  drop
  local.get $V_Lead
  global.get $__lit
  i32.const 304
  i32.add
  i32.const 3
  call $rt_bin
  call $__bp_prim_startsWith/2
  call $rt_pending
  br_if $raise
  local.set $t13
  (block $L23 (result i32)
  (block $L24
  local.get $t13
  global.get $__lit
  i32.const 256
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L24
  global.get $__lit
  i32.const 312
  i32.add
  i32.const 10
  call $rt_bin
  br $L23
  )
  (block $L25
  local.get $t13
  global.get $__lit
  i32.const 272
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L25
  global.get $__lit
  i32.const 280
  i32.add
  i32.const 1
  call $rt_bin
  br $L23
  )
  local.get $t13
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $t14
  (block $L27
  (block $L26
  local.get $t14
  local.set $V_Greet
  br $L27
  )
  local.get $t14
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t14
  drop
  local.get $V_Words
  global.get $__lit
  i32.const 328
  i32.add
  i32.const 5
  call $rt_bin
  call $__bp_prim_indexOf/2
  call $rt_pending
  br_if $raise
  i64.const 2
  call $rt_int
  call $rt_eqx
  call $rt_bool
  local.set $t15
  (block $L28 (result i32)
  (block $L29
  local.get $t15
  global.get $__lit
  i32.const 256
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L29
  global.get $__lit
  i32.const 336
  i32.add
  i32.const 7
  call $rt_bin
  br $L28
  )
  (block $L30
  local.get $t15
  global.get $__lit
  i32.const 272
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L30
  global.get $__lit
  i32.const 280
  i32.add
  i32.const 1
  call $rt_bin
  br $L28
  )
  local.get $t15
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $t16
  (block $L32
  (block $L31
  local.get $t16
  local.set $V_Where
  br $L32
  )
  local.get $t16
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t16
  drop
  local.get $V_Q
  global.get $__lit
  i32.const 344
  i32.add
  i32.const 1
  call $rt_bin
  local.get $V_All
  global.get $__lit
  i32.const 352
  i32.add
  i32.const 1
  call $rt_bin
  call $__bp_prim_join/2
  call $rt_pending
  br_if $raise
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 360
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  local.get $V_Lead
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 360
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  local.get $V_Rest
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 360
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  local.get $V_At
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 360
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  local.get $V_Big
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 360
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  local.get $V_Greet
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 360
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  local.get $V_Where
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 344
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  call $bp_comptime_template:build/2
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

(func $fun1:shout/1 (param $self i32) (param $a0 i32) (result i32)
  (local $V_W i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_W
  local.get $V_W
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

(func $__bp_prim_trim/1 (param $a0 i32) (result i32)
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
  call $rt_string_trim
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
  i32.const 408
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $t1
  i32.const 1
  global.get $__lit
  i32.const 432
  i32.add
  i32.const 4
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

(func $__bp_prim_map/2 (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_Recv i32) (local $V_Arg0 i32) (local $t1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Recv
  local.get $a1
  local.set $V_Arg0
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
  local.get $V_Arg0
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
  local.set $t1
  local.get $t1
  i32.const 0
  global.get $__lit
  i32.const 408
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $t1
  i32.const 1
  global.get $__lit
  i32.const 448
  i32.add
  i32.const 3
  call $rt_bin
  call $rt_tset
  drop
  local.get $t1
  i32.const 2
  i64.const 1
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

(func $__bp_prim_split/2 (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_Recv i32) (local $V_Arg0 i32) (local $t1 i32) (local $t2 i32) (local $t3 i32) (local $t4 i32) (local $t5 i32) (local $t6 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Recv
  local.get $a1
  local.set $V_Arg0
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
  call $rt_nil
  local.set $t1
  global.get $__tbase
  i32.const 2
  i32.add
  i32.const 2
  local.get $t1
  call $rt_make_fun
  local.set $t2
  local.get $V_Recv
  local.set $t3
  local.get $V_Arg0
  local.set $t4
  local.get $t2
  i32.const 2
  call $rt_nil
  call $rt_fun_index
  call $rt_pending
  br_if $raise
  local.set $t5
  local.get $t2
  local.get $t3
  local.get $t4
  local.get $t5
  call_indirect (param i32 i32 i32) (result i32)
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L6
  local.get $a0
  local.set $V_Recv
  i32.const 4
  call $rt_tuple
  local.set $t6
  local.get $t6
  i32.const 0
  global.get $__lit
  i32.const 408
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $t6
  i32.const 1
  global.get $__lit
  i32.const 464
  i32.add
  i32.const 5
  call $rt_bin
  call $rt_tset
  drop
  local.get $t6
  i32.const 2
  i64.const 1
  call $rt_int
  call $rt_tset
  drop
  local.get $t6
  i32.const 3
  local.get $V_Recv
  call $rt_tset
  drop
  local.get $t6
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

(func $fun3:__bp_prim_split/2 (param $self i32) (param $a0 i32) (param $a1 i32) (result i32)
  (local $V___S i32) (local $t1 i32) (local $t2 i32) (local $V___bingen2 i32) (local $t3 i32) (local $t4 i32) (local $V___C i32) (local $t5 i32) (local $V___X i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V___S
  local.get $a1
  global.get $__lit
  i32.const 456
  i32.add
  i32.const 0
  call $rt_bin_is
  i32.eqz
  br_if $L2
  call $rt_nil
  local.set $t1
  local.get $V___S
  call $rt_unicode_characters_to_list
  call $rt_pending
  br_if $raise
  local.set $t2
  local.get $t2
  local.set $V___bingen2
  local.get $V___bingen2
  local.set $t3
  (block $L3
  (loop $L4
  local.get $t3
  i32.const 12
  call $rt_is
  i32.eqz
  br_if $L3
  local.get $t3
  call $rt_hd
  local.set $t4
  local.get $t3
  call $rt_tl
  local.set $t3
  (block $L5
  local.get $t4
  local.set $V___C
  call $rt_bb_new
  local.set $t5
  local.get $t5
  local.get $V___C
  call $rt_bb_utf8
  call $rt_pending
  br_if $raise
  drop
  local.get $t5
  call $rt_bb_end
  local.get $t1
  call $rt_cons
  local.set $t1
  )
  br $L4
  )
  )
  local.get $t1
  call $rt_lists_reverse
  br $L1
  )
  (block $L6
  local.get $a0
  local.set $V___S
  local.get $a1
  local.set $V___X
  local.get $V___S
  local.get $V___X
  global.get $__lit
  i32.const 456
  i32.add
  i32.const 3
  call $rt_atom
  call $rt_string_split3
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
  i32.const 408
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $t1
  i32.const 1
  global.get $__lit
  i32.const 472
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

(func $__bp_prim_slice/3 (param $a0 i32) (param $a1 i32) (param $a2 i32) (result i32)
  (local $V_Recv i32) (local $V_Arg0 i32) (local $V_Arg1 i32) (local $t1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Recv
  local.get $a1
  local.set $V_Arg0
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
  local.get $V_Arg0
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
  local.set $V_Arg0
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
  local.get $V_Arg0
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
  local.set $t1
  local.get $t1
  i32.const 0
  global.get $__lit
  i32.const 408
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $t1
  i32.const 1
  global.get $__lit
  i32.const 480
  i32.add
  i32.const 5
  call $rt_bin
  call $rt_tset
  drop
  local.get $t1
  i32.const 2
  i64.const 2
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

(func $__bp_prim_reverse/1 (param $a0 i32) (result i32)
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
  call $rt_lists_reverse
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
  i32.const 408
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $t1
  i32.const 1
  global.get $__lit
  i32.const 488
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

(func $__bp_prim_append/2 (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_Recv i32) (local $V_Arg0 i32) (local $t1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Recv
  local.get $a1
  local.set $V_Arg0
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
  local.get $V_Arg0
  call $rt_append
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
  i32.const 408
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $t1
  i32.const 1
  global.get $__lit
  i32.const 496
  i32.add
  i32.const 6
  call $rt_bin
  call $rt_tset
  drop
  local.get $t1
  i32.const 2
  i64.const 1
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

(func $__bp_prim_at/2 (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_Recv i32) (local $V_Arg0 i32) (local $t1 i32) (local $t2 i32) (local $t3 i32) (local $t4 i32) (local $t5 i32) (local $t6 i32) (local $t7 i32) (local $t8 i32) (local $t9 i32) (local $t10 i32) (local $t11 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Recv
  local.get $a1
  local.set $V_Arg0
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
  call $rt_nil
  local.set $t1
  global.get $__tbase
  i32.const 3
  i32.add
  i32.const 2
  local.get $t1
  call $rt_make_fun
  local.set $t2
  local.get $V_Recv
  local.set $t3
  local.get $V_Arg0
  local.set $t4
  local.get $t2
  i32.const 2
  call $rt_nil
  call $rt_fun_index
  call $rt_pending
  br_if $raise
  local.set $t5
  local.get $t2
  local.get $t3
  local.get $t4
  local.get $t5
  call_indirect (param i32 i32 i32) (result i32)
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L6
  local.get $a0
  local.set $V_Recv
  local.get $a1
  local.set $V_Arg0
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
  call $rt_nil
  local.set $t6
  global.get $__tbase
  i32.const 4
  i32.add
  i32.const 2
  local.get $t6
  call $rt_make_fun
  local.set $t7
  local.get $V_Recv
  local.set $t8
  local.get $V_Arg0
  local.set $t9
  local.get $t7
  i32.const 2
  call $rt_nil
  call $rt_fun_index
  call $rt_pending
  br_if $raise
  local.set $t10
  local.get $t7
  local.get $t8
  local.get $t9
  local.get $t10
  call_indirect (param i32 i32 i32) (result i32)
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L10
  local.get $a0
  local.set $V_Recv
  i32.const 4
  call $rt_tuple
  local.set $t11
  local.get $t11
  i32.const 0
  global.get $__lit
  i32.const 408
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $t11
  i32.const 1
  global.get $__lit
  i32.const 264
  i32.add
  i32.const 2
  call $rt_bin
  call $rt_tset
  drop
  local.get $t11
  i32.const 2
  i64.const 1
  call $rt_int
  call $rt_tset
  drop
  local.get $t11
  i32.const 3
  local.get $V_Recv
  call $rt_tset
  drop
  local.get $t11
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

(func $fun4:__bp_prim_at/2 (param $self i32) (param $a0 i32) (param $a1 i32) (result i32)
  (local $V___L i32) (local $V___I i32) (local $t1 i32) (local $V___N i32) (local $t2 i32) (local $t3 i32) (local $V___J i32) (local $t4 i32) (local $t5 i32) (local $t6 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V___L
  local.get $a1
  local.set $V___I
  local.get $V___L
  call $rt_erlang_length
  call $rt_pending
  br_if $raise
  local.set $t1
  (block $L4
  (block $L3
  local.get $t1
  local.set $V___N
  br $L4
  )
  local.get $t1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t1
  drop
  local.get $V___I
  i64.const 0
  call $rt_int
  call $rt_cmp
  i32.const 0
  i32.lt_s
  call $rt_bool
  local.set $t2
  (block $L5 (result i32)
  (block $L6
  local.get $t2
  global.get $__lit
  i32.const 256
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L6
  local.get $V___I
  local.get $V___N
  call $rt_add
  call $rt_pending
  br_if $raise
  br $L5
  )
  (block $L7
  local.get $t2
  global.get $__lit
  i32.const 272
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L7
  local.get $V___I
  br $L5
  )
  local.get $t2
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $t3
  (block $L9
  (block $L8
  local.get $t3
  local.set $V___J
  br $L9
  )
  local.get $t3
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t3
  drop
  local.get $V___J
  i64.const 0
  call $rt_int
  call $rt_cmp
  i32.const 0
  i32.ge_s
  call $rt_bool
  local.set $t4
  local.get $t4
  call $rt_truth
  local.set $t5
  local.get $t5
  i32.const 2
  i32.eq
  (if
    (then
  local.get $t4
  call $rt_badarg_of
  drop
  br $raise
    )
  )
  local.get $t5
  (if (result i32)
    (then
  local.get $V___J
  local.get $V___N
  call $rt_cmp
  i32.const 0
  i32.lt_s
  call $rt_bool
    )
    (else
  global.get $__lit
  i32.const 272
  i32.add
  i32.const 5
  call $rt_atom
    )
  )
  local.set $t6
  (block $L10 (result i32)
  (block $L11
  local.get $t6
  global.get $__lit
  i32.const 256
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L11
  local.get $V___J
  i64.const 1
  call $rt_int
  call $rt_add
  call $rt_pending
  br_if $raise
  local.get $V___L
  call $rt_lists_nth
  call $rt_pending
  br_if $raise
  br $L10
  )
  (block $L12
  local.get $t6
  global.get $__lit
  i32.const 272
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L12
  global.get $__lit
  i32.const 376
  i32.add
  i32.const 9
  call $rt_atom
  br $L10
  )
  local.get $t6
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

(func $fun5:__bp_prim_at/2 (param $self i32) (param $a0 i32) (param $a1 i32) (result i32)
  (local $V___S i32) (local $V___I i32) (local $t1 i32) (local $V___N i32) (local $t2 i32) (local $t3 i32) (local $V___J i32) (local $t4 i32) (local $t5 i32) (local $t6 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V___S
  local.get $a1
  local.set $V___I
  local.get $V___S
  call $rt_string_length
  call $rt_pending
  br_if $raise
  local.set $t1
  (block $L4
  (block $L3
  local.get $t1
  local.set $V___N
  br $L4
  )
  local.get $t1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t1
  drop
  local.get $V___I
  i64.const 0
  call $rt_int
  call $rt_cmp
  i32.const 0
  i32.lt_s
  call $rt_bool
  local.set $t2
  (block $L5 (result i32)
  (block $L6
  local.get $t2
  global.get $__lit
  i32.const 256
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L6
  local.get $V___I
  local.get $V___N
  call $rt_add
  call $rt_pending
  br_if $raise
  br $L5
  )
  (block $L7
  local.get $t2
  global.get $__lit
  i32.const 272
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L7
  local.get $V___I
  br $L5
  )
  local.get $t2
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $t3
  (block $L9
  (block $L8
  local.get $t3
  local.set $V___J
  br $L9
  )
  local.get $t3
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t3
  drop
  local.get $V___J
  i64.const 0
  call $rt_int
  call $rt_cmp
  i32.const 0
  i32.ge_s
  call $rt_bool
  local.set $t4
  local.get $t4
  call $rt_truth
  local.set $t5
  local.get $t5
  i32.const 2
  i32.eq
  (if
    (then
  local.get $t4
  call $rt_badarg_of
  drop
  br $raise
    )
  )
  local.get $t5
  (if (result i32)
    (then
  local.get $V___J
  local.get $V___N
  call $rt_cmp
  i32.const 0
  i32.lt_s
  call $rt_bool
    )
    (else
  global.get $__lit
  i32.const 272
  i32.add
  i32.const 5
  call $rt_atom
    )
  )
  local.set $t6
  (block $L10 (result i32)
  (block $L11
  local.get $t6
  global.get $__lit
  i32.const 256
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L11
  local.get $V___S
  local.get $V___J
  i64.const 1
  call $rt_int
  call $rt_string_slice3
  call $rt_pending
  br_if $raise
  br $L10
  )
  (block $L12
  local.get $t6
  global.get $__lit
  i32.const 272
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L12
  global.get $__lit
  i32.const 376
  i32.add
  i32.const 9
  call $rt_atom
  br $L10
  )
  local.get $t6
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

(func $__bp_prim_contains/2 (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_Recv i32) (local $V_Arg0 i32) (local $t1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Recv
  local.get $a1
  local.set $V_Arg0
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
  local.get $V_Arg0
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
  local.set $V_Arg0
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
  local.get $V_Arg0
  call $rt_string_find
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 504
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
  local.set $t1
  local.get $t1
  i32.const 0
  global.get $__lit
  i32.const 408
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $t1
  i32.const 1
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 8
  call $rt_bin
  call $rt_tset
  drop
  local.get $t1
  i32.const 2
  i64.const 1
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

(func $__bp_prim_startsWith/2 (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_Recv i32) (local $V_Arg0 i32) (local $t1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Recv
  local.get $a1
  local.set $V_Arg0
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
  local.get $V_Arg0
  call $rt_string_prefix
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 504
  i32.add
  i32.const 7
  call $rt_atom
  call $rt_eqx
  i32.eqz
  call $rt_bool
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
  i32.const 408
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
  i32.const 10
  call $rt_bin
  call $rt_tset
  drop
  local.get $t1
  i32.const 2
  i64.const 1
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

(func $__bp_prim_indexOf/2 (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_Recv i32) (local $V_Arg0 i32) (local $t1 i32) (local $t2 i32) (local $t3 i32) (local $t4 i32) (local $t5 i32) (local $t6 i32) (local $t7 i32) (local $t8 i32) (local $t9 i32) (local $t10 i32) (local $t11 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Recv
  local.get $a1
  local.set $V_Arg0
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
  call $rt_nil
  local.set $t1
  global.get $__tbase
  i32.const 5
  i32.add
  i32.const 2
  local.get $t1
  call $rt_make_fun
  local.set $t2
  local.get $V_Recv
  local.set $t3
  local.get $V_Arg0
  local.set $t4
  local.get $t2
  i32.const 2
  call $rt_nil
  call $rt_fun_index
  call $rt_pending
  br_if $raise
  local.set $t5
  local.get $t2
  local.get $t3
  local.get $t4
  local.get $t5
  call_indirect (param i32 i32 i32) (result i32)
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L6
  local.get $a0
  local.set $V_Recv
  local.get $a1
  local.set $V_Arg0
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
  call $rt_nil
  local.set $t6
  global.get $__tbase
  i32.const 7
  i32.add
  i32.const 2
  local.get $t6
  call $rt_make_fun
  local.set $t7
  local.get $V_Recv
  local.set $t8
  local.get $V_Arg0
  local.set $t9
  local.get $t7
  i32.const 2
  call $rt_nil
  call $rt_fun_index
  call $rt_pending
  br_if $raise
  local.set $t10
  local.get $t7
  local.get $t8
  local.get $t9
  local.get $t10
  call_indirect (param i32 i32 i32) (result i32)
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L10
  local.get $a0
  local.set $V_Recv
  i32.const 4
  call $rt_tuple
  local.set $t11
  local.get $t11
  i32.const 0
  global.get $__lit
  i32.const 408
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $t11
  i32.const 1
  global.get $__lit
  i32.const 336
  i32.add
  i32.const 7
  call $rt_bin
  call $rt_tset
  drop
  local.get $t11
  i32.const 2
  i64.const 1
  call $rt_int
  call $rt_tset
  drop
  local.get $t11
  i32.const 3
  local.get $V_Recv
  call $rt_tset
  drop
  local.get $t11
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

(func $fun6:__bp_prim_indexOf/2 (param $self i32) (param $a0 i32) (param $a1 i32) (result i32)
  (local $V___L i32) (local $V___X i32) (local $t1 i32) (local $t2 i32) (local $t3 i32) (local $V___Find i32) (local $t4 i32) (local $t5 i32) (local $t6 i32) (local $t7 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V___L
  local.get $a1
  local.set $V___X
  i32.const 1
  call $rt_tuple
  local.set $t1
  local.get $t1
  i32.const 0
  local.get $V___X
  call $rt_tset
  drop
  local.get $t1
  local.set $t2
  global.get $__tbase
  i32.const 6
  i32.add
  i32.const 2
  local.get $t2
  call $rt_make_fun
  local.set $t3
  (block $L4
  (block $L3
  local.get $t3
  local.set $V___Find
  br $L4
  )
  local.get $t3
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t3
  drop
  local.get $V___Find
  local.set $t4
  i64.const 0
  call $rt_int
  local.set $t5
  local.get $V___L
  local.set $t6
  local.get $t4
  i32.const 2
  call $rt_nil
  call $rt_fun_index
  call $rt_pending
  br_if $raise
  local.set $t7
  local.get $t4
  local.get $t5
  local.get $t6
  local.get $t7
  call_indirect (param i32 i32 i32) (result i32)
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

(func $fun7:__bp_prim_indexOf/2 (param $self i32) (param $a0 i32) (param $a1 i32) (result i32)
  (local $V___X i32) (local $V___F i32) (local $V___I i32) (local $t1 i32) (local $t2 i32) (local $V___H i32) (local $V___T i32) (local $t3 i32) (local $t4 i32) (local $t5 i32) (local $t6 i32) (local $t7 i32)
  (block $raise
  local.get $self
  call $rt_fun_env
  i32.const 0
  call $rt_elem
  local.set $V___X
  local.get $self
  local.set $V___F
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V___I
  local.get $a1
  i32.const 12
  call $rt_is
  i32.eqz
  br_if $L2
  local.get $a1
  call $rt_hd
  local.set $t1
  local.get $a1
  call $rt_tl
  local.set $t2
  local.get $t1
  local.set $V___H
  local.get $t2
  local.set $V___T
  local.get $V___H
  local.get $V___X
  call $rt_eqx
  call $rt_bool
  local.set $t3
  (block $L3 (result i32)
  (block $L4
  local.get $t3
  global.get $__lit
  i32.const 256
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L4
  local.get $V___I
  br $L3
  )
  (block $L5
  local.get $t3
  global.get $__lit
  i32.const 272
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L5
  local.get $V___F
  local.set $t4
  local.get $V___I
  i64.const 1
  call $rt_int
  call $rt_add
  call $rt_pending
  br_if $raise
  local.set $t5
  local.get $V___T
  local.set $t6
  local.get $t4
  i32.const 2
  call $rt_nil
  call $rt_fun_index
  call $rt_pending
  br_if $raise
  local.set $t7
  local.get $t4
  local.get $t5
  local.get $t6
  local.get $t7
  call_indirect (param i32 i32 i32) (result i32)
  call $rt_pending
  br_if $raise
  br $L3
  )
  local.get $t3
  call $rt_case_clause
  drop
  br $raise
  )
  br $L1
  )
  (block $L6
  local.get $a1
  i32.const 11
  call $rt_is
  i32.eqz
  br_if $L6
  i64.const -1
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

(func $fun8:__bp_prim_indexOf/2 (param $self i32) (param $a0 i32) (param $a1 i32) (result i32)
  (local $V___S i32) (local $V___X i32) (local $t1 i32) (local $t2 i32) (local $t3 i32) (local $V___P i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V___S
  local.get $a1
  local.set $V___X
  local.get $V___X
  local.set $t1
  (block $L3 (result i32)
  (block $L4
  local.get $t1
  global.get $__lit
  i32.const 456
  i32.add
  i32.const 0
  call $rt_bin_is
  i32.eqz
  br_if $L4
  i64.const 0
  call $rt_int
  br $L3
  )
  (block $L5
  local.get $V___S
  local.get $V___X
  call $rt_binary_match
  call $rt_pending
  br_if $raise
  local.set $t2
  (block $L6 (result i32)
  (block $L7
  local.get $t2
  global.get $__lit
  i32.const 504
  i32.add
  i32.const 7
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L7
  i64.const -1
  call $rt_int
  br $L6
  )
  (block $L8
  local.get $t2
  call $rt_tuple_arity
  i32.const 2
  i32.ne
  br_if $L8
  local.get $t2
  i32.const 0
  call $rt_elem
  local.set $t3
  local.get $t3
  local.set $V___P
  local.get $V___P
  br $L6
  )
  local.get $t2
  call $rt_case_clause
  drop
  br $raise
  )
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

(func $__bp_prim_join/2 (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_Recv i32) (local $V_Arg0 i32) (local $t1 i32) (local $t2 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Recv
  local.get $a1
  local.set $V_Arg0
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
  local.get $V_Arg0
  call $rt_nil
  local.set $t1
  global.get $__tbase
  i32.const 8
  i32.add
  i32.const 1
  local.get $t1
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
  local.set $t2
  local.get $t2
  i32.const 0
  global.get $__lit
  i32.const 408
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $t2
  i32.const 1
  global.get $__lit
  i32.const 512
  i32.add
  i32.const 4
  call $rt_bin
  call $rt_tset
  drop
  local.get $t2
  i32.const 2
  i64.const 1
  call $rt_int
  call $rt_tset
  drop
  local.get $t2
  i32.const 3
  local.get $V_Recv
  call $rt_tset
  drop
  local.get $t2
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

(func $fun9:__bp_prim_join/2 (param $self i32) (param $a0 i32) (result i32)
  (local $V___E i32) (local $t1 i32) (local $t2 i32) (local $t3 i32) (local $t4 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V___E
  (block $L3 (result i32)
  (block $L4
  (block $L5
  (block $L6
  (block $L7
  local.get $V___E
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
  local.get $V___E
  br $L3
  )
  (block $L8
  (block $L9
  (block $L10
  (block $L11
  local.get $V___E
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
  local.get $V___E
  call $rt_erlang_integer_to_binary
  call $rt_pending
  br_if $raise
  br $L3
  )
  (block $L12
  (block $L13
  (block $L14
  (block $L15
  local.get $V___E
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
  local.get $V___E
  br $L3
  )
  (block $L16
  (block $L17
  (block $L18
  (block $L19
  global.get $__lit
  i32.const 256
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
  local.set $t1
  i64.const 112
  call $rt_int
  local.get $t1
  call $rt_cons
  local.set $t2
  i64.const 126
  call $rt_int
  local.get $t2
  call $rt_cons
  local.get $V___E
  local.set $t3
  call $rt_nil
  local.set $t4
  local.get $t3
  local.get $t4
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
  i32.const 376
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
  i32.const 256
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
  i32.const 272
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
  i32.const 376
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
  i32.const 256
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L4
  local.get $V_Self
  local.get $V_Start
  local.get $V_End
  local.get $V_Start
  call $rt_sub
  call $rt_pending
  br_if $raise
  call $rt_string_slice3
  call $rt_pending
  br_if $raise
  br $L3
  )
  (block $L5
  local.get $t1
  global.get $__lit
  i32.const 272
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L5
  local.get $V_Self
  local.get $V_Start
  call $rt_string_slice2
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

;; main/1 argument — an external term, not part of the module:
;; Arg0 = #{
;;     '__bp_capture' => <<"q">>,
;;     text => <<" hello big world ">>,
;;     parts => [
;;         #{
;;             kind => <<"Text">>,
;;             text => <<" hello big world ">>,
;;             span => #{start => 0, 'end' => 17, line => 1}
;;         }
;;     ],
;;     source => #{file => <<"">>, line => 14, col => 15},
;;     context => #{
;;         source => #{file => <<"">>, line => 14, col => 15},
;;         text => <<" hello big world ">>,
;;         multiline => false
;;     },
;;     bindings => [
;;         #{name => <<"shout">>, kind => 'Fn'},
;;         #{name => <<"s">>, kind => 'Val'},
;;         #{name => <<"main">>, kind => 'Fn'}
;;     ]
;; }
```

----- COMPTIME REPLY -- template shout
```json
{
  "kind": "code",
  "source": "\"END,WORLD,BIG,HELLO|hello|big world|at|contains|startsWith|indexOf\""
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 44}.

{function, 'Array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, 'Array_range'}, 2}.
  {label, 3}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 14}, [{y, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 15}}.
  {label, 14}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
  {label, 15}.
    {deallocate, 4}.
    return.

{function, 'Array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, 'Array_repeat'}, 2}.
  {label, 5}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 16}, [{integer, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 17}}.
  {label, 16}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
  {label, 17}.
    {deallocate, 4}.
    return.

{function, s, 0, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, s}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {move, {literal, <<"END,WORLD,BIG,HELLO|hello|big world|at|contains|startsWith|indexOf">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, main, 0, 9}.
  {label, 8}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, main}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {call, 0, {f, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 19}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 11}.
  {label, 10}.
    {line, [{location, "test@main.erl", 5}]}.
    {func_info, {atom, test@main}, {atom, '_botopink_main'}, 0}.
  {label, 11}.
    {call_only, 0, {f, 9}}.

{function, main, 1, 13}.
  {label, 12}.
    {line, [{location, "test@main.erl", 6}]}.
    {func_info, {atom, test@main}, {atom, main}, 1}.
  {label, 13}.
    {call_only, 0, {f, 11}}.

{function, '__bp_print', 1, 19}.
  {label, 18}.
    {line, [{location, "test@main.erl", 5}]}.
    {func_info, {atom, test@main}, {atom, '__bp_print'}, 1}.
  {label, 19}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 23}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 23}.
  {label, 22}.
    {line, [{location, "test@main.erl", 5}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 23}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 21}}.

{function, '-bp_show_elem-', 1, 25}.
  {label, 24}.
    {line, [{location, "test@main.erl", 5}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 25}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 21}}.

{function, '__bp_show', 2, 21}.
  {label, 20}.
    {line, [{location, "test@main.erl", 5}]}.
    {func_info, {atom, test@main}, {atom, '__bp_show'}, 2}.
  {label, 21}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 33}, [{x, 0}]}.
    {test, is_eq, {f, 32}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 32}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 33}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 34}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 25}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 34}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 36}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 35}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 35}, [{x, 0}]}.
    {test, is_ne_exact, {f, 35}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 35}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 35}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 37}}.
  {label, 35}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 25}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 36}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 38}, [{x, 0}]}.
    {test, is_ne_exact, {f, 38}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 38}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 39}, [{x, 0}, {atom, undefined}]}.
  {label, 37}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 27}, 2}.
  {label, 38}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 39}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 27}.
  {label, 26}.
    {line, [{location, "test@main.erl", 5}]}.
    {func_info, {atom, test@main}, {atom, '__bp_tagged'}, 2}.
  {label, 27}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 40}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 40}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 40}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 41}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 29}, 3}.
  {label, 41}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 29}.
  {label, 28}.
    {line, [{location, "test@main.erl", 5}]}.
    {func_info, {atom, test@main}, {atom, '__bp_render'}, 1}.
  {label, 29}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 42}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 42}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 43}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 43}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 31}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 31}.
  {label, 30}.
    {line, [{location, "test@main.erl", 5}]}.
    {func_info, {atom, test@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 31}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 21}}.
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
END,WORLD,BIG,HELLO|hello|big world|at|contains|startsWith|indexOf
```
