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
;;         #{
;;             name => <<"shout">>,
;;             kind => 'Fn',
;;             identity => <<"main@@shout">>,
;;             local => <<"shout">>
;;         },
;;         #{name => <<"s">>, kind => 'Val', identity => <<"main@@s">>, local => <<"s">>},
;;         #{
;;             name => <<"main">>,
;;             kind => 'Fn',
;;             identity => <<"main@@main">>,
;;             local => <<"main">>
;;         }
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

----- JAVASCRIPT -- main.js
```javascript
function __bp_show(v, s, top, a) {
    if ((typeof v === "string")) {
        a.push(top ? v : (("\"" + Array.from(v, (c) => ((c === "\"") || (c === "\\")) ? ("\\" + c) : (c === "\n") ? "\\n" : (c === "\r") ? "\\r" : (c === "\t") ? "\\t" : c).join("")) + "\""));
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

// behavior String
//   fn length(...)
//   fn split(...)
//   fn toUpper(...)
//   fn toLower(...)
//   fn contains(...)
//   fn startsWith(...)
//   fn endsWith(...)
//   fn trim(...)
//   fn trimStart(...)
//   fn trimEnd(...)
//   fn replace(...)
//   default fn slice(...)
//   fn at(...)
//   fn indexOf(...)
//   default fn toString(...)
//   fn padStart(...)
//   fn padEnd(...)
//   fn repeat(...)
//   fn replaceAll(...)
//   fn chars(...)
//   fn lines(...)
//   fn words(...)
//   fn charCodeAt(...)
//   fn lastIndexOf(...)
String.prototype.slice = function(start, end) {
    const self = this.valueOf();
    if ((end != null)) { return ((__s, __a, __e) => { const __n = __s.length; if (__a == null) __a = 0; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return __s.substring(__b, Math.max(__b, __f)); })(self, start, end); } else { return ((__s, __a) => { const __n = __s.length; if (__a == null) __a = 0; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return __s.substring(__b); })(self, start); }
};
String.prototype.chars = function() { return (Array.from(this.valueOf())); };
String.prototype.lines = function() { return this.valueOf().split(/\r?\n/); };
String.prototype.words = function() { return this.valueOf().split(/[ \t\n\r]+/).filter(__w => __w.length > 0); };
String.prototype.charCodeAt = function(index) { return ((this.valueOf().codePointAt(index) ?? -1) | 0); };

// behavior Array
//   length: i32
//   fn at(...)
//   fn push(...)
//   fn pop(...)
//   default fn slice(...)
//   fn join(...)
//   fn reverse(...)
//   fn indexOf(...)
//   fn forEach(...)
//   fn map(...)
//   fn filter(...)
//   fn zip(...)
//   default fn range(...)
//   default fn repeat(...)
//   default fn isEmpty(...)
//   default fn contains(...)
//   default fn first(...)
//   default fn rest(...)
//   default fn take(...)
//   default fn drop(...)
//   default fn fold(...)
//   default fn find(...)
//   default fn count(...)
//   default fn all(...)
//   default fn any(...)
//   default fn append(...)
//   default fn prepend(...)
//   default fn flatten(...)
//   default fn flatMap(...)
//   default fn toList(...)
//   default fn some(...)
//   default fn every(...)
//   default fn flat(...)
//   default fn findIndex(...)
//   default fn fill(...)
//   default fn chunked(...)
//   default fn sliding(...)
//   default fn unique(...)
Array.range = function(start, stop) {
    return (() => { if ((start >= stop)) { return []; } else { const head = start; return [head, ...(Array.range((start + 1), stop))]; } })();
};
Array.repeat = function(value, times) {
    return (() => { if ((times <= 0)) { return []; } else { const head = value; return [head, ...(Array.repeat(value, (times - 1)))]; } })();
};
Array.prototype.slice = function(start, end) {
    if ((end != null)) { return ((__xs, __a, __e) => { const __n = __xs.length; if (__a == null) __a = 0; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return Array.from({ length: Math.max(__f - __b, 0) }, (_, __i) => __xs[__b + __i]); })(this, start, end); } else { return ((__xs, __a) => { const __n = __xs.length; if (__a == null) __a = 0; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return Array.from({ length: __n - __b }, (_, __i) => __xs[__b + __i]); })(this, start); }
};
Array.prototype.zip = function(other) { return this.map((__x, __i) => [__x, (other)[__i]]).slice(0, Math.min(this.length, (other).length)); };
Array.prototype.isEmpty = function() {
    return (this.length === 0);
};
Array.prototype.contains = function(x) {
    return (this.indexOf(x) !== (-1));
};
Array.prototype.first = function() {
    return this.at(0);
};
Array.prototype.rest = function() {
    return this.slice(1, this.length);
};
Array.prototype.take = function(n) {
    return this.slice(0, n);
};
Array.prototype.drop = function(n) {
    return this.slice(n, this.length);
};
Array.prototype.fold = function(initial, f) {
    let acc = initial;
    this.forEach((x) => {
    acc = f(acc, x);
});
    return acc;
};
Array.prototype.count = function(pred) {
    return this.filter(pred).length;
};
Array.prototype.all = function(pred) {
    return (this.filter(pred).length === this.length);
};
Array.prototype.any = function(pred) {
    return (this.filter(pred).length !== 0);
};
Array.prototype.prepend = function(item) {
    let out = [item];
    this.forEach((x) => {
    return out.push(x);
});
    return out;
};
Array.prototype.flatten = function() {
    let out = [];
    this.forEach((inner) => {
    out = out.concat(inner);
});
    return out;
};
Array.prototype.toList = function() {
    return this;
};
Array.prototype.some = function(pred) {
    return this.any(pred);
};
Array.prototype.every = function(pred) {
    return this.all(pred);
};
Array.prototype.flat = function() {
    return this.flatten();
};
Array.prototype.findIndex = function(pred) {
    let out = (-1);
    let i = 0;
    this.forEach((x) => {
    (() => { if ((out === (-1))) { return (() => { if (pred(x)) { return out = i; } })(); } })();
    i = (i + 1);
});
    return out;
};
Array.prototype.fill = function(value) {
    return Array.repeat(value, this.length);
};
Array.prototype.chunked = function(n) {
    let out = [];
    if ((n <= 0)) { return out; }
    const len = this.length;
    for (const k of Array.from({length: Math.max(0, (len) - (0))}, (_, __i) => (0) + __i)) {
    (() => { if (((k % n) === 0)) { return out = out.concat([this.slice(k, (k + n))]); } })();
}
    return out;
};
Array.prototype.sliding = function(n) {
    let out = [];
    if ((n <= 0)) { return out; }
    const windows = ((this.length - n) + 1);
    if ((windows <= 0)) { return out; }
    for (const k of Array.from({length: Math.max(0, (windows) - (0))}, (_, __i) => (0) + __i)) {
    out = out.concat([this.slice(k, (k + n))]);
}
    return out;
};
Array.prototype.unique = function() {
    let out = [];
    let first = true;
    let prev = this.at(0);
    this.forEach((x) => {
    (() => { if (first) { out = out.concat([x]); return first = false; } else { return (() => { if ((prev !== x)) { return out = out.concat([x]); } })(); } })();
    prev = x;
});
    return out;
};

const s = "END,WORLD,BIG,HELLO|hello|big world|at|contains|startsWith|indexOf";

exports.s = s;

function main() {
    __bp_print(s);
}
exports.main = main;

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
END,WORLD,BIG,HELLO|hello|big world|at|contains|startsWith|indexOf
```
