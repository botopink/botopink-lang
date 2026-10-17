----- SOURCE CODE -- main.bp
```botopink
pub fn six(expr t: string) -> i32 {
    val n = 2 + 4;
    return n;
}
val n = six @`ignored`;
```

----- COMPTIME WAT -- template six
```wat
(func $six/1 (param $a0 i32) (result i32)
  (local $s0 i32) (local $s1 i32) (local $V___BpF0 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $s0
  i64.const 2
  call $rt_int
  i64.const 4
  call $rt_int
  call $bp_comptime_template:__bp_add/2
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
  (block $L5 (result i32)
  (block $L6
  local.get $s1
  call $bp_comptime_template:expr/1
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
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L8
  local.get $s1
  local.set $V___BpF0
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 3
  call $rt_int
  i64.const 12
  call $rt_int
  local.get $V___BpF0
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $V___BpF0
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L7
  )
  local.get $s0
  local.get $s1
  call $rt_raise
  drop
  br $raise
  )
  br $L5
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
;;     '__bp_capture' => <<"t">>,
;;     text => <<"ignored">>,
;;     parts => [
;;         #{
;;             kind => <<"Text">>,
;;             text => <<"ignored">>,
;;             span => #{start => 0, 'end' => 7, line => 1}
;;         }
;;     ],
;;     source => #{file => <<"">>, line => 5, col => 13},
;;     context => #{
;;         source => #{file => <<"">>, line => 5, col => 13},
;;         text => <<"ignored">>,
;;         multiline => false
;;     },
;;     bindings => [],
;;     words => [<<"ignored">>]
;; }
```

----- COMPTIME REPLY -- template six
```json
{
  "kind": "value",
  "value": 6
}
```

