----- SOURCE CODE -- main.bp
```botopink
type Op(name: string, run: fn() -> i32, twice: fn() -> i32)

fn two() -> i32 {
    return 2;
}

fn main() {
    val op = comptime Op(name: "two" + "!", run: two, twice: { -> two() * 2 });
    @print(op.name);
    @print(op.run());
    @print(op.twice());
}
```

----- COMPTIME WAT -- comptime block
```wat
(func $__bp_lift/2 (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_V i32) (local $s1 i32) (local $t1 i32) (local $s3 i32) (local $s4 i32) (local $s5 i32) (local $V_E i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_V
  local.get $a1
  local.set $s1
  local.get $V_V
  local.set $t1
  (block $L3 (result i32)
  (block $L4
  local.get $t1
  global.get $__lit
  i32.const 32
  i32.add
  i32.const 9
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L4
  global.get $__lit
  i32.const 48
  i32.add
  i32.const 4
  call $rt_atom
  br $L3
  )
  (block $L5
  local.get $t1
  global.get $__lit
  i32.const 56
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L5
  global.get $__lit
  i32.const 56
  i32.add
  i32.const 4
  call $rt_atom
  br $L3
  )
  (block $L6
  local.get $t1
  global.get $__lit
  i32.const 64
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L6
  global.get $__lit
  i32.const 64
  i32.add
  i32.const 5
  call $rt_atom
  br $L3
  )
  (block $L7
  (block $L8
  (block $L9
  (block $L10
  local.get $V_V
  call $rt_erlang_is_integer
  call $rt_pending
  br_if $L10
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L9
  br $L8
  )
  call $rt_clear
  )
  br $L7
  )
  local.get $V_V
  br $L3
  )
  (block $L11
  (block $L12
  (block $L13
  (block $L14
  local.get $V_V
  call $rt_erlang_is_float
  call $rt_pending
  br_if $L14
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L13
  br $L12
  )
  call $rt_clear
  )
  br $L11
  )
  call $rt_map_empty
  local.set $s3
  local.get $s3
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_bin
  local.get $V_V
  call $rt_map_put
  br $L3
  )
  (block $L15
  (block $L16
  (block $L17
  (block $L18
  local.get $V_V
  call $rt_erlang_is_binary
  call $rt_pending
  br_if $L18
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L17
  br $L16
  )
  call $rt_clear
  )
  br $L15
  )
  local.get $V_V
  br $L3
  )
  (block $L19
  (block $L20
  (block $L21
  (block $L22
  local.get $V_V
  call $rt_erlang_is_atom
  call $rt_pending
  br_if $L22
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L21
  br $L20
  )
  call $rt_clear
  )
  br $L19
  )
  call $rt_map_empty
  local.set $s3
  local.get $s3
  global.get $__lit
  i32.const 80
  i32.add
  i32.const 4
  call $rt_bin
  local.get $V_V
  call $rt_erlang_atom_to_binary
  call $rt_pending
  br_if $raise
  call $rt_map_put
  br $L3
  )
  (block $L23
  (block $L24
  (block $L25
  (block $L26
  local.get $V_V
  call $rt_erlang_is_list
  call $rt_pending
  br_if $L26
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L25
  br $L24
  )
  call $rt_clear
  )
  br $L23
  )
  call $rt_nil
  local.set $s3
  local.get $V_V
  local.set $s4
  (block $L27
  (loop $L28
  local.get $s4
  i32.const 12
  call $rt_is
  i32.eqz
  br_if $L27
  local.get $s4
  call $rt_hd
  local.set $s5
  local.get $s4
  call $rt_tl
  local.set $s4
  (block $L29
  local.get $s5
  local.set $V_E
  local.get $V_E
  local.get $s1
  call $__bp_lift/2
  call $rt_pending
  br_if $raise
  local.get $s3
  call $rt_cons
  local.set $s3
  )
  br $L28
  )
  )
  local.get $s3
  call $rt_lists_reverse
  br $L3
  )
  (block $L30
  (block $L31
  (block $L32
  (block $L33
  local.get $V_V
  call $rt_erlang_is_tuple
  call $rt_pending
  br_if $L33
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L32
  br $L31
  )
  call $rt_clear
  )
  br $L30
  )
  call $rt_map_empty
  local.set $s3
  local.get $s3
  global.get $__lit
  i32.const 88
  i32.add
  i32.const 5
  call $rt_bin
  call $rt_nil
  local.set $s3
  local.get $V_V
  call $rt_erlang_tuple_to_list
  call $rt_pending
  br_if $raise
  local.set $s4
  (block $L34
  (loop $L35
  local.get $s4
  i32.const 12
  call $rt_is
  i32.eqz
  br_if $L34
  local.get $s4
  call $rt_hd
  local.set $s5
  local.get $s4
  call $rt_tl
  local.set $s4
  (block $L36
  local.get $s5
  local.set $V_E
  local.get $V_E
  local.get $s1
  call $__bp_lift/2
  call $rt_pending
  br_if $raise
  local.get $s3
  call $rt_cons
  local.set $s3
  )
  br $L35
  )
  )
  local.get $s3
  call $rt_lists_reverse
  call $rt_map_put
  br $L3
  )
  (block $L37
  (block $L38
  (block $L39
  (block $L40
  local.get $V_V
  call $rt_erlang_is_map
  call $rt_pending
  br_if $L40
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L39
  br $L38
  )
  call $rt_clear
  )
  br $L37
  )
  call $rt_map_empty
  local.set $s3
  local.get $s3
  global.get $__lit
  i32.const 96
  i32.add
  i32.const 6
  call $rt_bin
  i32.const 1
  call $rt_tuple
  local.set $s3
  local.get $s3
  i32.const 0
  local.get $s1
  call $rt_tset
  drop
  local.get $s3
  local.set $s3
  global.get $__tbase
  i32.const 0
  i32.add
  i32.const 2
  local.get $s3
  call $rt_make_fun
  local.get $V_V
  call $rt_maps_map
  call $rt_pending
  br_if $raise
  call $rt_map_put
  br $L3
  )
  (block $L41
  (block $L42
  (block $L43
  (block $L44
  local.get $V_V
  call $rt_erlang_is_function
  call $rt_pending
  br_if $L44
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L43
  br $L42
  )
  call $rt_clear
  )
  br $L41
  )
  call $rt_map_empty
  local.set $s3
  local.get $s3
  global.get $__lit
  i32.const 104
  i32.add
  i32.const 2
  call $rt_bin
  local.get $V_V
  local.get $s1
  call $__bp_fn_index/2
  call $rt_pending
  br_if $raise
  call $rt_map_put
  br $L3
  )
  (block $L45
  call $rt_map_empty
  local.set $s1
  local.get $s1
  global.get $__lit
  i32.const 112
  i32.add
  i32.const 8
  call $rt_bin
  local.get $V_V
  call $bp_comptime_decorator:__bp_text/1
  call $rt_pending
  br_if $raise
  call $rt_map_put
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

(func $fun1:__bp_lift/2 (param $self i32) (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_R i32) (local $V_X i32)
  (block $raise
  local.get $self
  call $rt_fun_env
  i32.const 0
  call $rt_elem
  local.set $V_R
  (block $L1 (result i32)
  (block $L2
  local.get $a1
  local.set $V_X
  local.get $V_X
  local.get $V_R
  call $__bp_lift/2
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

(func $__bp_ct_value/0 (result i32)
  (local $s0 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  call $rt_map_empty
  local.set $s0
  local.get $s0
  global.get $__lit
  i32.const 120
  i32.add
  i32.const 4
  call $rt_atom
  global.get $__lit
  i32.const 128
  i32.add
  i32.const 3
  call $rt_bin
  global.get $__lit
  i32.const 136
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  call $rt_map_put
  local.set $s0
  local.get $s0
  global.get $__lit
  i32.const 144
  i32.add
  i32.const 3
  call $rt_atom
  call $__bp_fn_0/0
  call $rt_pending
  br_if $raise
  call $rt_map_put
  local.set $s0
  local.get $s0
  global.get $__lit
  i32.const 152
  i32.add
  i32.const 5
  call $rt_atom
  call $__bp_fn_1/0
  call $rt_pending
  br_if $raise
  call $rt_map_put
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

(func $__bp_fns/0 (result i32)
  (local $s0 i32) (local $s1 i32) (local $t5 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  i32.const 2
  call $rt_tuple
  local.set $s0
  local.get $s0
  i32.const 0
  i64.const 0
  call $rt_int
  call $rt_tset
  drop
  local.get $s0
  i32.const 1
  call $__bp_fn_0/0
  call $rt_pending
  br_if $raise
  call $rt_tset
  drop
  local.get $s0
  local.set $s0
  i32.const 2
  call $rt_tuple
  local.set $s1
  local.get $s1
  i32.const 0
  i64.const 1
  call $rt_int
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  call $__bp_fn_1/0
  call $rt_pending
  br_if $raise
  call $rt_tset
  drop
  local.get $s1
  local.set $s1
  call $rt_nil
  local.set $t5
  local.get $s1
  local.get $t5
  call $rt_cons
  local.set $s1
  local.get $s0
  local.get $s1
  call $rt_cons
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

(func $__bp_fn_index/2 (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_F i32) (local $s1 i32) (local $s2 i32) (local $s3 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_F
  local.get $a1
  local.set $s1
  local.get $s1
  local.set $s1
  (block $L3 (result i32)
  (block $L4
  local.get $s1
  i32.const 11
  call $rt_is
  i32.eqz
  br_if $L4
  global.get $__lit
  i32.const 48
  i32.add
  i32.const 4
  call $rt_atom
  br $L3
  )
  (block $L5
  local.get $s1
  i32.const 12
  call $rt_is
  i32.eqz
  br_if $L5
  local.get $s1
  call $rt_hd
  local.set $s2
  local.get $s1
  call $rt_tl
  local.set $s3
  local.get $s2
  call $rt_tuple_arity
  i32.const 2
  i32.ne
  br_if $L5
  local.get $s2
  i32.const 0
  call $rt_elem
  local.set $s3
  local.get $s3
  local.set $s3
  local.get $s2
  i32.const 1
  call $rt_elem
  local.set $s2
  local.get $s2
  local.set $s2
  (block $L6
  (block $L7
  (block $L8
  local.get $s2
  local.get $V_F
  call $rt_eqx
  call $rt_bool
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L7
  br $L6
  )
  call $rt_clear
  )
  br $L5
  )
  local.get $s3
  br $L3
  )
  (block $L9
  local.get $s1
  i32.const 12
  call $rt_is
  i32.eqz
  br_if $L9
  local.get $s1
  call $rt_hd
  local.set $s2
  local.get $s1
  call $rt_tl
  local.set $s2
  local.get $s2
  local.set $s2
  local.get $V_F
  local.get $s2
  call $__bp_fn_index/2
  call $rt_pending
  br_if $raise
  br $L3
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

(func $__bp_fn_0/0 (result i32)
  (local $t1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  call $rt_nil
  local.set $t1
  global.get $__tbase
  i32.const 1
  i32.add
  i32.const 0
  local.get $t1
  call $rt_make_fun
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

(func $fun2:__bp_fn_0/0 (param $self i32) (result i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  call $two/0
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

(func $__bp_fn_1/0 (result i32)
  (local $t1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  call $rt_nil
  local.set $t1
  global.get $__tbase
  i32.const 2
  i32.add
  i32.const 0
  local.get $t1
  call $rt_make_fun
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

(func $fun3:__bp_fn_1/0 (param $self i32) (result i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  call $two/0
  call $rt_pending
  br_if $raise
  i64.const 2
  call $rt_int
  call $rt_mul
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

(func $two/0 (result i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  i64.const 2
  call $rt_int
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
```

