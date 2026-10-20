----- SOURCE CODE -- main.bp
```botopink
pub fn describe(syntax decl: unknown) -> void {
    val names = compiler.fields(decl).map({ f -> f.name });
    val upper = names.map({ n -> n.toUpper() }).join("_");
    val hidden = if (names.contains("secret")) { "hidden"; } else { "open"; };
    val short = compiler.name(decl)!.slice(0, 3);
    val size = if (compiler.name(decl)!.length() == 4) { "four"; } else { "other"; };
    @emit("pub fn describe" + compiler.name(decl)! + "() -> string { return \"" + upper + ":" + hidden + ":" + short + ":" + size + "\"; }");
}

#[describe]
type User(name: string, secret: string, age: i32)

fn main() -> void {
    print(describeUser());
}
import {compiler} from "std";

import {io.terminal.print} from "std";
```

----- COMPTIME WAT -- decorator describe
```wat
(func $describe/1 (param $a0 i32) (result i32)
  (local $s0 i32) (local $s1 i32) (local $s2 i32) (local $s3 i32) (local $s4 i32) (local $s5 i32) (local $s6 i32) (local $V___BpF11 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $s0
  i32.const 2
  call $rt_tuple
  local.set $s1
  local.get $s1
  i32.const 0
  global.get $__lit
  i32.const 160
  i32.add
  i32.const 6
  call $rt_atom
  local.get $s0
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  call $rt_nil
  local.set $s2
  global.get $__tbase
  i32.const 0
  i32.add
  i32.const 1
  local.get $s2
  call $rt_make_fun
  call $rt_tset
  drop
  local.get $s1
  local.set $s1
  (block $L3 (result i32)
  (block $L4
  local.get $s1
  call $rt_tuple_arity
  i32.const 2
  i32.ne
  br_if $L4
  local.get $s1
  i32.const 0
  call $rt_elem
  local.set $s2
  local.get $s2
  local.set $s2
  local.get $s1
  i32.const 1
  call $rt_elem
  local.set $s3
  local.get $s3
  local.set $s3
  (block $L5 (result i32)
  (block $L6
  local.get $s2
  local.get $s3
  call $__bp_prim_map/2
  call $rt_pending
  br_if $L6
  br $L5
  )
  call $rt_class
  local.set $s2
  call $rt_reason
  local.set $s3
  call $rt_clear
  (block $L7 (result i32)
  (block $L8
  local.get $s2
  global.get $__lit
  i32.const 144
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L8
  local.get $s3
  local.set $s4
  global.get $__lit
  i32.const 176
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 2
  call $rt_int
  i64.const 33
  call $rt_int
  local.get $s4
  call $bp_comptime_decorator:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 144
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s4
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L7
  )
  local.get $s2
  local.get $s3
  call $rt_raise
  drop
  br $raise
  )
  br $L5
  )
  br $L3
  )
  local.get $s1
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s1
  (block $L10
  (block $L9
  local.get $s1
  local.set $s2
  br $L10
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  i32.const 2
  call $rt_tuple
  local.set $s1
  local.get $s1
  i32.const 0
  i32.const 2
  call $rt_tuple
  local.set $s3
  local.get $s3
  i32.const 0
  local.get $s2
  call $rt_tset
  drop
  local.get $s3
  i32.const 1
  call $rt_nil
  local.set $s4
  global.get $__tbase
  i32.const 1
  i32.add
  i32.const 1
  local.get $s4
  call $rt_make_fun
  call $rt_tset
  drop
  local.get $s3
  local.set $s3
  (block $L11 (result i32)
  (block $L12
  local.get $s3
  call $rt_tuple_arity
  i32.const 2
  i32.ne
  br_if $L12
  local.get $s3
  i32.const 0
  call $rt_elem
  local.set $s4
  local.get $s4
  local.set $s4
  local.get $s3
  i32.const 1
  call $rt_elem
  local.set $s5
  local.get $s5
  local.set $s5
  (block $L13 (result i32)
  (block $L14
  local.get $s4
  local.get $s5
  call $__bp_prim_map/2
  call $rt_pending
  br_if $L14
  br $L13
  )
  call $rt_class
  local.set $s4
  call $rt_reason
  local.set $s5
  call $rt_clear
  (block $L15 (result i32)
  (block $L16
  local.get $s4
  global.get $__lit
  i32.const 144
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L16
  local.get $s5
  local.set $s6
  global.get $__lit
  i32.const 176
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 3
  call $rt_int
  i64.const 17
  call $rt_int
  local.get $s6
  call $bp_comptime_decorator:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 144
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s6
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L15
  )
  local.get $s4
  local.get $s5
  call $rt_raise
  drop
  br $raise
  )
  br $L13
  )
  br $L11
  )
  local.get $s3
  call $rt_case_clause
  drop
  br $raise
  )
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  global.get $__lit
  i32.const 184
  i32.add
  i32.const 1
  call $rt_bin
  call $rt_tset
  drop
  local.get $s1
  local.set $s1
  (block $L17 (result i32)
  (block $L18
  local.get $s1
  call $rt_tuple_arity
  i32.const 2
  i32.ne
  br_if $L18
  local.get $s1
  i32.const 0
  call $rt_elem
  local.set $s3
  local.get $s3
  local.set $s3
  local.get $s1
  i32.const 1
  call $rt_elem
  local.set $s4
  local.get $s4
  local.set $s4
  (block $L19 (result i32)
  (block $L20
  local.get $s3
  local.get $s4
  call $__bp_prim_join/2
  call $rt_pending
  br_if $L20
  br $L19
  )
  call $rt_class
  local.set $s3
  call $rt_reason
  local.set $s4
  call $rt_clear
  (block $L21 (result i32)
  (block $L22
  local.get $s3
  global.get $__lit
  i32.const 144
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L22
  local.get $s4
  local.set $s5
  global.get $__lit
  i32.const 176
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 3
  call $rt_int
  i64.const 17
  call $rt_int
  local.get $s5
  call $bp_comptime_decorator:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 144
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s5
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L21
  )
  local.get $s3
  local.get $s4
  call $rt_raise
  drop
  br $raise
  )
  br $L19
  )
  br $L17
  )
  local.get $s1
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s1
  (block $L24
  (block $L23
  local.get $s1
  local.set $s3
  br $L24
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  (block $L25 (result i32)
  (block $L26
  local.get $s2
  global.get $__lit
  i32.const 192
  i32.add
  i32.const 6
  call $rt_bin
  call $__bp_prim_contains/2
  call $rt_pending
  br_if $L26
  br $L25
  )
  call $rt_class
  local.set $s1
  call $rt_reason
  local.set $s2
  call $rt_clear
  (block $L27 (result i32)
  (block $L28
  local.get $s1
  global.get $__lit
  i32.const 144
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L28
  local.get $s2
  local.set $s4
  global.get $__lit
  i32.const 176
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 4
  call $rt_int
  i64.const 22
  call $rt_int
  local.get $s4
  call $bp_comptime_decorator:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 144
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s4
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L27
  )
  local.get $s1
  local.get $s2
  call $rt_raise
  drop
  br $raise
  )
  br $L25
  )
  local.set $s1
  (block $L29 (result i32)
  (block $L30
  local.get $s1
  global.get $__lit
  i32.const 200
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L30
  global.get $__lit
  i32.const 208
  i32.add
  i32.const 6
  call $rt_bin
  br $L29
  )
  (block $L31
  local.get $s1
  global.get $__lit
  i32.const 216
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L31
  global.get $__lit
  i32.const 224
  i32.add
  i32.const 4
  call $rt_bin
  br $L29
  )
  local.get $s1
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s1
  (block $L33
  (block $L32
  local.get $s1
  local.set $s2
  br $L33
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  i32.const 3
  call $rt_tuple
  local.set $s1
  local.get $s1
  i32.const 0
  global.get $__lit
  i32.const 168
  i32.add
  i32.const 4
  call $rt_atom
  local.get $s0
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  i64.const 0
  call $rt_int
  call $rt_tset
  drop
  local.get $s1
  i32.const 2
  i64.const 3
  call $rt_int
  call $rt_tset
  drop
  local.get $s1
  local.set $s1
  (block $L34 (result i32)
  (block $L35
  local.get $s1
  call $rt_tuple_arity
  i32.const 3
  i32.ne
  br_if $L35
  local.get $s1
  i32.const 0
  call $rt_elem
  local.set $s4
  local.get $s4
  local.set $s4
  local.get $s1
  i32.const 1
  call $rt_elem
  local.set $s5
  local.get $s5
  local.set $s5
  local.get $s1
  i32.const 2
  call $rt_elem
  local.set $s6
  local.get $s6
  local.set $s6
  (block $L36 (result i32)
  (block $L37
  local.get $s4
  local.get $s5
  local.get $s6
  call $__bp_prim_slice/3
  call $rt_pending
  br_if $L37
  br $L36
  )
  call $rt_class
  local.set $s4
  call $rt_reason
  local.set $s5
  call $rt_clear
  (block $L38 (result i32)
  (block $L39
  local.get $s4
  global.get $__lit
  i32.const 144
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L39
  local.get $s5
  local.set $s6
  global.get $__lit
  i32.const 176
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 5
  call $rt_int
  i64.const 31
  call $rt_int
  local.get $s6
  call $bp_comptime_decorator:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 144
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s6
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L38
  )
  local.get $s4
  local.get $s5
  call $rt_raise
  drop
  br $raise
  )
  br $L36
  )
  br $L34
  )
  local.get $s1
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s1
  (block $L41
  (block $L40
  local.get $s1
  local.set $s4
  br $L41
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  i32.const 1
  call $rt_tuple
  local.set $s1
  local.get $s1
  i32.const 0
  global.get $__lit
  i32.const 168
  i32.add
  i32.const 4
  call $rt_atom
  local.get $s0
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $rt_tset
  drop
  local.get $s1
  local.set $s1
  (block $L42 (result i32)
  (block $L43
  local.get $s1
  call $rt_tuple_arity
  i32.const 1
  i32.ne
  br_if $L43
  local.get $s1
  i32.const 0
  call $rt_elem
  local.set $s5
  local.get $s5
  local.set $s5
  (block $L44 (result i32)
  (block $L45
  local.get $s5
  call $__bp_prim_length/1
  call $rt_pending
  br_if $L45
  br $L44
  )
  call $rt_class
  local.set $s5
  call $rt_reason
  local.set $s6
  call $rt_clear
  (block $L46 (result i32)
  (block $L47
  local.get $s5
  global.get $__lit
  i32.const 144
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L47
  local.get $s6
  local.set $V___BpF11
  global.get $__lit
  i32.const 176
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 6
  call $rt_int
  i64.const 34
  call $rt_int
  local.get $V___BpF11
  call $bp_comptime_decorator:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 144
  i32.add
  i32.const 5
  call $rt_atom
  local.get $V___BpF11
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L46
  )
  local.get $s5
  local.get $s6
  call $rt_raise
  drop
  br $raise
  )
  br $L44
  )
  br $L42
  )
  local.get $s1
  call $rt_case_clause
  drop
  br $raise
  )
  i64.const 4
  call $rt_int
  call $rt_eqx
  call $rt_bool
  local.set $s1
  (block $L48 (result i32)
  (block $L49
  local.get $s1
  global.get $__lit
  i32.const 200
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L49
  global.get $__lit
  i32.const 232
  i32.add
  i32.const 4
  call $rt_bin
  br $L48
  )
  (block $L50
  local.get $s1
  global.get $__lit
  i32.const 216
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L50
  global.get $__lit
  i32.const 240
  i32.add
  i32.const 5
  call $rt_bin
  br $L48
  )
  local.get $s1
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s1
  (block $L52
  (block $L51
  local.get $s1
  local.set $s5
  br $L52
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  i32.const 1
  call $rt_tuple
  local.set $s1
  local.get $s1
  i32.const 0
  global.get $__lit
  i32.const 248
  i32.add
  i32.const 15
  call $rt_bin
  global.get $__lit
  i32.const 168
  i32.add
  i32.const 4
  call $rt_atom
  local.get $s0
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 264
  i32.add
  i32.const 23
  call $rt_bin
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  local.get $s3
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 288
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  local.get $s2
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 288
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  local.get $s4
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 288
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  local.get $s5
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 4
  call $rt_bin
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  call $rt_tset
  drop
  local.get $s1
  local.set $s0
  (block $L53 (result i32)
  (block $L54
  local.get $s0
  call $rt_tuple_arity
  i32.const 1
  i32.ne
  br_if $L54
  local.get $s0
  i32.const 0
  call $rt_elem
  local.set $s1
  local.get $s1
  local.set $s1
  (block $L55 (result i32)
  (block $L56
  local.get $s1
  call $bp_comptime_decorator:emit/1
  call $rt_pending
  br_if $L56
  br $L55
  )
  call $rt_class
  local.set $s1
  call $rt_reason
  local.set $s2
  call $rt_clear
  (block $L57 (result i32)
  (block $L58
  local.get $s1
  global.get $__lit
  i32.const 144
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L58
  local.get $s2
  local.set $s3
  global.get $__lit
  i32.const 176
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 7
  call $rt_int
  i64.const 5
  call $rt_int
  local.get $s3
  call $bp_comptime_decorator:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 144
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s3
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L57
  )
  local.get $s1
  local.get $s2
  call $rt_raise
  drop
  br $raise
  )
  br $L55
  )
  br $L53
  )
  local.get $s0
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

(func $fun1:describe/1 (param $self i32) (param $a0 i32) (result i32)
  (local $V_F i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_F
  global.get $__lit
  i32.const 168
  i32.add
  i32.const 4
  call $rt_atom
  local.get $V_F
  call $rt_maps_get
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

(func $fun2:describe/1 (param $self i32) (param $a0 i32) (result i32)
  (local $s0 i32) (local $t2 i32) (local $V___BpF2 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $s0
  (block $L3 (result i32)
  (block $L4
  local.get $s0
  call $__bp_prim_toUpper/1
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
  i32.const 144
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L6
  local.get $t2
  local.set $V___BpF2
  global.get $__lit
  i32.const 176
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 3
  call $rt_int
  i64.const 34
  call $rt_int
  local.get $V___BpF2
  call $bp_comptime_decorator:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 144
  i32.add
  i32.const 5
  call $rt_atom
  local.get $V___BpF2
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

(func $__bp_prim_map/2 (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_Recv i32) (local $s1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Recv
  local.get $a1
  local.set $s1
  (block $L3
  (block $L4
  (block $L5
  local.get $V_Recv
  call $rt_erlang_is_list
  call $rt_pending
  br_if $L5
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L4
  br $L3
  )
  call $rt_clear
  )
  br $L2
  )
  local.get $s1
  local.get $V_Recv
  call $rt_lists_map
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L6
  local.get $a0
  local.set $V_Recv
  i32.const 4
  call $rt_tuple
  local.set $s1
  local.get $s1
  i32.const 0
  global.get $__lit
  i32.const 328
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  global.get $__lit
  i32.const 352
  i32.add
  i32.const 3
  call $rt_bin
  call $rt_tset
  drop
  local.get $s1
  i32.const 2
  i64.const 1
  call $rt_int
  call $rt_tset
  drop
  local.get $s1
  i32.const 3
  local.get $V_Recv
  call $rt_tset
  drop
  local.get $s1
  call $rt_error
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

(func $__bp_prim_toUpper/1 (param $a0 i32) (result i32)
  (local $V_Recv i32) (local $t1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Recv
  (block $L3
  (block $L4
  (block $L5
  local.get $V_Recv
  call $rt_erlang_is_binary
  call $rt_pending
  br_if $L5
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L4
  br $L3
  )
  call $rt_clear
  )
  br $L2
  )
  local.get $V_Recv
  call $rt_string_uppercase
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L6
  local.get $a0
  local.set $V_Recv
  i32.const 4
  call $rt_tuple
  local.set $t1
  local.get $t1
  i32.const 0
  global.get $__lit
  i32.const 328
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $t1
  i32.const 1
  global.get $__lit
  i32.const 360
  i32.add
  i32.const 7
  call $rt_bin
  call $rt_tset
  drop
  local.get $t1
  i32.const 2
  i64.const 0
  call $rt_int
  call $rt_tset
  drop
  local.get $t1
  i32.const 3
  local.get $V_Recv
  call $rt_tset
  drop
  local.get $t1
  call $rt_error
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

(func $__bp_prim_join/2 (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_Recv i32) (local $s1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Recv
  local.get $a1
  local.set $s1
  (block $L3
  (block $L4
  (block $L5
  local.get $V_Recv
  call $rt_erlang_is_list
  call $rt_pending
  br_if $L5
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L4
  br $L3
  )
  call $rt_clear
  )
  br $L2
  )
  local.get $s1
  call $rt_nil
  local.set $s1
  global.get $__tbase
  i32.const 2
  i32.add
  i32.const 1
  local.get $s1
  call $rt_make_fun
  local.get $V_Recv
  call $rt_lists_map
  call $rt_pending
  br_if $raise
  call $rt_lists_join
  call $rt_pending
  br_if $raise
  call $rt_erlang_iolist_to_binary
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L6
  local.get $a0
  local.set $V_Recv
  i32.const 4
  call $rt_tuple
  local.set $s1
  local.get $s1
  i32.const 0
  global.get $__lit
  i32.const 328
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  global.get $__lit
  i32.const 368
  i32.add
  i32.const 4
  call $rt_bin
  call $rt_tset
  drop
  local.get $s1
  i32.const 2
  i64.const 1
  call $rt_int
  call $rt_tset
  drop
  local.get $s1
  i32.const 3
  local.get $V_Recv
  call $rt_tset
  drop
  local.get $s1
  call $rt_error
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

(func $fun3:__bp_prim_join/2 (param $self i32) (param $a0 i32) (result i32)
  (local $s0 i32) (local $s1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $s0
  (block $L3 (result i32)
  (block $L4
  (block $L5
  (block $L6
  (block $L7
  local.get $s0
  call $rt_erlang_is_binary
  call $rt_pending
  br_if $L7
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L6
  br $L5
  )
  call $rt_clear
  )
  br $L4
  )
  local.get $s0
  br $L3
  )
  (block $L8
  (block $L9
  (block $L10
  (block $L11
  local.get $s0
  call $rt_erlang_is_integer
  call $rt_pending
  br_if $L11
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L10
  br $L9
  )
  call $rt_clear
  )
  br $L8
  )
  local.get $s0
  call $rt_erlang_integer_to_binary
  call $rt_pending
  br_if $raise
  br $L3
  )
  (block $L12
  (block $L13
  (block $L14
  (block $L15
  local.get $s0
  call $rt_erlang_is_list
  call $rt_pending
  br_if $L15
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L14
  br $L13
  )
  call $rt_clear
  )
  br $L12
  )
  local.get $s0
  br $L3
  )
  (block $L16
  (block $L17
  (block $L18
  (block $L19
  global.get $__lit
  i32.const 200
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L18
  br $L17
  )
  call $rt_clear
  )
  br $L16
  )
  call $rt_nil
  local.set $s1
  i64.const 112
  call $rt_int
  local.get $s1
  call $rt_cons
  local.set $s1
  i64.const 126
  call $rt_int
  local.get $s1
  call $rt_cons
  local.get $s0
  local.set $s0
  call $rt_nil
  local.set $s1
  local.get $s0
  local.get $s1
  call $rt_cons
  call $rt_io_lib_format
  call $rt_pending
  br_if $raise
  call $rt_erlang_iolist_to_binary
  call $rt_pending
  br_if $raise
  br $L3
  )
  call $rt_if_clause
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

(func $__bp_prim_contains/2 (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_Recv i32) (local $s1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Recv
  local.get $a1
  local.set $s1
  (block $L3
  (block $L4
  (block $L5
  local.get $V_Recv
  call $rt_erlang_is_list
  call $rt_pending
  br_if $L5
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L4
  br $L3
  )
  call $rt_clear
  )
  br $L2
  )
  local.get $s1
  local.get $V_Recv
  call $rt_lists_member
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L6
  local.get $a0
  local.set $V_Recv
  local.get $a1
  local.set $s1
  (block $L7
  (block $L8
  (block $L9
  local.get $V_Recv
  call $rt_erlang_is_binary
  call $rt_pending
  br_if $L9
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L8
  br $L7
  )
  call $rt_clear
  )
  br $L6
  )
  local.get $V_Recv
  local.get $s1
  call $rt_string_find
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 376
  i32.add
  i32.const 7
  call $rt_atom
  call $rt_eqx
  i32.eqz
  call $rt_bool
  br $L1
  )
  (block $L10
  local.get $a0
  local.set $V_Recv
  i32.const 4
  call $rt_tuple
  local.set $s1
  local.get $s1
  i32.const 0
  global.get $__lit
  i32.const 328
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  global.get $__lit
  i32.const 384
  i32.add
  i32.const 8
  call $rt_bin
  call $rt_tset
  drop
  local.get $s1
  i32.const 2
  i64.const 1
  call $rt_int
  call $rt_tset
  drop
  local.get $s1
  i32.const 3
  local.get $V_Recv
  call $rt_tset
  drop
  local.get $s1
  call $rt_error
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

(func $__bp_prim_slice/3 (param $a0 i32) (param $a1 i32) (param $a2 i32) (result i32)
  (local $V_Recv i32) (local $s1 i32) (local $V_Arg1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Recv
  local.get $a1
  local.set $s1
  local.get $a2
  local.set $V_Arg1
  (block $L3
  (block $L4
  (block $L5
  local.get $V_Recv
  call $rt_erlang_is_list
  call $rt_pending
  br_if $L5
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L4
  br $L3
  )
  call $rt_clear
  )
  br $L2
  )
  local.get $V_Recv
  local.get $s1
  local.get $V_Arg1
  call $array_slice/3
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L6
  local.get $a0
  local.set $V_Recv
  local.get $a1
  local.set $s1
  local.get $a2
  local.set $V_Arg1
  (block $L7
  (block $L8
  (block $L9
  local.get $V_Recv
  call $rt_erlang_is_binary
  call $rt_pending
  br_if $L9
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L8
  br $L7
  )
  call $rt_clear
  )
  br $L6
  )
  local.get $V_Recv
  local.get $s1
  local.get $V_Arg1
  call $string_slice/3
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L10
  local.get $a0
  local.set $V_Recv
  i32.const 4
  call $rt_tuple
  local.set $s1
  local.get $s1
  i32.const 0
  global.get $__lit
  i32.const 328
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  global.get $__lit
  i32.const 392
  i32.add
  i32.const 5
  call $rt_bin
  call $rt_tset
  drop
  local.get $s1
  i32.const 2
  i64.const 2
  call $rt_int
  call $rt_tset
  drop
  local.get $s1
  i32.const 3
  local.get $V_Recv
  call $rt_tset
  drop
  local.get $s1
  call $rt_error
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

(func $__bp_prim_length/1 (param $a0 i32) (result i32)
  (local $V_Recv i32) (local $t1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Recv
  (block $L3
  (block $L4
  (block $L5
  local.get $V_Recv
  call $rt_erlang_is_list
  call $rt_pending
  br_if $L5
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L4
  br $L3
  )
  call $rt_clear
  )
  br $L2
  )
  local.get $V_Recv
  call $rt_erlang_length
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L6
  local.get $a0
  local.set $V_Recv
  (block $L7
  (block $L8
  (block $L9
  local.get $V_Recv
  call $rt_erlang_is_binary
  call $rt_pending
  br_if $L9
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L8
  br $L7
  )
  call $rt_clear
  )
  br $L6
  )
  local.get $V_Recv
  call $rt_unicode_characters_to_list
  call $rt_pending
  br_if $raise
  call $rt_erlang_length
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L10
  local.get $a0
  local.set $V_Recv
  i32.const 4
  call $rt_tuple
  local.set $t1
  local.get $t1
  i32.const 0
  global.get $__lit
  i32.const 328
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $t1
  i32.const 1
  global.get $__lit
  i32.const 400
  i32.add
  i32.const 6
  call $rt_bin
  call $rt_tset
  drop
  local.get $t1
  i32.const 2
  i64.const 0
  call $rt_int
  call $rt_tset
  drop
  local.get $t1
  i32.const 3
  local.get $V_Recv
  call $rt_tset
  drop
  local.get $t1
  call $rt_error
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

(func $array_slice/3 (param $a0 i32) (param $a1 i32) (param $a2 i32) (result i32)
  (local $V_Self i32) (local $V_Start i32) (local $V_End i32) (local $t1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Self
  local.get $a1
  local.set $V_Start
  local.get $a2
  local.set $V_End
  local.get $V_End
  global.get $__lit
  i32.const 32
  i32.add
  i32.const 9
  call $rt_atom
  call $rt_eqx
  i32.eqz
  call $rt_bool
  local.set $t1
  (block $L3 (result i32)
  (block $L4
  local.get $t1
  global.get $__lit
  i32.const 200
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L4
  local.get $V_Self
  local.get $V_Start
  i64.const 1
  call $rt_int
  call $rt_add
  call $rt_pending
  br_if $raise
  local.get $V_End
  local.get $V_Start
  call $rt_sub
  call $rt_pending
  br_if $raise
  call $rt_lists_sublist3
  call $rt_pending
  br_if $raise
  br $L3
  )
  (block $L5
  local.get $t1
  global.get $__lit
  i32.const 216
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L5
  local.get $V_Start
  local.get $V_Self
  call $rt_lists_nthtail
  call $rt_pending
  br_if $raise
  br $L3
  )
  local.get $t1
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

(func $string_slice/3 (param $a0 i32) (param $a1 i32) (param $a2 i32) (result i32)
  (local $s0 i32) (local $s1 i32) (local $s2 i32) (local $t1 i32) (local $s4 i32) (local $t4 i32) (local $t5 i32) (local $t7 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $s0
  local.get $a1
  local.set $s1
  local.get $a2
  local.set $s2
  local.get $s2
  global.get $__lit
  i32.const 32
  i32.add
  i32.const 9
  call $rt_atom
  call $rt_eqx
  i32.eqz
  call $rt_bool
  local.set $t1
  (block $L3 (result i32)
  (block $L4
  local.get $t1
  global.get $__lit
  i32.const 200
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L4
  call $rt_nil
  local.set $s4
  global.get $__tbase
  i32.const 3
  i32.add
  i32.const 3
  local.get $s4
  call $rt_make_fun
  local.set $s4
  local.get $s0
  local.set $t4
  local.get $s1
  local.set $t5
  local.get $s2
  local.set $s2
  local.get $s4
  i32.const 3
  call $rt_nil
  call $rt_fun_index
  call $rt_pending
  br_if $raise
  local.set $t7
  local.get $s4
  local.get $t4
  local.get $t5
  local.get $s2
  local.get $t7
  call_indirect (param i32 i32 i32 i32) (result i32)
  call $rt_pending
  br_if $raise
  br $L3
  )
  (block $L5
  local.get $t1
  global.get $__lit
  i32.const 216
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L5
  call $rt_nil
  local.set $s2
  global.get $__tbase
  i32.const 4
  i32.add
  i32.const 2
  local.get $s2
  call $rt_make_fun
  local.set $s2
  local.get $s0
  local.set $s0
  local.get $s1
  local.set $s1
  local.get $s2
  i32.const 2
  call $rt_nil
  call $rt_fun_index
  call $rt_pending
  br_if $raise
  local.set $s4
  local.get $s2
  local.get $s0
  local.get $s1
  local.get $s4
  call_indirect (param i32 i32 i32) (result i32)
  call $rt_pending
  br_if $raise
  br $L3
  )
  local.get $t1
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

(func $fun4:string_slice/3 (param $self i32) (param $a0 i32) (param $a1 i32) (param $a2 i32) (result i32)
  (local $s0 i32) (local $s1 i32) (local $s2 i32) (local $V___L i32) (local $V___N i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $s0
  local.get $a1
  local.set $s1
  local.get $a2
  local.set $s2
  local.get $s0
  call $rt_unicode_characters_to_list
  call $rt_pending
  br_if $raise
  local.set $s0
  (block $L4
  (block $L3
  local.get $s0
  local.set $V___L
  br $L4
  )
  local.get $s0
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s0
  drop
  local.get $V___L
  call $rt_erlang_length
  call $rt_pending
  br_if $raise
  local.set $s0
  (block $L6
  (block $L5
  local.get $s0
  local.set $V___N
  br $L6
  )
  local.get $s0
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s0
  drop
  local.get $s1
  i64.const 0
  call $rt_int
  call $rt_cmp
  i32.const 0
  i32.lt_s
  call $rt_bool
  local.set $s0
  (block $L7 (result i32)
  (block $L8
  local.get $s0
  global.get $__lit
  i32.const 200
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L8
  local.get $V___N
  local.get $s1
  call $rt_add
  call $rt_pending
  br_if $raise
  i64.const 0
  call $rt_int
  call $rt_erlang_max
  call $rt_pending
  br_if $raise
  br $L7
  )
  (block $L9
  local.get $s0
  global.get $__lit
  i32.const 216
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L9
  local.get $s1
  local.get $V___N
  call $rt_erlang_min
  call $rt_pending
  br_if $raise
  br $L7
  )
  local.get $s0
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s0
  (block $L11
  (block $L10
  local.get $s0
  local.set $s1
  br $L11
  )
  local.get $s0
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s0
  drop
  local.get $s2
  i64.const 0
  call $rt_int
  call $rt_cmp
  i32.const 0
  i32.lt_s
  call $rt_bool
  local.set $s0
  (block $L12 (result i32)
  (block $L13
  local.get $s0
  global.get $__lit
  i32.const 200
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L13
  local.get $V___N
  local.get $s2
  call $rt_add
  call $rt_pending
  br_if $raise
  i64.const 0
  call $rt_int
  call $rt_erlang_max
  call $rt_pending
  br_if $raise
  br $L12
  )
  (block $L14
  local.get $s0
  global.get $__lit
  i32.const 216
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L14
  local.get $s2
  local.get $V___N
  call $rt_erlang_min
  call $rt_pending
  br_if $raise
  br $L12
  )
  local.get $s0
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s0
  (block $L16
  (block $L15
  local.get $s0
  local.set $s2
  br $L16
  )
  local.get $s0
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s0
  drop
  local.get $V___L
  local.get $s1
  i64.const 1
  call $rt_int
  call $rt_add
  call $rt_pending
  br_if $raise
  local.get $s2
  local.get $s1
  call $rt_sub
  call $rt_pending
  br_if $raise
  i64.const 0
  call $rt_int
  call $rt_erlang_max
  call $rt_pending
  br_if $raise
  call $rt_lists_sublist3
  call $rt_pending
  br_if $raise
  call $rt_unicode_characters_to_binary
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

(func $fun5:string_slice/3 (param $self i32) (param $a0 i32) (param $a1 i32) (result i32)
  (local $s0 i32) (local $s1 i32) (local $V___L i32) (local $V___N i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $s0
  local.get $a1
  local.set $s1
  local.get $s0
  call $rt_unicode_characters_to_list
  call $rt_pending
  br_if $raise
  local.set $s0
  (block $L4
  (block $L3
  local.get $s0
  local.set $V___L
  br $L4
  )
  local.get $s0
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s0
  drop
  local.get $V___L
  call $rt_erlang_length
  call $rt_pending
  br_if $raise
  local.set $s0
  (block $L6
  (block $L5
  local.get $s0
  local.set $V___N
  br $L6
  )
  local.get $s0
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s0
  drop
  local.get $s1
  i64.const 0
  call $rt_int
  call $rt_cmp
  i32.const 0
  i32.lt_s
  call $rt_bool
  local.set $s0
  (block $L7 (result i32)
  (block $L8
  local.get $s0
  global.get $__lit
  i32.const 200
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L8
  local.get $V___N
  local.get $s1
  call $rt_add
  call $rt_pending
  br_if $raise
  i64.const 0
  call $rt_int
  call $rt_erlang_max
  call $rt_pending
  br_if $raise
  br $L7
  )
  (block $L9
  local.get $s0
  global.get $__lit
  i32.const 216
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L9
  local.get $s1
  local.get $V___N
  call $rt_erlang_min
  call $rt_pending
  br_if $raise
  br $L7
  )
  local.get $s0
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s0
  (block $L11
  (block $L10
  local.get $s0
  local.set $s1
  br $L11
  )
  local.get $s0
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s0
  drop
  local.get $s1
  local.get $V___L
  call $rt_lists_nthtail
  call $rt_pending
  br_if $raise
  call $rt_unicode_characters_to_binary
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
;;     kind => 'Type',
;;     name => <<"User">>,
;;     fields => [
;;         #{name => <<"name">>, typeName => <<"string">>, annotations => []},
;;         #{name => <<"secret">>, typeName => <<"string">>, annotations => []},
;;         #{name => <<"age">>, typeName => <<"i32">>, annotations => []}
;;     ],
;;     variants => [],
;;     methods => [],
;;     returnType => <<"">>,
;;     annotations => [#{name => <<"describe">>, args => [], decorator => <<"main@@describe">>}],
;;     hooks => [],
;;     params => [],
;;     component => undefined,
;;     module => <<"">>,
;;     owner => undefined,
;;     package => <<"">>
;; }
```

