----- SOURCE CODE -- main.bp
```botopink
pub fn inner(comptime q: @Expr<string>) -> @Expr<string> {
    return q;
}
pub fn outer(comptime q: @Expr<string>) -> @Expr<string> {
    return q.build("inner(\"deep\")");
}
val s = outer "x";
```

----- COMPTIME WAT -- template outer
```wat
(func $outer/1 (param $a0 i32) (result i32)
  (local $V_Q i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Q
  local.get $V_Q
  global.get $__lit
  i32.const 224
  i32.add
  i32.const 13
  call $rt_bin
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
;;     text => <<"x">>,
;;     parts => [
;;         #{
;;             kind => <<"Text">>,
;;             text => <<"x">>,
;;             span => #{start => 0, 'end' => 1, line => 1}
;;         }
;;     ],
;;     source => #{file => <<"">>, line => 7, col => 15},
;;     context => #{
;;         source => #{file => <<"">>, line => 7, col => 15},
;;         text => <<"x">>,
;;         multiline => false
;;     },
;;     bindings => [
;;         #{name => <<"inner">>, kind => 'Fn'},
;;         #{name => <<"outer">>, kind => 'Fn'},
;;         #{name => <<"s">>, kind => 'Val'}
;;     ]
;; }
```

----- COMPTIME REPLY -- template outer
```json
{
  "kind": "code",
  "source": "inner(\"deep\")"
}
```

