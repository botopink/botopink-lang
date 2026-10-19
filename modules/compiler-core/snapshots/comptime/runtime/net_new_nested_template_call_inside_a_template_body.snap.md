----- SOURCE CODE -- main.bp
```botopink
pub fn inner(syntax q: string) -> string {
    return q;
}
pub fn outer(syntax q: string) -> string {
    return compiler.build("inner @`deep`");
}
val s = outer @`x`;

import {compiler} from "std";
```

----- COMPTIME WAT -- template outer
```wat
(func $outer/1 (param $a0 i32) (result i32)
  (local $s0 i32) (local $t2 i32) (local $V___BpF0 i32)
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
  i32.const 13
  call $rt_bin
  call $bp_comptime_template:build/2
  call $rt_pending
  br_if $L4
  br $L3
  )
  call $rt_class
  local.set $s0
  call $rt_reason
  local.set $t2
  call $rt_clear
  (block $L5 (result i32)
  (block $L6
  local.get $s0
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L6
  local.get $t2
  local.set $V___BpF0
  global.get $__lit
  i32.const 328
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 5
  call $rt_int
  i64.const 21
  call $rt_int
  local.get $V___BpF0
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $V___BpF0
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L5
  )
  local.get $s0
  local.get $t2
  call $rt_raise
  drop
  br $raise
  )
  br $L3
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
;;     text => <<"x">>,
;;     source => #{file => <<"">>, line => 7, col => 15},
;;     context => #{
;;         source => #{file => <<"">>, line => 7, col => 15},
;;         text => <<"x">>,
;;         multiline => false
;;     },
;;     bindings => [],
;;     words => [<<"x">>],
;;     name => <<"x">>
;; }
```

----- COMPTIME REPLY -- template outer
```json
{
  "kind": "code",
  "source": "inner @`deep`"
}
```

