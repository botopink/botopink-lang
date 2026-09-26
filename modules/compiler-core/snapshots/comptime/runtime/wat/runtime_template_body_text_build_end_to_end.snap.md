----- SOURCE CODE -- main.bp
```botopink
pub fn shout(comptime q: @Expr<string>) -> @Expr<string> {
    val t = q.text();
    return q.build("\"" + t + "!\"");
}
val s = shout "hey";
```

----- COMPTIME WAT -- template shout
```wat
(func $shout/1 (param $a0 i32) (result i32)
  (local $V_Q i32) (local $t1 i32) (local $V_T i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Q
  local.get $V_Q
  call $bp_comptime_template:text/1
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
  local.get $V_Q
  global.get $__lit
  i32.const 224
  i32.add
  i32.const 1
  call $rt_bin
  local.get $V_T
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 232
  i32.add
  i32.const 2
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

;; main/1 argument — an external term, not part of the module:
;; Arg0 = #{
;;     '__bp_capture' => <<"q">>,
;;     text => <<"hey">>,
;;     parts => [
;;         #{
;;             kind => <<"Text">>,
;;             text => <<"hey">>,
;;             span => #{start => 0, 'end' => 3, line => 1}
;;         }
;;     ],
;;     source => #{file => <<"">>, line => 5, col => 15},
;;     context => #{
;;         source => #{file => <<"">>, line => 5, col => 15},
;;         text => <<"hey">>,
;;         multiline => false
;;     },
;;     bindings => [
;;         #{
;;             name => <<"shout">>,
;;             kind => 'Fn',
;;             identity => <<"main@@shout">>,
;;             local => <<"shout">>
;;         },
;;         #{name => <<"s">>, kind => 'Val', identity => <<"main@@s">>, local => <<"s">>}
;;     ]
;; }
```

----- COMPTIME REPLY -- template shout
```json
{
  "kind": "code",
  "source": "\"hey!\""
}
```

