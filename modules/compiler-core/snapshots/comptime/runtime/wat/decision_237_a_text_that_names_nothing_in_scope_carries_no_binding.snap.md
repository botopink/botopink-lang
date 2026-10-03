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
  (local $V_Q i32) (local $t1 i32) (local $V_N i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Q
  local.get $V_Q
  call $bp_comptime_template:bindings/1
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 224
  i32.add
  i32.const 6
  call $rt_atom
  call $bp_comptime_template:__bp_len/2
  call $rt_pending
  br_if $raise
  local.set $t1
  (block $L4
  (block $L3
  local.get $t1
  local.set $V_N
  br $L4
  )
  local.get $t1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t1
  drop
  local.get $V_N
  call $bp_comptime_template:expr/1
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

