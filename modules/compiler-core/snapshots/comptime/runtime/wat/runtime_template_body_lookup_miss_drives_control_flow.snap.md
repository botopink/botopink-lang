----- SOURCE CODE -- main.bp
```botopink
pub type Button(
    label: string,
)
pub fn need(comptime t: @Expr<string>) -> @Expr<string> {
    val hit = t.lookup("Buttom");
    if (hit) { b ->
        return t.fail("should be missing");
    };
    return t.build("\"ok\"");
}
val r = need "x";
```

----- COMPTIME WAT -- template need
```wat
(func $need/1 (param $a0 i32) (result i32)
  (local $V_T i32) (local $t1 i32) (local $V_Hit i32) (local $t2 i32) (local $V_B i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_T
  local.get $V_T
  global.get $__lit
  i32.const 224
  i32.add
  i32.const 6
  call $rt_bin
  call $bp_comptime_template:lookup/2
  call $rt_pending
  br_if $raise
  local.set $t1
  (block $L4
  (block $L3
  local.get $t1
  local.set $V_Hit
  br $L4
  )
  local.get $t1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t1
  drop
  local.get $V_Hit
  local.set $t2
  (block $L5 (result i32)
  (block $L6
  local.get $t2
  global.get $__lit
  i32.const 232
  i32.add
  i32.const 9
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L6
  local.get $V_T
  global.get $__lit
  i32.const 248
  i32.add
  i32.const 4
  call $rt_bin
  call $bp_comptime_template:build/2
  call $rt_pending
  br_if $raise
  br $L5
  )
  (block $L7
  local.get $t2
  local.set $V_B
  local.get $V_T
  global.get $__lit
  i32.const 256
  i32.add
  i32.const 17
  call $rt_bin
  call $bp_comptime_template:fail/2
  call $rt_pending
  br_if $raise
  br $L5
  )
  local.get $t2
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
;;     '__bp_capture' => <<"t">>,
;;     text => <<"x">>,
;;     parts => [
;;         #{
;;             kind => <<"Text">>,
;;             text => <<"x">>,
;;             span => #{start => 0, 'end' => 1, line => 1}
;;         }
;;     ],
;;     source => #{file => <<"">>, line => 11, col => 14},
;;     context => #{
;;         source => #{file => <<"">>, line => 11, col => 14},
;;         text => <<"x">>,
;;         multiline => false
;;     },
;;     bindings => [
;;         #{name => <<"Button">>, kind => 'Record_'},
;;         #{name => <<"need">>, kind => 'Fn'},
;;         #{name => <<"r">>, kind => 'Val'}
;;     ]
;; }
```

----- COMPTIME REPLY -- template need
```json
{
  "kind": "code",
  "source": "\"ok\""
}
```

