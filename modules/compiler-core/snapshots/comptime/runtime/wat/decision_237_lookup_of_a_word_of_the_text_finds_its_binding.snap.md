----- SOURCE CODE -- main.bp
```botopink
pub type Card(
    title: string,
)
pub type Badge(
    n: i32,
)
val unrelated = 1;
pub fn ui(comptime q: @Expr<string>) -> @Expr<string> {
    val count = q.bindings().length;
    val hit = q.lookup("Badge");
    if (hit) { b ->
        return q.build("\"" + b.name + "/" + b.local + "\"");
    } else {
        return q.fail("Badge is a word of the text and in scope");
    };
}
val s = ui "<Card title=\"x\"><Badge/></Card>";
```

----- COMPTIME WAT -- template ui
```wat
(func $ui/1 (param $a0 i32) (result i32)
  (local $V_Q i32) (local $t1 i32) (local $V_Count i32) (local $t2 i32) (local $V_Hit i32) (local $t3 i32) (local $V_B i32)
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
  local.set $V_Count
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
  i32.const 232
  i32.add
  i32.const 5
  call $rt_bin
  call $bp_comptime_template:lookup/2
  call $rt_pending
  br_if $raise
  local.set $t2
  (block $L6
  (block $L5
  local.get $t2
  local.set $V_Hit
  br $L6
  )
  local.get $t2
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t2
  drop
  local.get $V_Hit
  local.set $t3
  (block $L7 (result i32)
  (block $L8
  local.get $t3
  global.get $__lit
  i32.const 240
  i32.add
  i32.const 9
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L8
  local.get $V_Q
  global.get $__lit
  i32.const 256
  i32.add
  i32.const 40
  call $rt_bin
  call $bp_comptime_template:fail/2
  call $rt_pending
  br_if $raise
  br $L7
  )
  (block $L9
  local.get $t3
  local.set $V_B
  local.get $V_Q
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 1
  call $rt_bin
  global.get $__lit
  i32.const 304
  i32.add
  i32.const 4
  call $rt_atom
  local.get $V_B
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 312
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 320
  i32.add
  i32.const 5
  call $rt_atom
  local.get $V_B
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  call $bp_comptime_template:build/2
  call $rt_pending
  br_if $raise
  br $L7
  )
  local.get $t3
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
;;     text => <<"<Card title=\\\"x\\\"><Badge/></Card>">>,
;;     parts => [
;;         #{
;;             kind => <<"Text">>,
;;             text => <<"<Card title=\\\"x\\\"><Badge/></Card>">>,
;;             span => #{start => 0, 'end' => 33, line => 1}
;;         }
;;     ],
;;     source => #{file => <<"">>, line => 17, col => 12},
;;     context => #{
;;         source => #{file => <<"">>, line => 17, col => 12},
;;         text => <<"<Card title=\\\"x\\\"><Badge/></Card>">>,
;;         multiline => false
;;     },
;;     bindings => [
;;         #{
;;             name => <<"Card">>,
;;             kind => 'Record_',
;;             identity => <<"main@@Card">>,
;;             local => <<"Card">>
;;         },
;;         #{
;;             name => <<"Badge">>,
;;             kind => 'Record_',
;;             identity => <<"main@@Badge">>,
;;             local => <<"Badge">>
;;         }
;;     ],
;;     words => [<<"Card">>, <<"title">>, <<"x">>, <<"Badge">>]
;; }
```

----- COMPTIME REPLY -- template ui
```json
{
  "kind": "code",
  "source": "\"Badge/Badge\""
}
```

