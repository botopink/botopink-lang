----- SOURCE CODE -- main.bp
```botopink
pub type Point(x: i32, y: i32)
pub fn holes<T>(comptime q: @Expr<string>) -> @Expr<T> {
    var codes: Array<string> = [];
    var texts = "";
    var spans = "";
    for (q.parts()) { p ->
        if (p.kind == "Interp") { codes.push(p.code); };
        if (p.kind == "Text") { texts = texts + p.text; };
        spans = spans + p.span.start.toString() + "-" + p.span.end.toString() + ";";
    };
    return q.build("#(" + codes.join(", ") + ", \"" + texts + "\", \"" + spans + "\")");
}
val origin = Point(x: 3, y: 4);
val xs = [1, 2, 3];
val maybe: ?i32 = null;
val got = holes """p=${origin} xs=${xs} m=${maybe}""";
```

----- COMPTIME WAT -- template holes
```wat
(func $holes/1 (param $a0 i32) (result i32)
  (local $V_Q i32) (local $s1 i32) (local $s2 i32) (local $s3 i32) (local $s4 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Q
  call $rt_nil
  local.set $s1
  (block $L4
  (block $L3
  local.get $s1
  local.set $s2
  br $L4
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  global.get $__lit
  i32.const 224
  i32.add
  i32.const 0
  call $rt_bin
  local.set $s1
  (block $L6
  (block $L5
  local.get $s1
  local.set $s3
  br $L6
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  global.get $__lit
  i32.const 224
  i32.add
  i32.const 0
  call $rt_bin
  local.set $s1
  (block $L8
  (block $L7
  local.get $s1
  local.set $s4
  br $L8
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  call $rt_nil
  local.set $s1
  global.get $__tbase
  i32.const 0
  i32.add
  i32.const 2
  local.get $s1
  call $rt_make_fun
  i32.const 3
  call $rt_tuple
  local.set $s1
  local.get $s1
  i32.const 0
  local.get $s2
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  local.get $s3
  call $rt_tset
  drop
  local.get $s1
  i32.const 2
  local.get $s4
  call $rt_tset
  drop
  local.get $s1
  local.get $V_Q
  call $bp_comptime_template:parts/1
  call $rt_pending
  br_if $raise
  call $rt_lists_foldl
  call $rt_pending
  br_if $raise
  local.set $s1
  (block $L10
  (block $L9
  local.get $s1
  call $rt_tuple_arity
  i32.const 3
  i32.ne
  br_if $L9
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
  local.get $s1
  i32.const 2
  call $rt_elem
  local.set $s4
  local.get $s4
  local.set $s4
  br $L10
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  local.get $V_Q
  global.get $__lit
  i32.const 288
  i32.add
  i32.const 2
  call $rt_bin
  local.get $s2
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 2
  call $rt_bin
  call $__bp_prim_join/2
  call $rt_pending
  br_if $raise
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 304
  i32.add
  i32.const 3
  call $rt_bin
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  local.get $s3
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 312
  i32.add
  i32.const 4
  call $rt_bin
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  local.get $s4
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 320
  i32.add
  i32.const 2
  call $rt_bin
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
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

(func $fun1:holes/1 (param $self i32) (param $a0 i32) (param $a1 i32) (result i32)
  (local $s0 i32) (local $s1 i32) (local $s2 i32) (local $s3 i32) (local $s4 i32) (local $s5 i32) (local $s6 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $s0
  local.get $a1
  call $rt_tuple_arity
  i32.const 3
  i32.ne
  br_if $L2
  local.get $a1
  i32.const 0
  call $rt_elem
  local.set $s1
  local.get $s1
  local.set $s1
  local.get $a1
  i32.const 1
  call $rt_elem
  local.set $s2
  local.get $s2
  local.set $s2
  local.get $a1
  i32.const 2
  call $rt_elem
  local.set $s3
  local.get $s3
  local.set $s3
  global.get $__lit
  i32.const 32
  i32.add
  i32.const 4
  call $rt_atom
  local.get $s0
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 224
  i32.add
  i32.const 6
  call $rt_bin
  call $rt_eqx
  call $rt_bool
  local.set $s4
  (block $L3 (result i32)
  (block $L4
  local.get $s4
  global.get $__lit
  i32.const 232
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L4
  local.get $s1
  global.get $__lit
  i32.const 96
  i32.add
  i32.const 4
  call $rt_atom
  local.get $s0
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $__bp_prim_push/2
  call $rt_pending
  br_if $raise
  local.set $s5
  (block $L6
  (block $L5
  local.get $s5
  local.set $s6
  br $L6
  )
  local.get $s5
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s5
  drop
  local.get $s6
  br $L3
  )
  (block $L7
  local.get $s1
  br $L3
  )
  local.get $s4
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s1
  (block $L9
  (block $L8
  local.get $s1
  local.set $s4
  br $L9
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  global.get $__lit
  i32.const 32
  i32.add
  i32.const 4
  call $rt_atom
  local.get $s0
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 240
  i32.add
  i32.const 4
  call $rt_bin
  call $rt_eqx
  call $rt_bool
  local.set $s1
  (block $L10 (result i32)
  (block $L11
  local.get $s1
  global.get $__lit
  i32.const 232
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L11
  local.get $s2
  global.get $__lit
  i32.const 248
  i32.add
  i32.const 4
  call $rt_atom
  local.get $s0
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  local.set $s5
  (block $L13
  (block $L12
  local.get $s5
  local.set $s6
  br $L13
  )
  local.get $s5
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s5
  drop
  local.get $s6
  br $L10
  )
  (block $L14
  local.get $s2
  br $L10
  )
  local.get $s1
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s1
  (block $L16
  (block $L15
  local.get $s1
  local.set $s2
  br $L16
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  local.get $s3
  global.get $__lit
  i32.const 256
  i32.add
  i32.const 5
  call $rt_atom
  global.get $__lit
  i32.const 64
  i32.add
  i32.const 4
  call $rt_atom
  local.get $s0
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $__bp_prim_toString/1
  call $rt_pending
  br_if $raise
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 264
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 272
  i32.add
  i32.const 3
  call $rt_atom
  global.get $__lit
  i32.const 64
  i32.add
  i32.const 4
  call $rt_atom
  local.get $s0
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $__bp_prim_toString/1
  call $rt_pending
  br_if $raise
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 280
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  local.set $s0
  (block $L18
  (block $L17
  local.get $s0
  local.set $s1
  br $L18
  )
  local.get $s0
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s0
  drop
  i32.const 3
  call $rt_tuple
  local.set $s0
  local.get $s0
  i32.const 0
  local.get $s4
  call $rt_tset
  drop
  local.get $s0
  i32.const 1
  local.get $s2
  call $rt_tset
  drop
  local.get $s0
  i32.const 2
  local.get $s1
  call $rt_tset
  drop
  local.get $s0
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

(func $__bp_prim_push/2 (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_Recv i32) (local $s1 i32) (local $t2 i32)
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
  local.get $V_Recv
  local.get $s1
  local.set $s1
  call $rt_nil
  local.set $t2
  local.get $s1
  local.get $t2
  call $rt_cons
  call $rt_append
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
  i32.const 368
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

(func $__bp_prim_toString/1 (param $a0 i32) (result i32)
  (local $V_Recv i32) (local $t1 i32) (local $t2 i32)
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
  call $string_toString/1
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
  call $rt_erlang_is_boolean
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
  call $rt_erlang_atom_to_binary
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L10
  local.get $a0
  local.set $V_Recv
  (block $L11
  (block $L12
  (block $L13
  local.get $V_Recv
  call $rt_erlang_is_integer
  call $rt_pending
  br_if $L13
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L12
  br $L11
  )
  call $rt_clear
  )
  br $L10
  )
  local.get $V_Recv
  call $rt_erlang_integer_to_binary
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L14
  local.get $a0
  local.set $V_Recv
  (block $L15
  (block $L16
  (block $L17
  local.get $V_Recv
  call $rt_erlang_is_float
  call $rt_pending
  br_if $L17
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L16
  br $L15
  )
  call $rt_clear
  )
  br $L14
  )
  local.get $V_Recv
  global.get $__lit
  i32.const 400
  i32.add
  i32.const 5
  call $rt_atom
  local.set $t1
  call $rt_nil
  local.set $t2
  local.get $t1
  local.get $t2
  call $rt_cons
  call $rt_erlang_float_to_binary2
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L18
  local.get $a0
  local.set $V_Recv
  local.get $V_Recv
  call $bp_comptime_template:__bp_text/1
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
  i32.const 368
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  global.get $__lit
  i32.const 416
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
  i32.const 232
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

(func $string_toString/1 (param $a0 i32) (result i32)
  (local $V_Self i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Self
  local.get $V_Self
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
;;     text => <<"p=__bp_hole_q_0 xs=__bp_hole_q_1 m=__bp_hole_q_2">>,
;;     parts => [
;;         #{
;;             kind => <<"Text">>,
;;             text => <<"p=">>,
;;             span => #{start => 0, 'end' => 2, line => 1}
;;         },
;;         #{
;;             kind => <<"Interp">>,
;;             code => <<"__bp_hole_q_0">>,
;;             span => #{start => 2, 'end' => 15, line => 1},
;;             known => false,
;;             value => undefined
;;         },
;;         #{
;;             kind => <<"Text">>,
;;             text => <<" xs=">>,
;;             span => #{start => 15, 'end' => 19, line => 1}
;;         },
;;         #{
;;             kind => <<"Interp">>,
;;             code => <<"__bp_hole_q_1">>,
;;             span => #{start => 19, 'end' => 32, line => 1},
;;             known => false,
;;             value => undefined
;;         },
;;         #{
;;             kind => <<"Text">>,
;;             text => <<" m=">>,
;;             span => #{start => 32, 'end' => 35, line => 1}
;;         },
;;         #{
;;             kind => <<"Interp">>,
;;             code => <<"__bp_hole_q_2">>,
;;             span => #{start => 35, 'end' => 48, line => 1},
;;             known => true,
;;             value => undefined
;;         }
;;     ],
;;     source => #{file => <<"">>, line => 16, col => 17},
;;     context => #{
;;         source => #{file => <<"">>, line => 16, col => 17},
;;         text => <<"p=__bp_hole_q_0 xs=__bp_hole_q_1 m=__bp_hole_q_2">>,
;;         multiline => true
;;     },
;;     bindings => [
;;         #{
;;             name => <<"xs">>,
;;             kind => 'Val',
;;             identity => <<"main@@xs">>,
;;             local => <<"xs">>
;;         }
;;     ],
;;     words => [<<"p">>, <<"xs">>, <<"m">>]
;; }
```

----- COMPTIME REPLY -- template holes
```json
{
  "kind": "code",
  "source": "#(__bp_hole_q_0, __bp_hole_q_1, __bp_hole_q_2, \"p= xs= m=\", \"0-2;2-15;15-19;19-32;32-35;35-48;\")"
}
```

