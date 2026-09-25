----- SOURCE CODE -- main.bp
```botopink
pub fn six(comptime t: @Expr<string>) -> @Expr<i32> {
    val n = 2 + 4;
    return @expr(n);
}
val n = six "ignored";
```

----- COMPTIME WAT -- template six
```wat
(func $six/1 (param $a0 i32) (result i32)
  (local $V_T i32) (local $t1 i32) (local $V_N i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_T
  i64.const 2
  call $rt_int
  i64.const 4
  call $rt_int
  call $bp_comptime_template:__bp_add/2
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
;;     bindings => [#{name => <<"six">>, kind => 'Fn'}, #{name => <<"n">>, kind => 'Val'}]
;; }
```

----- COMPTIME REPLY -- template six
```json
{
  "kind": "value",
  "value": 6
}
```

