----- SOURCE CODE -- main.bp
```botopink
import {Item} from "shapes";
pub fn dsl<T>(comptime e: @Expr<string>) -> @ExprCustom<T> {
    val code = e.build("41");
    val leaf = CustomNode(kind: "field", span: Span(7, 9, 1), label: "property", ref: e.lookup("Item"), children: []);
    val root = CustomNode(kind: "select", span: Span(0, 6, 1), label: "keyword", ref: null, children: [leaf]);
    return e.custom(root, code);
}
val rows = dsl "select id";
```

----- COMPTIME WAT -- template dsl
```wat
(func $dsl/1 (param $a0 i32) (result i32)
  (local $V_E i32) (local $t1 i32) (local $V_Code i32) (local $t2 i32) (local $t3 i32) (local $t4 i32) (local $t5 i32) (local $t6 i32) (local $t7 i32) (local $t8 i32) (local $t9 i32) (local $t10 i32) (local $V_Leaf i32) (local $t11 i32) (local $t12 i32) (local $t13 i32) (local $t14 i32) (local $t15 i32) (local $t16 i32) (local $t17 i32) (local $t18 i32) (local $t19 i32) (local $t20 i32) (local $t21 i32) (local $V_Root i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_E
  local.get $V_E
  global.get $__lit
  i32.const 224
  i32.add
  i32.const 2
  call $rt_bin
  call $bp_comptime_template:build/2
  call $rt_pending
  br_if $raise
  local.set $t1
  (block $L4
  (block $L3
  local.get $t1
  local.set $V_Code
  br $L4
  )
  local.get $t1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t1
  drop
  call $rt_map_empty
  local.set $t2
  local.get $t2
  global.get $__lit
  i32.const 32
  i32.add
  i32.const 4
  call $rt_atom
  global.get $__lit
  i32.const 232
  i32.add
  i32.const 5
  call $rt_bin
  call $rt_map_put
  local.set $t3
  local.get $t3
  global.get $__lit
  i32.const 64
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_map_empty
  local.set $t4
  local.get $t4
  global.get $__lit
  i32.const 240
  i32.add
  i32.const 5
  call $rt_atom
  i64.const 7
  call $rt_int
  call $rt_map_put
  local.set $t5
  local.get $t5
  global.get $__lit
  i32.const 248
  i32.add
  i32.const 3
  call $rt_atom
  i64.const 9
  call $rt_int
  call $rt_map_put
  local.set $t6
  local.get $t6
  global.get $__lit
  i32.const 256
  i32.add
  i32.const 4
  call $rt_atom
  i64.const 1
  call $rt_int
  call $rt_map_put
  call $rt_map_put
  local.set $t7
  local.get $t7
  global.get $__lit
  i32.const 264
  i32.add
  i32.const 5
  call $rt_atom
  global.get $__lit
  i32.const 272
  i32.add
  i32.const 8
  call $rt_bin
  call $rt_map_put
  local.set $t8
  local.get $t8
  global.get $__lit
  i32.const 280
  i32.add
  i32.const 3
  call $rt_atom
  local.get $V_E
  global.get $__lit
  i32.const 288
  i32.add
  i32.const 4
  call $rt_bin
  call $bp_comptime_template:lookup/2
  call $rt_pending
  br_if $raise
  call $rt_map_put
  local.set $t9
  local.get $t9
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 8
  call $rt_atom
  call $rt_nil
  call $rt_map_put
  local.set $t10
  (block $L6
  (block $L5
  local.get $t10
  local.set $V_Leaf
  br $L6
  )
  local.get $t10
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t10
  drop
  call $rt_map_empty
  local.set $t11
  local.get $t11
  global.get $__lit
  i32.const 32
  i32.add
  i32.const 4
  call $rt_atom
  global.get $__lit
  i32.const 304
  i32.add
  i32.const 6
  call $rt_bin
  call $rt_map_put
  local.set $t12
  local.get $t12
  global.get $__lit
  i32.const 64
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_map_empty
  local.set $t13
  local.get $t13
  global.get $__lit
  i32.const 240
  i32.add
  i32.const 5
  call $rt_atom
  i64.const 0
  call $rt_int
  call $rt_map_put
  local.set $t14
  local.get $t14
  global.get $__lit
  i32.const 248
  i32.add
  i32.const 3
  call $rt_atom
  i64.const 6
  call $rt_int
  call $rt_map_put
  local.set $t15
  local.get $t15
  global.get $__lit
  i32.const 256
  i32.add
  i32.const 4
  call $rt_atom
  i64.const 1
  call $rt_int
  call $rt_map_put
  call $rt_map_put
  local.set $t16
  local.get $t16
  global.get $__lit
  i32.const 264
  i32.add
  i32.const 5
  call $rt_atom
  global.get $__lit
  i32.const 312
  i32.add
  i32.const 7
  call $rt_bin
  call $rt_map_put
  local.set $t17
  local.get $t17
  global.get $__lit
  i32.const 280
  i32.add
  i32.const 3
  call $rt_atom
  global.get $__lit
  i32.const 320
  i32.add
  i32.const 9
  call $rt_atom
  call $rt_map_put
  local.set $t18
  local.get $t18
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 8
  call $rt_atom
  local.get $V_Leaf
  local.set $t19
  call $rt_nil
  local.set $t20
  local.get $t19
  local.get $t20
  call $rt_cons
  call $rt_map_put
  local.set $t21
  (block $L8
  (block $L7
  local.get $t21
  local.set $V_Root
  br $L8
  )
  local.get $t21
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t21
  drop
  local.get $V_E
  local.get $V_Root
  local.get $V_Code
  call $bp_comptime_template:custom/3
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
;;     '__bp_capture' => <<"e">>,
;;     text => <<"select id">>,
;;     parts => [
;;         #{
;;             kind => <<"Text">>,
;;             text => <<"select id">>,
;;             span => #{start => 0, 'end' => 9, line => 1}
;;         }
;;     ],
;;     source => #{file => <<"">>, line => 8, col => 16},
;;     context => #{
;;         source => #{file => <<"">>, line => 8, col => 16},
;;         text => <<"select id">>,
;;         multiline => false
;;     },
;;     bindings => [
;;         #{
;;             name => <<"Item">>,
;;             kind => 'Fn',
;;             identity => <<"shapes@@Item">>,
;;             local => <<"Item">>
;;         },
;;         #{
;;             name => <<"dsl">>,
;;             kind => 'Fn',
;;             identity => <<"main@@dsl">>,
;;             local => <<"dsl">>
;;         },
;;         #{
;;             name => <<"rows">>,
;;             kind => 'Val',
;;             identity => <<"main@@rows">>,
;;             local => <<"rows">>
;;         }
;;     ]
;; }
```

----- COMPTIME REPLY -- template dsl
```json
{
  "ast": {
    "children": [
      {
        "children": [],
        "kind": "field",
        "label": "property",
        "ref": {
          "identity": "shapes@@Item",
          "kind": "Fn",
          "local": "Item",
          "name": "Item"
        },
        "span": {
          "end": 9,
          "line": 1,
          "start": 7
        }
      }
    ],
    "kind": "select",
    "label": "keyword",
    "ref": null,
    "span": {
      "end": 6,
      "line": 1,
      "start": 0
    }
  },
  "kind": "custom",
  "source": "41"
}
```

