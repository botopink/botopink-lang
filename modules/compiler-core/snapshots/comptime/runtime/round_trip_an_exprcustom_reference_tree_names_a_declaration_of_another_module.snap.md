----- SOURCE CODE -- main.bp
```botopink
import {Item} from "shapes";
pub fn dsl(syntax e: string) -> anyvalue {
    val code = compiler.build("41");
    val leaf = CustomNode(kind: "field", span: Span(7, 9, 1), label: "property", ref: compiler.lookup(e, "Item"), children: []);
    val root = CustomNode(kind: "select", span: Span(0, 6, 1), label: "keyword", ref: null, children: [leaf]);
    compiler.custom(root);
    return code;
}
val rows = dsl @`select id from Item`;

import {compiler, compiler.Span, compiler.CustomNode} from "std";
```

----- COMPTIME WAT -- template dsl
```wat
(func $dsl/1 (param $a0 i32) (result i32)
  (local $s0 i32) (local $s1 i32) (local $s2 i32) (local $s3 i32) (local $s4 i32) (local $V___BpF4 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $s0
  (block $L3 (result i32)
  (block $L4
  local.get $s0
  global.get $__lit
  i32.const 312
  i32.add
  i32.const 2
  call $rt_bin
  call $bp_comptime_template:build/2
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
  i32.const 320
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 3
  call $rt_int
  i64.const 25
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
  call $rt_map_empty
  local.set $s1
  local.get $s1
  global.get $__lit
  i32.const 32
  i32.add
  i32.const 4
  call $rt_atom
  global.get $__lit
  i32.const 328
  i32.add
  i32.const 5
  call $rt_bin
  call $rt_map_put
  local.set $s1
  local.get $s1
  global.get $__lit
  i32.const 64
  i32.add
  i32.const 4
  call $rt_atom
  (block $L11 (result i32)
  (block $L12
  call $rt_map_empty
  local.set $s1
  local.get $s1
  global.get $__lit
  i32.const 336
  i32.add
  i32.const 5
  call $rt_atom
  i64.const 7
  call $rt_int
  call $rt_map_put
  local.set $s1
  local.get $s1
  global.get $__lit
  i32.const 344
  i32.add
  i32.const 3
  call $rt_atom
  i64.const 9
  call $rt_int
  call $rt_map_put
  local.set $s1
  local.get $s1
  global.get $__lit
  i32.const 352
  i32.add
  i32.const 4
  call $rt_atom
  i64.const 1
  call $rt_int
  call $rt_map_put
  br $L11
  )
  call $rt_class
  local.set $s1
  call $rt_reason
  local.set $s3
  call $rt_clear
  (block $L13 (result i32)
  (block $L14
  local.get $s1
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L14
  local.get $s3
  local.set $s4
  global.get $__lit
  i32.const 320
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 4
  call $rt_int
  i64.const 48
  call $rt_int
  local.get $s4
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $L10
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s4
  call $rt_raise
  drop
  br $L10
  call $rt_nil
  br $L13
  )
  local.get $s1
  local.get $s3
  call $rt_raise
  drop
  br $L10
  )
  br $L11
  )
  call $rt_map_put
  local.set $s1
  local.get $s1
  global.get $__lit
  i32.const 360
  i32.add
  i32.const 5
  call $rt_atom
  global.get $__lit
  i32.const 368
  i32.add
  i32.const 8
  call $rt_bin
  call $rt_map_put
  local.set $s1
  local.get $s1
  global.get $__lit
  i32.const 376
  i32.add
  i32.const 3
  call $rt_atom
  (block $L15 (result i32)
  (block $L16
  local.get $s0
  global.get $__lit
  i32.const 384
  i32.add
  i32.const 4
  call $rt_bin
  call $bp_comptime_template:lookup/2
  call $rt_pending
  br_if $L16
  br $L15
  )
  call $rt_class
  local.set $s1
  call $rt_reason
  local.set $s3
  call $rt_clear
  (block $L17 (result i32)
  (block $L18
  local.get $s1
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L18
  local.get $s3
  local.set $s4
  global.get $__lit
  i32.const 320
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 4
  call $rt_int
  i64.const 103
  call $rt_int
  local.get $s4
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $L10
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s4
  call $rt_raise
  drop
  br $L10
  call $rt_nil
  br $L17
  )
  local.get $s1
  local.get $s3
  call $rt_raise
  drop
  br $L10
  )
  br $L15
  )
  call $rt_map_put
  local.set $s1
  local.get $s1
  global.get $__lit
  i32.const 392
  i32.add
  i32.const 8
  call $rt_atom
  call $rt_nil
  call $rt_map_put
  br $L9
  )
  call $rt_class
  local.set $s1
  call $rt_reason
  local.set $s3
  call $rt_clear
  (block $L19 (result i32)
  (block $L20
  local.get $s1
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
  i32.const 320
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 4
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
  local.get $s1
  local.get $s3
  call $rt_raise
  drop
  br $raise
  )
  br $L9
  )
  local.set $s1
  (block $L22
  (block $L21
  local.get $s1
  local.set $s3
  br $L22
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  (block $L23 (result i32)
  (block $L24
  call $rt_map_empty
  local.set $s1
  local.get $s1
  global.get $__lit
  i32.const 32
  i32.add
  i32.const 4
  call $rt_atom
  global.get $__lit
  i32.const 400
  i32.add
  i32.const 6
  call $rt_bin
  call $rt_map_put
  local.set $s1
  local.get $s1
  global.get $__lit
  i32.const 64
  i32.add
  i32.const 4
  call $rt_atom
  (block $L25 (result i32)
  (block $L26
  call $rt_map_empty
  local.set $s1
  local.get $s1
  global.get $__lit
  i32.const 336
  i32.add
  i32.const 5
  call $rt_atom
  i64.const 0
  call $rt_int
  call $rt_map_put
  local.set $s1
  local.get $s1
  global.get $__lit
  i32.const 344
  i32.add
  i32.const 3
  call $rt_atom
  i64.const 6
  call $rt_int
  call $rt_map_put
  local.set $s1
  local.get $s1
  global.get $__lit
  i32.const 352
  i32.add
  i32.const 4
  call $rt_atom
  i64.const 1
  call $rt_int
  call $rt_map_put
  br $L25
  )
  call $rt_class
  local.set $s1
  call $rt_reason
  local.set $s4
  call $rt_clear
  (block $L27 (result i32)
  (block $L28
  local.get $s1
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L28
  local.get $s4
  local.set $V___BpF4
  global.get $__lit
  i32.const 320
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 5
  call $rt_int
  i64.const 49
  call $rt_int
  local.get $V___BpF4
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $L24
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $V___BpF4
  call $rt_raise
  drop
  br $L24
  call $rt_nil
  br $L27
  )
  local.get $s1
  local.get $s4
  call $rt_raise
  drop
  br $L24
  )
  br $L25
  )
  call $rt_map_put
  local.set $s1
  local.get $s1
  global.get $__lit
  i32.const 360
  i32.add
  i32.const 5
  call $rt_atom
  global.get $__lit
  i32.const 408
  i32.add
  i32.const 7
  call $rt_bin
  call $rt_map_put
  local.set $s1
  local.get $s1
  global.get $__lit
  i32.const 376
  i32.add
  i32.const 3
  call $rt_atom
  global.get $__lit
  i32.const 120
  i32.add
  i32.const 9
  call $rt_atom
  call $rt_map_put
  local.set $s1
  local.get $s1
  global.get $__lit
  i32.const 392
  i32.add
  i32.const 8
  call $rt_atom
  local.get $s3
  local.set $s1
  call $rt_nil
  local.set $s3
  local.get $s1
  local.get $s3
  call $rt_cons
  call $rt_map_put
  br $L23
  )
  call $rt_class
  local.set $s1
  call $rt_reason
  local.set $s3
  call $rt_clear
  (block $L29 (result i32)
  (block $L30
  local.get $s1
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L30
  local.get $s3
  local.set $s4
  global.get $__lit
  i32.const 320
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 5
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
  br $L29
  )
  local.get $s1
  local.get $s3
  call $rt_raise
  drop
  br $raise
  )
  br $L23
  )
  local.set $s1
  (block $L32
  (block $L31
  local.get $s1
  local.set $s3
  br $L32
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  local.get $s3
  local.set $s1
  (block $L34
  (block $L33
  local.get $s1
  local.set $s3
  br $L34
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  (block $L35 (result i32)
  (block $L36
  local.get $s0
  local.get $s3
  local.get $s2
  call $bp_comptime_template:custom/3
  call $rt_pending
  br_if $L36
  br $L35
  )
  call $rt_class
  local.set $s0
  call $rt_reason
  local.set $s1
  call $rt_clear
  (block $L37 (result i32)
  (block $L38
  local.get $s0
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L38
  local.get $s1
  local.set $s2
  global.get $__lit
  i32.const 320
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 7
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
  br $L37
  )
  local.get $s0
  local.get $s1
  call $rt_raise
  drop
  br $raise
  )
  br $L35
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
;;     '__bp_capture' => <<"e">>,
;;     text => <<"select id from Item">>,
;;     source => #{file => <<"">>, line => 9, col => 16},
;;     context => #{
;;         source => #{file => <<"">>, line => 9, col => 16},
;;         text => <<"select id from Item">>,
;;         multiline => false
;;     },
;;     bindings => [
;;         #{
;;             kind => 'Type',
;;             name => <<"Item">>,
;;             fields => [#{name => <<"id">>, typeName => <<"i32">>, annotations => []}],
;;             variants => [],
;;             methods => [],
;;             returnType => <<"">>,
;;             annotations => [],
;;             hooks => [],
;;             params => [],
;;             component => undefined,
;;             module => <<"shapes">>,
;;             owner => undefined,
;;             package => <<"">>,
;;             meta => [],
;;             identity => <<"shapes@@Item">>,
;;             local => <<"Item">>
;;         }
;;     ],
;;     words => [<<"select">>, <<"id">>, <<"from">>, <<"Item">>]
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
          "annotations": [],
          "component": null,
          "fields": [
            {
              "annotations": [],
              "name": "id",
              "typeName": "i32"
            }
          ],
          "hooks": [],
          "identity": "shapes@@Item",
          "kind": "Type",
          "local": "Item",
          "meta": [],
          "methods": [],
          "module": "shapes",
          "name": "Item",
          "owner": null,
          "package": "",
          "params": [],
          "returnType": "",
          "variants": []
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