----- COMPTIME REPLY -- decorator describe
```json
{
  "contributions": [
    {
      "kind": "emit",
      "source": "pub fn describeUser() -> string { return \"NAME_SECRET_AGE:hidden:Use:four\"; }"
    }
  ],
  "kind": "ok"
}
```

----- JAVASCRIPT -- main.js
```javascript
const __bp_surrogate = /[\uD800-\uDFFF]/;
const __bp_surrogate_k = new Array(64).fill("");
const __bp_surrogate_v = new Array(64).fill(false);
const __bp_surrogate_k2 = new Array(64).fill("");
const __bp_surrogate_v2 = new Array(64).fill(false);
function __bp_has_surrogate(s) {
    const h = s.length & 63;
    if (__bp_surrogate_k[h] === s) { return __bp_surrogate_v[h]; }
    if (__bp_surrogate_k2[h] === s) { return __bp_surrogate_v2[h]; }
    const p = __bp_surrogate.test(s);
    __bp_surrogate_k2[h] = __bp_surrogate_k[h];
    __bp_surrogate_v2[h] = __bp_surrogate_v[h];
    __bp_surrogate_k[h] = s;
    __bp_surrogate_v[h] = p;
    return p;
}

function __bp_str_count(s, u) {
    let n = 0;
    for (const c of s.substring(0, u)) { n += 1; }
    return n;
}

function __bp_str_index_of(s, sub) {
    const u = s.indexOf(sub);
    return (u <= 0 || !__bp_has_surrogate(s)) ? u : __bp_str_count(s, u);
}

function __bp_array_at(xs, i) { return xs.at(i) ?? null; }

function __bp_eq(a, b, d) {
    if (Object.is(a, b)) {
        return true;
    }
    if ((((((d > 32) || (a === null)) || (b === null)) || (typeof a !== "object")) || (a.constructor !== b.constructor))) {
        return false;
    }
    if (Array.isArray(a)) {
        return ((a.length === b.length) && a.every((e, i) => __bp_eq(e, b[i], (d + 1))));
    }
    const k = Object.keys(a);
    return ((k.length === Object.keys(b).length) && k.every((n) => __bp_eq(a[n], b[n], (d + 1))));
}

function __bp_f64(v) {
    if (Number.isNaN(v)) { return "NaN"; }
    if (!Number.isFinite(v)) { return (v < 0) ? "-Infinity" : "Infinity"; }
    if (v === 0) { return Object.is(v, -0) ? "-0.0" : "0.0"; }
    const t = Math.abs(v).toExponential();
    const i = t.indexOf("e");
    const d = t.slice(0, i).replace(".", "");
    const e = Number(t.slice(i + 1));
    const g = (v < 0) ? "-" : "";
    const x = g + d[0] + "." + ((d.length > 1) ? d.slice(1) : "0") + "e" + e;
    const p = e + 1;
    const f = g + ((p <= 0) ? "0." + "0".repeat(-p) + d : (p >= d.length) ? d + "0".repeat(p - d.length) + ".0" : d.slice(0, p) + "." + d.slice(p));
    return ((f.length <= x.length) && (Math.abs(v) < 9007199254740992)) ? f : x;
}

function __bp_show(v, s, top, a) {
    if ((typeof v === "string")) {
        a.push(top ? v : (("\"" + Array.from(v, (c) => ((c === "\"") || (c === "\\")) ? ("\\" + c) : (c === "\n") ? "\\n" : (c === "\r") ? "\\r" : (c === "\t") ? "\\t" : c).join("")) + "\""));
        return "%s";
    }
    if ((typeof v === "bigint")) {
        a.push(String(v));
        return "%s";
    }
    if (((typeof v === "number") && (s === "f"))) {
        a.push(__bp_f64(v));
        return "%s";
    }
    if (Array.isArray(v)) {
        const t = ((s != null) && (s[0] === "#"));
        return (((t ? "#(" : "[") + v.map((e, i) => __bp_show(e, (s == null) ? null : t ? s[i + 1] : s[1], false, a)).join(", ")) + (t ? ")" : "]"));
    }
    if ((((typeof v === "object") && (v != null)) && (typeof v.__bp !== "string"))) {
        const k = Object.keys(v);
        if (((k.length === 1) && ((k[0] === "ok") || (k[0] === "error")))) {
            return ((((k[0] === "ok") ? "Ok(" : "Error(") + __bp_show(v[k[0]], null, false, a)) + ")");
        }
    }
    if (((v != null) && (typeof v.__bp === "string"))) {
        if ((typeof v.display === "function")) {
            a.push(v.display());
            return "%s";
        }
        const k = Object.keys(v);
        return (((typeof Object.getPrototypeOf(v).tag === "string") ? ((v.__bp + ".") + Object.getPrototypeOf(v).tag) : v.__bp) + ((k.length === 0) ? "" : (("(" + k.map((n) => ((n + ": ") + __bp_show(v[n], v.__bp_s?.[n], false, a))).join(", ")) + ")")));
    }
    if ((v === undefined)) return "null";
    a.push(v);
    return "%O";
}

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

// behavior String
//   fn length(...)
//   fn split(...)
//   fn toUpper(...)
//   fn toLower(...)
//   fn contains(...)
//   fn startsWith(...)
//   fn endsWith(...)
//   fn trim(...)
//   fn trimStart(...)
//   fn trimEnd(...)
//   fn replace(...)
//   default fn slice(...)
//   fn at(...)
//   fn indexOf(...)
//   default fn toString(...)
//   fn fromCodepoint(...)
//   fn padStart(...)
//   fn padEnd(...)
//   fn repeat(...)
//   fn replaceAll(...)
//   fn chars(...)
//   fn lines(...)
//   fn words(...)
//   fn normalizeNewlines(...)
//   fn trimTrailingNewlines(...)
//   fn firstDifferingLine(...)
//   fn charCodeAt(...)
//   fn lastIndexOf(...)
//   default fn parseInt(...)
//   default fn parseFloat(...)
String.prototype.slice = function(start, end) {
    const self = this.valueOf();
    if ((end != null)) { return ((__s, __a, __e) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); const __g = __e < 0 ? Math.max(__m + __e, 0) : Math.min(__e, __m); return Array.from({ length: Math.max(__g - __d, 0) }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return __s.substring(__b, Math.max(__b, __f)); })(self, start, end); } else { return ((__s, __a) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); return Array.from({ length: __m - __d }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return __s.substring(__b); })(self, start); }
};
String.prototype.chars = function() { return (Array.from(this.valueOf())); };
String.prototype.lines = function() { return this.valueOf().split(/\r?\n/); };
String.prototype.words = function() { return this.valueOf().split(/[ \t\n\r]+/).filter(__w => __w.length > 0); };
String.prototype.normalizeNewlines = function() { return this.valueOf().replaceAll("\r\n", "\n"); };
String.prototype.trimTrailingNewlines = function() { return this.valueOf().replace(/\n+$/, ""); };
String.prototype.firstDifferingLine = function(other) { return ((__a, __b) => { const __x = __a.split("\n"), __y = __b.split("\n"); let __i = 0; while (__i < __x.length && __i < __y.length && __x[__i] === __y[__i]) __i++; return (__i === __x.length && __i === __y.length) ? 0 : __i + 1 })(this.valueOf(), other); };
String.prototype.charCodeAt = function(index) { return ((__s, __i) => { if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = __i >= 0 ? Array.from(__s)[__i] : undefined; return __c === undefined ? -1 : __c.codePointAt(0); } return (__s.codePointAt(__i) ?? -1) | 0; })(this.valueOf(), index); };
String.prototype.parseInt = function() {
    const self = this.valueOf();
    const signed = (self.startsWith("-") || self.startsWith("+"));
    const digits = (() => { if (signed) { return ((__s, __a) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); return Array.from({ length: __m - __d }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return __s.substring(__b); })(self, 1); } else { return self; } })();
    return (() => { if ((/^[0-9]+$/.test(digits))) { return ((__s) => { const __n = BigInt(__s); return (__n >= -9223372036854775808n && __n <= 9223372036854775807n) ? { ok: (__n >= -9007199254740991n && __n <= 9007199254740991n) ? Number(__n) : __n } : { error: 'parseInt: "' + __s + '" is out of range' } })(self); } else { return ({ error: 'parseInt: "' + self + '" is not an integer' }); } })();
};
String.prototype.parseFloat = function() {
    const self = this.valueOf();
    const signed = (self.startsWith("-") || self.startsWith("+"));
    const start = (() => { if (signed) { return 1; } else { return 0; } })();
    const lowerAt = __bp_str_index_of(self, "e");
    const exponentAt = (() => { if ((lowerAt < 0)) { return __bp_str_index_of(self, "E"); } else { return lowerAt; } })();
    const mantissa = (() => { if ((exponentAt < 0)) { return ((__s, __a) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); return Array.from({ length: __m - __d }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return __s.substring(__b); })(self, start); } else { return ((__s, __a, __e) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); const __g = __e < 0 ? Math.max(__m + __e, 0) : Math.min(__e, __m); return Array.from({ length: Math.max(__g - __d, 0) }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return __s.substring(__b, Math.max(__b, __f)); })(self, start, exponentAt); } })();
    const pointAt = __bp_str_index_of(self, ".");
    const pointed = ((pointAt >= 0) && (((exponentAt < 0) || (pointAt < exponentAt))));
    const whole = (() => { if (pointed) { return ((__s, __a, __e) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); const __g = __e < 0 ? Math.max(__m + __e, 0) : Math.min(__e, __m); return Array.from({ length: Math.max(__g - __d, 0) }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return __s.substring(__b, Math.max(__b, __f)); })(self, start, pointAt); } else { return mantissa; } })();
    const fraction = (() => { if ((pointed === false)) { return "0"; } else { return (() => { if ((exponentAt < 0)) { return ((__s, __a) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); return Array.from({ length: __m - __d }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return __s.substring(__b); })(self, (pointAt + 1)); } else { return ((__s, __a, __e) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); const __g = __e < 0 ? Math.max(__m + __e, 0) : Math.min(__e, __m); return Array.from({ length: Math.max(__g - __d, 0) }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return __s.substring(__b, Math.max(__b, __f)); })(self, (pointAt + 1), exponentAt); } })(); } })();
    const exponent = (() => { if ((exponentAt < 0)) { return "0"; } else { return ((__s, __a) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); return Array.from({ length: __m - __d }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return __s.substring(__b); })(self, (exponentAt + 1)); } })();
    const exponentMark = (() => { if ((exponentAt < 0)) { return ""; } else { return ((__s, __a, __e) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); const __g = __e < 0 ? Math.max(__m + __e, 0) : Math.min(__e, __m); return Array.from({ length: Math.max(__g - __d, 0) }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return __s.substring(__b, Math.max(__b, __f)); })(self, (exponentAt + 1), (exponentAt + 2)); } })();
    const exponentSigned = ((exponentMark === "-") || (exponentMark === "+"));
    const exponentDigits = (() => { if (exponentSigned) { return ((__s, __a) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); return Array.from({ length: __m - __d }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return __s.substring(__b); })(self, (exponentAt + 2)); } else { return exponent; } })();
    const wellFormed = (((/^[0-9]+$/.test(whole)) && (/^[0-9]+$/.test(fraction))) && (/^[0-9]+$/.test(exponentDigits)));
    return (() => { if (wellFormed) { return ((__t, __w, __f, __x) => { const __n = Number((__t.startsWith('-') ? '-' : '') + __w + '.' + __f + 'e' + __x); return Number.isFinite(__n) ? { ok: __n } : { error: 'parseFloat: "' + __t + '" overflows f64' } })(self, whole, fraction, exponent); } else { return ({ error: 'parseFloat: "' + self + '" is not a number' }); } })();
};

// behavior Array
//   length: i32
//   fn at(...)
//   fn push(...)
//   fn pop(...)
//   default fn slice(...)
//   fn join(...)
//   fn reverse(...)
//   fn indexOf(...)
//   default fn lastIndexOf(...)
//   fn forEach(...)
//   fn map(...)
//   fn filter(...)
//   fn zip(...)
//   fn range(...)
//   fn repeat(...)
//   default fn isEmpty(...)
//   default fn contains(...)
//   default fn first(...)
//   default fn rest(...)
//   default fn take(...)
//   default fn drop(...)
//   default fn fold(...)
//   default fn find(...)
//   default fn count(...)
//   default fn all(...)
//   default fn any(...)
//   default fn append(...)
//   default fn prepend(...)
//   default fn flatten(...)
//   default fn flatMap(...)
//   default fn toList(...)
//   default fn some(...)
//   default fn every(...)
//   default fn flat(...)
//   default fn findIndex(...)
//   default fn fill(...)
//   default fn chunked(...)
//   default fn sliding(...)
//   default fn unique(...)
Array.range = function(start, stop) { return ((__a, __b) => Array.from({ length: Math.max(0, __b - __a) }, (_, __i) => __a + __i))(start, stop); };
Array.repeat = function(value, times) { return ((__v, __n) => Array.from({ length: Math.max(0, __n) }, () => __v))(value, times); };
Array.prototype.slice = function(start, end) {
    if ((end != null)) { return ((__xs, __a, __e) => { const __n = __xs.length; if (__a == null) __a = 0; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return Array.from({ length: Math.max(__f - __b, 0) }, (_, __i) => __xs[__b + __i]); })(this, start, end); } else { return ((__xs, __a) => { const __n = __xs.length; if (__a == null) __a = 0; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return Array.from({ length: __n - __b }, (_, __i) => __xs[__b + __i]); })(this, start); }
};
Array.prototype.indexOf = function(item) { return this.findIndex((__e) => __bp_eq(__e, item, 0)); };
Array.prototype.lastIndexOf = function(item) { return this.findLastIndex((__e) => __bp_eq(__e, item, 0)); };
Array.prototype.zip = function(other) { return this.map((__x, __i) => [__x, (other)[__i]]).slice(0, Math.min(this.length, (other).length)); };
Array.prototype.isEmpty = function() {
    return (this.length === 0);
};
Array.prototype.contains = function(x) {
    return (this.indexOf(x) !== (-1));
};
Array.prototype.first = function() {
    return __bp_array_at(this, 0);
};
Array.prototype.rest = function() {
    return this.slice(1, this.length);
};
Array.prototype.take = function(n) {
    return this.slice(0, n);
};
Array.prototype.drop = function(n) {
    return this.slice(n, this.length);
};
Array.prototype.fold = function(initial, f) {
    let acc = initial;
    this.forEach((x) => {
    acc = f(acc, x);
});
    return acc;
};
Array.prototype.count = function(pred) {
    return this.filter(pred).length;
};
Array.prototype.all = function(pred) {
    return (this.filter(pred).length === this.length);
};
Array.prototype.any = function(pred) {
    return (this.filter(pred).length !== 0);
};
Array.prototype.prepend = function(item) {
    let out = [item];
    this.forEach((x) => {
    return out.push(x);
});
    return out;
};
Array.prototype.flatten = function() {
    let out = [];
    this.forEach((inner) => {
    out = out.concat(inner);
});
    return out;
};
Array.prototype.toList = function() {
    return this;
};
Array.prototype.some = function(pred) {
    return this.any(pred);
};
Array.prototype.every = function(pred) {
    return this.all(pred);
};
Array.prototype.flat = function() {
    return this.flatten();
};
Array.prototype.findIndex = function(pred) {
    let out = (-1);
    let i = 0;
    this.forEach((x) => {
    (() => { if ((out === (-1))) { return (() => { if (pred(x)) { return out = i; } })(); } })();
    i = (i + 1);
});
    return out;
};
Array.prototype.fill = function(value) {
    return Array.repeat(value, this.length);
};
Array.prototype.chunked = function(n) {
    let out = [];
    if ((n <= 0)) { return out; }
    const len = this.length;
    for (const k of Array.from({length: Math.max(0, (len) - (0))}, (_, __i) => (0) + __i)) {
    (() => { if ((((k % n) + 0) === 0)) { return out = out.concat([this.slice(k, (k + n))]); } })();
}
    return out;
};
Array.prototype.sliding = function(n) {
    let out = [];
    if ((n <= 0)) { return out; }
    const windows = ((this.length - n) + 1);
    if ((windows <= 0)) { return out; }
    for (const k of Array.from({length: Math.max(0, (windows) - (0))}, (_, __i) => (0) + __i)) {
    out = out.concat([this.slice(k, (k + n))]);
}
    return out;
};
Array.prototype.unique = function() {
    let out = [];
    this.forEach((x) => {
    return (() => { if ((!out.any((y) => {
    return __bp_eq(y, x, 0);
}))) { return out = out.concat([x]); } })();
});
    return out;
};

class User {
    constructor(name, secret, age) {
        this.name = name;
        this.secret = secret;
        this.age = age;
    }
}
User.prototype.__bp = "User";

function main() {
    __bp_print(describeUser());
}

function describeUser() {
    return "NAME_SECRET_AGE:hidden:Use:four";
}
exports.describeUser = describeUser;

function _botopink_main() {
    main();
}
if (require.main === module) _botopink_main();

Object.defineProperty(exports, "__bp_priv__", { value: { User, main, describeUser } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript






export declare function describeUser(): string;

```

----- RUN LOG -----
```logs
NAME_SECRET_AGE:hidden:Use:four
```
