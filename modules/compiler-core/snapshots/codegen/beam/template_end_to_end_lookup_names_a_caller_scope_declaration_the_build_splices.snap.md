----- SOURCE CODE -- main.bp
```botopink
val greeting = "ola mundo";
pub fn refer(expr q: string) -> string {
    val hit = compiler.lookup(q, "greeting");
    if (hit) { b ->
        return compiler.build(b.name);
    } else {
        return compiler.fail("greeting not found in caller scope", at: q);
    };
}
val s = refer @`greeting`;
fn main() {
    @print(s);
}
```

----- COMPTIME WAT -- template refer
```wat
(func $refer/1 (param $a0 i32) (result i32)
  (local $s0 i32) (local $s1 i32) (local $s2 i32) (local $s3 i32) (local $s4 i32) (local $s5 i32)
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
  i32.const 8
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
  i64.const 3
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
  i32.const 1
  call $rt_tuple
  local.set $s2
  local.get $s2
  i32.const 0
  (block $L11 (result i32)
  (block $L12
  local.get $s0
  global.get $__lit
  i32.const 312
  i32.add
  i32.const 34
  call $rt_bin
  call $bp_comptime_template:fail/2
  call $rt_pending
  br_if $L12
  br $L11
  )
  call $rt_class
  local.set $s3
  call $rt_reason
  local.set $s4
  call $rt_clear
  (block $L13 (result i32)
  (block $L14
  local.get $s3
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L14
  local.get $s4
  local.set $s5
  global.get $__lit
  i32.const 304
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 7
  call $rt_int
  i64.const 72
  call $rt_int
  local.get $s5
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s5
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L13
  )
  local.get $s3
  local.get $s4
  call $rt_raise
  drop
  br $raise
  )
  br $L11
  )
  call $rt_tset
  drop
  local.get $s2
  local.set $s2
  (block $L15 (result i32)
  (block $L16
  local.get $s2
  call $rt_tuple_arity
  i32.const 1
  i32.ne
  br_if $L16
  local.get $s2
  i32.const 0
  call $rt_elem
  local.set $s3
  local.get $s3
  local.set $s3
  (block $L17 (result i32)
  (block $L18
  local.get $s3
  call $bp_comptime_template:expr/1
  call $rt_pending
  br_if $L18
  br $L17
  )
  call $rt_class
  local.set $s3
  call $rt_reason
  local.set $s4
  call $rt_clear
  (block $L19 (result i32)
  (block $L20
  local.get $s3
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L20
  local.get $s4
  local.set $s5
  global.get $__lit
  i32.const 304
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 7
  call $rt_int
  i64.const 25
  call $rt_int
  local.get $s5
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s5
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L19
  )
  local.get $s3
  local.get $s4
  call $rt_raise
  drop
  br $raise
  )
  br $L17
  )
  br $L15
  )
  local.get $s2
  call $rt_case_clause
  drop
  br $raise
  )
  br $L9
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
  i32.const 352
  i32.add
  i32.const 4
  call $rt_atom
  local.get $s2
  call $rt_maps_get
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
  i32.const 304
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 5
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
;;     '__bp_capture' => <<"q">>,
;;     text => <<"greeting">>,
;;     parts => [
;;         #{
;;             kind => <<"Text">>,
;;             text => <<"greeting">>,
;;             span => #{start => 0, 'end' => 8, line => 1}
;;         }
;;     ],
;;     source => #{file => <<"">>, line => 10, col => 15},
;;     context => #{
;;         source => #{file => <<"">>, line => 10, col => 15},
;;         text => <<"greeting">>,
;;         multiline => false
;;     },
;;     bindings => [
;;         #{
;;             kind => 'Val',
;;             name => <<"greeting">>,
;;             fields => [],
;;             variants => [],
;;             methods => [],
;;             returnType => <<"">>,
;;             annotations => [],
;;             hooks => [],
;;             params => [],
;;             component => undefined,
;;             module => <<"">>,
;;             owner => undefined,
;;             package => <<"">>,
;;             meta => [],
;;             identity => <<"main@@greeting">>,
;;             local => <<"greeting">>
;;         }
;;     ],
;;     words => [<<"greeting">>]
;; }
```

----- COMPTIME REPLY -- template refer
```json
{
  "kind": "code",
  "source": "greeting"
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {greeting, 0}, {s, 0}, {main, 0}]}.
{attributes, []}.
{labels, 40}.

{function, greeting, 0, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, greeting}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {literal, <<"ola mundo">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, s, 0, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, s}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {call, 0, {f, 3}}.
    {deallocate, 0}.
    return.

{function, main, 0, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, main}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {call, 0, {f, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 13}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 9}.
  {label, 8}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '_botopink_main'}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 7}, 0}.

{function, main, 1, 11}.
  {label, 10}.
    {line, [{location, "test@main.erl", 5}]}.
    {func_info, {atom, test@main}, {atom, main}, 1}.
  {label, 11}.
    {call_only, 0, {f, 9}}.

{function, '__bp_print', 1, 13}.
  {label, 12}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_print'}, 1}.
  {label, 13}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 17}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 17}.
  {label, 16}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 17}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 15}}.

{function, '-bp_show_elem-', 1, 19}.
  {label, 18}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 19}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 15}}.

{function, '__bp_show', 2, 15}.
  {label, 14}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_show'}, 2}.
  {label, 15}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 27}, [{x, 0}]}.
    {test, is_eq, {f, 26}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 26}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 27}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 28}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 19}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 28}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 30}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 29}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 29}, [{x, 0}]}.
    {test, is_ne_exact, {f, 29}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 29}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 29}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 34}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 35}}.
  {label, 34}.
    {test, is_eq_exact, {f, 31}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 35}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 15}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 29}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 19}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 30}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 32}, [{x, 0}]}.
    {test, is_ne_exact, {f, 32}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 32}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 33}, [{x, 0}, {atom, undefined}]}.
  {label, 31}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 21}, 2}.
  {label, 32}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 33}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 21}.
  {label, 20}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_tagged'}, 2}.
  {label, 21}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 36}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 36}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 36}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 37}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 23}, 3}.
  {label, 37}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 23}.
  {label, 22}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_render'}, 1}.
  {label, 23}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 38}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 38}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 39}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 39}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 25}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 25}.
  {label, 24}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 25}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 15}}.
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

----- RUN LOG -----
```logs
ola mundo
```
