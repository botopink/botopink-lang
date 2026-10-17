----- SOURCE CODE -- main.bp
```botopink
pub fn shout(expr q: string) -> string {
    val t = compiler.text(q);
    return compiler.build("\"" + t + "!\"");
}
val s = shout @`hey`;
```

----- COMPTIME WAT -- template shout
```wat
(func $shout/1 (param $a0 i32) (result i32)
  (local $s0 i32) (local $s1 i32) (local $s2 i32) (local $s3 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $s0
  (block $L3 (result i32)
  (block $L4
  local.get $s0
  call $bp_comptime_template:text/1
  call $rt_pending
  br_if $L4
  br $L3
  )
  call $rt_class
  local.set $s1
  call $rt_reason
  local.set $s2
  call $rt_clear
  (block $L5 (result i32)
  (block $L6
  local.get $s1
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L6
  local.get $s2
  local.set $s3
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 2
  call $rt_int
  i64.const 27
  call $rt_int
  local.get $s3
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s3
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L5
  )
  local.get $s1
  local.get $s2
  call $rt_raise
  drop
  br $raise
  )
  br $L3
  )
  local.set $s1
  (block $L8
  (block $L7
  local.get $s1
  local.set $s2
  br $L8
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  i32.const 2
  call $rt_tuple
  local.set $s1
  local.get $s1
  i32.const 0
  local.get $s0
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  global.get $__lit
  i32.const 304
  i32.add
  i32.const 1
  call $rt_bin
  local.get $s2
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 312
  i32.add
  i32.const 2
  call $rt_bin
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  call $rt_tset
  drop
  local.get $s1
  local.set $s0
  (block $L9 (result i32)
  (block $L10
  local.get $s0
  call $rt_tuple_arity
  i32.const 2
  i32.ne
  br_if $L10
  local.get $s0
  i32.const 0
  call $rt_elem
  local.set $s1
  local.get $s1
  local.set $s1
  local.get $s0
  i32.const 1
  call $rt_elem
  local.set $s2
  local.get $s2
  local.set $s2
  (block $L11 (result i32)
  (block $L12
  local.get $s1
  local.get $s2
  call $bp_comptime_template:build/2
  call $rt_pending
  br_if $L12
  br $L11
  )
  call $rt_class
  local.set $s1
  call $rt_reason
  local.set $s2
  call $rt_clear
  (block $L13 (result i32)
  (block $L14
  local.get $s1
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L14
  local.get $s2
  local.set $s3
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 3
  call $rt_int
  i64.const 21
  call $rt_int
  local.get $s3
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s3
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L13
  )
  local.get $s1
  local.get $s2
  call $rt_raise
  drop
  br $raise
  )
  br $L11
  )
  br $L9
  )
  local.get $s0
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
;;     text => <<"hey">>,
;;     source => #{file => <<"">>, line => 5, col => 15},
;;     context => #{
;;         source => #{file => <<"">>, line => 5, col => 15},
;;         text => <<"hey">>,
;;         multiline => false
;;     },
;;     bindings => [],
;;     words => [<<"hey">>]
;; }
```

----- COMPTIME REPLY -- template shout
```json
{
  "kind": "code",
  "source": "\"hey!\""
}
```

