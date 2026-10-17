----- SOURCE CODE -- main.bp
```botopink
val cfg_1 = "unread";
pub fn conf(comptime q: @Expr<string>) -> @Expr<i32> {
    val n = q.bindings().length;
    return @expr(n);
}
val n = conf "cfg-0";
```

----- COMPTIME WAT -- template conf
```wat
(func $conf/1 (param $a0 i32) (result i32)
  (local $s0 i32) (local $s1 i32) (local $s2 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $s0
  (block $L3 (result i32)
  (block $L4
  local.get $s0
  call $bp_comptime_template:bindings/1
  call $rt_pending
  br_if $L4
  br $L3
  )
  call $rt_class
  local.set $s0
  call $rt_reason
  local.set $s1
  call $rt_clear
  (block $L5 (result i32)
  (block $L6
  local.get $s0
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L6
  local.get $s1
  local.set $s2
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 3
  call $rt_int
  i64.const 13
  call $rt_int
  local.get $s2
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s2
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L5
  )
  local.get $s0
  local.get $s1
  call $rt_raise
  drop
  br $raise
  )
  br $L3
  )
  global.get $__lit
  i32.const 304
  i32.add
  i32.const 6
  call $rt_atom
  call $bp_comptime_template:__bp_len/2
  call $rt_pending
  br_if $raise
  local.set $s0
  (block $L8
  (block $L7
  local.get $s0
  local.set $s1
  br $L8
  )
  local.get $s0
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s0
  drop
  (block $L9 (result i32)
  (block $L10
  local.get $s1
  call $bp_comptime_template:expr/1
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
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L12
  local.get $s1
  local.set $s2
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 4
  call $rt_int
  i64.const 12
  call $rt_int
  local.get $s2
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s2
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L11
  )
  local.get $s0
  local.get $s1
  call $rt_raise
  drop
  br $raise
  )
  br $L9
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
;;     text => <<"cfg-0">>,
;;     parts => [
;;         #{
;;             kind => <<"Text">>,
;;             text => <<"cfg-0">>,
;;             span => #{start => 0, 'end' => 5, line => 1}
;;         }
;;     ],
;;     source => #{file => <<"">>, line => 6, col => 14},
;;     context => #{
;;         source => #{file => <<"">>, line => 6, col => 14},
;;         text => <<"cfg-0">>,
;;         multiline => false
;;     },
;;     bindings => [],
;;     words => [<<"cfg">>]
;; }
```

----- COMPTIME REPLY -- template conf
```json
{
  "kind": "value",
  "value": 0
}
```