----- COMPTIME REPLY -- comptime block
```json
{
  "kind": "value",
  "value": {
    "record": {
      "name": "two!",
      "run": {
        "fn": 0
      },
      "twice": {
        "fn": 1
      }
    }
  }
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 43}.

{function, two, 0, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, two}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {integer, 2}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, main, 0, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, main}, 0}.
  {label, 5}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, <<"two!">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 3}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 11}, 0, 0, {x, 0}, {list, []}}.
    {test_heap, 5, 3}.
    {put_tuple2, {x, 0}, {list, [{atom, test@main@@Op}, {x, 1}, {x, 2}, {x, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 14}, [{x, 0}, 4, {atom, test@main@@Op}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 14}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 16}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 41}, [{x, 0}, 4, {atom, test@main@@Op}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 41}.
    {call_fun, 0}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 16}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 42}, [{x, 0}, 4, {atom, test@main@@Op}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 42}.
    {call_fun, 0}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 16}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '_botopink_main', 0, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '_botopink_main'}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 5}, 0}.

{function, main, 1, 9}.
  {label, 8}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, main}, 1}.
  {label, 9}.
    {call_only, 0, {f, 7}}.

{function, '-main/0-fun-0-', 0, 11}.
  {label, 10}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '-main/0-fun-0-'}, 0}.
  {label, 11}.
    {allocate, 0, 0}.
    {call, 0, {f, 3}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 12}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 12}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 13}}.
  {label, 12}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at test@main.bp:8:73">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 13}.
    {deallocate, 0}.
    return.

{function, '__bp_print', 1, 16}.
  {label, 15}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '__bp_print'}, 1}.
  {label, 16}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 20}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 20}.
  {label, 19}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 20}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 18}}.

{function, '-bp_show_elem-', 1, 22}.
  {label, 21}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 22}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 18}}.

{function, '__bp_show', 2, 18}.
  {label, 17}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '__bp_show'}, 2}.
  {label, 18}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 30}, [{x, 0}]}.
    {test, is_eq, {f, 29}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 29}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 30}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 31}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 22}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 93}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 91}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 31}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 33}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 32}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 32}, [{x, 0}]}.
    {test, is_ne_exact, {f, 32}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 32}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 32}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 34}}.
  {label, 32}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 22}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 40}, {x, 0}, {x, 0}}.
    {put_list, {integer, 35}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 33}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 35}, [{x, 0}]}.
    {test, is_ne_exact, {f, 35}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 35}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 36}, [{x, 0}, {atom, undefined}]}.
  {label, 34}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 24}, 2}.
  {label, 35}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 36}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 24}.
  {label, 23}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '__bp_tagged'}, 2}.
  {label, 24}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 37}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 37}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 37}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 38}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 26}, 3}.
  {label, 38}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 26}.
  {label, 25}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '__bp_render'}, 1}.
  {label, 26}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 39}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 39}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 40}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 40}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 28}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {y, 1}, {x, 1}, {x, 1}}.
    {put_list, {integer, 40}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_render_pair-', 1, 28}.
  {label, 27}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 28}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 18}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 6, 1}.
    {put_list, {y, 1}, nil, {x, 1}}.
    {put_list, {literal, <<": ">>}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- test@main@@Op.S
```erlang
{module, test@main@@Op}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 9}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "test@main@@Op.erl", 1}]}.
    {func_info, {atom, test@main@@Op}, {atom, '__bp_get'}, 2}.
  {label, 3}.
    {test, is_eq_exact, {f, 4}, [{x, 1}, {atom, name}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 4}.
    {test, is_eq_exact, {f, 5}, [{x, 1}, {atom, run}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 5}.
    {test, is_eq_exact, {f, 6}, [{x, 1}, {atom, twice}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 6}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 8}.
  {label, 7}.
    {line, [{location, "test@main@@Op.erl", 1}]}.
    {func_info, {atom, test@main@@Op}, {atom, '__bp_format'}, 1}.
  {label, 8}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"twice">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"run">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"name">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Op">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
two!
2
4
```
