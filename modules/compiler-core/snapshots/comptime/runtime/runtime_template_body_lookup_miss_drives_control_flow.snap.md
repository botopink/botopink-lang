----- SOURCE CODE -- main.bp
```botopink
pub type Button(
    label: string,
)
pub fn need(expr t: string) -> string {
    val hit = compiler.lookup(t, "Buttom");
    if (hit) { b ->
        return compiler.fail("should be missing", at: t);
    };
    return compiler.build("\"ok\"");
}
val r = need @`<Buttom/>`;
import {compiler} from "std";
```

----- COMPTIME WAT -- template need
```wat
(func $need/1 (param $a0 i32) (result i32)
  (local $s0 i32) (local $s1 i32) (local $s2 i32) (local $s3 i32) (local $s4 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $s0
  (block $L3 (result i32)
  (block $L4
  local.get $s0
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 6
  call $rt_bin
  call $bp_comptime_template:lookup/2
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
  i32.const 304
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 5
  call $rt_int
  i64.const 31
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
  local.get $s2
  local.set $s1
  (block $L9 (result i32)
  (block $L10
  local.get $s1
  global.get $__lit
  i32.const 120
  i32.add
  i32.const 9
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L10
  (block $L11 (result i32)
  (block $L12
  local.get $s0
  global.get $__lit
  i32.const 312
  i32.add
  i32.const 4
  call $rt_bin
  call $bp_comptime_template:build/2
  call $rt_pending
  br_if $L12
  br $L11
  )
  call $rt_class
  local.set $s2
  call $rt_reason
  local.set $s3
  call $rt_clear
  (block $L13 (result i32)
  (block $L14
  local.get $s2
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
  i32.const 304
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 9
  call $rt_int
  i64.const 21
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
  br $L13
  )
  local.get $s2
  local.get $s3
  call $rt_raise
  drop
  br $raise
  )
  br $L11
  )
  br $L9
  )
  (block $L15
  local.get $s1
  local.set $s2
  i32.const 1
  call $rt_tuple
  local.set $s2
  local.get $s2
  i32.const 0
  (block $L16 (result i32)
  (block $L17
  local.get $s0
  global.get $__lit
  i32.const 320
  i32.add
  i32.const 17
  call $rt_bin
  call $bp_comptime_template:fail/2
  call $rt_pending
  br_if $L17
  br $L16
  )
  call $rt_class
  local.set $s0
  call $rt_reason
  local.set $s3
  call $rt_clear
  (block $L18 (result i32)
  (block $L19
  local.get $s0
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L19
  local.get $s3
  local.set $s4
  global.get $__lit
  i32.const 304
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 7
  call $rt_int
  i64.const 55
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
  br $L18
  )
  local.get $s0
  local.get $s3
  call $rt_raise
  drop
  br $raise
  )
  br $L16
  )
  call $rt_tset
  drop
  local.get $s2
  local.set $s0
  (block $L20 (result i32)
  (block $L21
  local.get $s0
  call $rt_tuple_arity
  i32.const 1
  i32.ne
  br_if $L21
  local.get $s0
  i32.const 0
  call $rt_elem
  local.set $s2
  local.get $s2
  local.set $s2
  (block $L22 (result i32)
  (block $L23
  local.get $s2
  call $bp_comptime_template:expr/1
  call $rt_pending
  br_if $L23
  br $L22
  )
  call $rt_class
  local.set $s2
  call $rt_reason
  local.set $s3
  call $rt_clear
  (block $L24 (result i32)
  (block $L25
  local.get $s2
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L25
  local.get $s3
  local.set $s4
  global.get $__lit
  i32.const 304
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 7
  call $rt_int
  i64.const 25
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
  br $L24
  )
  local.get $s2
  local.get $s3
  call $rt_raise
  drop
  br $raise
  )
  br $L22
  )
  br $L20
  )
  local.get $s0
  call $rt_case_clause
  drop
  br $raise
  )
  br $L9
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
;;     '__bp_capture' => <<"t">>,
;;     text => <<"<Buttom/>">>,
;;     source => #{file => <<"">>, line => 11, col => 14},
;;     context => #{
;;         source => #{file => <<"">>, line => 11, col => 14},
;;         text => <<"<Buttom/>">>,
;;         multiline => false
;;     },
;;     bindings => [],
;;     words => [<<"Buttom">>]
;; }
```

----- COMPTIME REPLY -- template need
```json
{
  "kind": "code",
  "source": "\"ok\""
}
```

