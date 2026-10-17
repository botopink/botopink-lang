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
        return q.build("\"" + b.name + "/" + b.module + "\"");
    } else {
        return q.fail("Badge is a word of the text and in scope");
    };
}
val s = ui "<Card title=\"x\"><Badge/></Card>";
```

----- COMPTIME WAT -- template ui
```wat
(func $ui/1 (param $a0 i32) (result i32)
  (local $s0 i32) (local $s1 i32) (local $s2 i32) (local $s3 i32) (local $s4 i32)
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
  i64.const 9
  call $rt_int
  i64.const 17
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
  global.get $__lit
  i32.const 304
  i32.add
  i32.const 6
  call $rt_atom
  call $bp_comptime_template:__bp_len/2
  call $rt_pending
  br_if $raise
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
  (block $L9 (result i32)
  (block $L10
  local.get $s0
  global.get $__lit
  i32.const 312
  i32.add
  i32.const 5
  call $rt_bin
  call $bp_comptime_template:lookup/2
  call $rt_pending
  br_if $L10
  br $L9
  )
  call $rt_class
  local.set $s1
  call $rt_reason
  local.set $s2
  call $rt_clear
  (block $L11 (result i32)
  (block $L12
  local.get $s1
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L12
  local.get $s2
  local.set $s3
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 10
  call $rt_int
  i64.const 15
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
  br $L11
  )
  local.get $s1
  local.get $s2
  call $rt_raise
  drop
  br $raise
  )
  br $L9
  )
  local.set $s1
  (block $L14
  (block $L13
  local.get $s1
  local.set $s2
  br $L14
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  local.get $s2
  local.set $s1
  (block $L15 (result i32)
  (block $L16
  local.get $s1
  global.get $__lit
  i32.const 120
  i32.add
  i32.const 9
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L16
  (block $L17 (result i32)
  (block $L18
  local.get $s0
  global.get $__lit
  i32.const 320
  i32.add
  i32.const 40
  call $rt_bin
  call $bp_comptime_template:fail/2
  call $rt_pending
  br_if $L18
  br $L17
  )
  call $rt_class
  local.set $s2
  call $rt_reason
  local.set $s3
  call $rt_clear
  (block $L19 (result i32)
  (block $L20
  local.get $s2
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L20
  local.get $s3
  local.set $s4
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 14
  call $rt_int
  i64.const 16
  call $rt_int
  local.get $s4
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s4
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L19
  )
  local.get $s2
  local.get $s3
  call $rt_raise
  drop
  br $raise
  )
  br $L17
  )
  br $L15
  )
  (block $L21
  local.get $s1
  local.set $s2
  i32.const 2
  call $rt_tuple
  local.set $s3
  local.get $s3
  i32.const 0
  local.get $s0
  call $rt_tset
  drop
  local.get $s3
  i32.const 1
  global.get $__lit
  i32.const 360
  i32.add
  i32.const 1
  call $rt_bin
  global.get $__lit
  i32.const 368
  i32.add
  i32.const 4
  call $rt_atom
  local.get $s2
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 376
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 384
  i32.add
  i32.const 6
  call $rt_atom
  local.get $s2
  call $rt_maps_get
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
  call $rt_tset
  drop
  local.get $s3
  local.set $s0
  (block $L22 (result i32)
  (block $L23
  local.get $s0
  call $rt_tuple_arity
  i32.const 2
  i32.ne
  br_if $L23
  local.get $s0
  i32.const 0
  call $rt_elem
  local.set $s2
  local.get $s2
  local.set $s2
  local.get $s0
  i32.const 1
  call $rt_elem
  local.set $s3
  local.get $s3
  local.set $s3
  (block $L24 (result i32)
  (block $L25
  local.get $s2
  local.get $s3
  call $bp_comptime_template:build/2
  call $rt_pending
  br_if $L25
  br $L24
  )
  call $rt_class
  local.set $s2
  call $rt_reason
  local.set $s3
  call $rt_clear
  (block $L26 (result i32)
  (block $L27
  local.get $s2
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L27
  local.get $s3
  local.set $s4
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 12
  call $rt_int
  i64.const 16
  call $rt_int
  local.get $s4
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s4
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L26
  )
  local.get $s2
  local.get $s3
  call $rt_raise
  drop
  br $raise
  )
  br $L24
  )
  br $L22
  )
  local.get $s0
  call $rt_case_clause
  drop
  br $raise
  )
  br $L15
  )
  local.get $s1
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
;;             kind => 'Type',
;;             name => <<"Card">>,
;;             fields => [#{name => <<"title">>, typeName => <<"string">>, annotations => []}],
;;             variants => [],
;;             methods => [],
;;             returnType => <<"">>,
;;             annotations => [],
;;             hooks => [],
;;             params => [],
;;             component => undefined,
;;             module => <<"">>,
;;             owner => undefined,
;;             meta => [],
;;             identity => <<"main@@Card">>,
;;             local => <<"Card">>
;;         },
;;         #{
;;             kind => 'Type',
;;             name => <<"Badge">>,
;;             fields => [#{name => <<"n">>, typeName => <<"i32">>, annotations => []}],
;;             variants => [],
;;             methods => [],
;;             returnType => <<"">>,
;;             annotations => [],
;;             hooks => [],
;;             params => [],
;;             component => undefined,
;;             module => <<"">>,
;;             owner => undefined,
;;             meta => [],
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
  "source": "\"Badge/\""
}
```

