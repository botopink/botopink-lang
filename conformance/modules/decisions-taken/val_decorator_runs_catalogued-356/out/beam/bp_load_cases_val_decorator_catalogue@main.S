{module, bp_load_cases_val_decorator_catalogue@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {port, 0}, {host, 0}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__array_first', 1}, {'__bp_priv__array_range', 2}, {'__bp_priv__array_repeat', 2}]}.
{attributes, []}.
{labels, 102}.

{function, 'array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_val_decorator_catalogue@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_val_decorator_catalogue@main}, {atom, 'array_range'}, 2}.
  {label, 3}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_ge, {f, 22}, [{integer, 0}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 23}}.
  {label, 22}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 24}, [{x, 0}, {integer, 1}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {jump, {f, 25}}.
  {label, 24}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 27}}.
  {label, 25}.
  {label, 23}.
    {deallocate, 6}.
    return.

{function, 'array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_val_decorator_catalogue@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_val_decorator_catalogue@main}, {atom, 'array_repeat'}, 2}.
  {label, 5}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 28}, [{integer, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 29}}.
  {label, 28}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_eq_exact, {f, 30}, [{x, 0}, {integer, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 27}}.
    {jump, {f, 31}}.
  {label, 30}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 27}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 27}}.
  {label, 31}.
  {label, 29}.
    {deallocate, 6}.
    return.
%%% Decision 356 — a decorator on a module-level `val` runs over a `@Decl` of
%%% kind `DeclKind.Val`: `name`, `returnType` the declared type as written
%%% (`""` when none), and `setMeta` records meta read back by
%%% `compiler.typeInfo(<val>)`. The `val` is an entry of `@TypeInfo.all`, with its
%%% declared type as `returnTypeName`. On the parent binary the decorator was
%%% dropped silently (`DeclKind.Val` did not exist).

{function, port, 0, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_val_decorator_catalogue@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_val_decorator_catalogue@main}, {atom, port}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {move, {integer, 8080}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, host, 0, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_val_decorator_catalogue@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_val_decorator_catalogue@main}, {atom, host}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {move, {literal, <<"localhost">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, main, 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_val_decorator_catalogue@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_val_decorator_catalogue@main}, {atom, main}, 0}.
  {label, 11}.
    {allocate, 19, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"port">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"i32">>}, {x, 0}}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_val_decorator_catalogue@main@@Setting}, {x, 1}, {x, 0}]}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 34}}.
    {test, is_eq, {f, 35}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 37}}.
  {label, 35}.
    {test, is_tagged_tuple, {f, 36}, [{x, 0}, 3, {atom, bp_load_cases_val_decorator_catalogue@main@@Setting}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 37}}.
  {label, 36}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 37}.
    {test, is_ne_exact, {f, 32}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 38}}.
  {label, 32}.
    {move, {literal, <<"none">>}, {x, 0}}.
  {label, 38}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 40}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"port">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"i32">>}, {x, 0}}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_val_decorator_catalogue@main@@Setting}, {x, 1}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 34}}.
    {test, is_eq, {f, 68}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 70}}.
  {label, 68}.
    {test, is_tagged_tuple, {f, 69}, [{x, 0}, 3, {atom, bp_load_cases_val_decorator_catalogue@main@@Setting}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
    {jump, {f, 70}}.
  {label, 69}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 70}.
    {test, is_ne_exact, {f, 67}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {jump, {f, 71}}.
  {label, 67}.
    {move, {literal, <<"none">>}, {x, 0}}.
  {label, 71}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 40}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"]">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"host">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_val_decorator_catalogue@main@@Setting}, {x, 1}, {x, 0}]}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 34}}.
    {test, is_eq, {f, 73}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 75}}.
  {label, 73}.
    {test, is_tagged_tuple, {f, 74}, [{x, 0}, 3, {atom, bp_load_cases_val_decorator_catalogue@main@@Setting}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
    {jump, {f, 75}}.
  {label, 74}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 75}.
    {test, is_ne_exact, {f, 72}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {jump, {f, 76}}.
  {label, 72}.
    {move, {literal, <<"none">>}, {x, 0}}.
  {label, 76}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"[">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 78}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 40}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"host">>}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, <<"bp_load__cases__val_decorator_catalogue/main">>}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {call, 0, {f, 9}}.
    {move, {x, 0}, {y, 10}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {literal, <<"bp_load__cases__val_decorator_catalogue@main@@Setting">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 82}, 0, 0, {x, 0}, {list, []}}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_val_decorator_catalogue@main@@DeclaredTypedMeta}, {x, 1}, {x, 0}]}}.
    {move, {y, 11}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 8, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_val_decorator_catalogue@main@@Declared}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {x, 0}]}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"port">>}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, <<"bp_load__cases__val_decorator_catalogue/main">>}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, <<"i32">>}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {call, 0, {f, 7}}.
    {move, {x, 0}, {y, 10}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {literal, <<"bp_load__cases__val_decorator_catalogue@main@@Setting">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 84}, 0, 0, {x, 0}, {list, []}}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_val_decorator_catalogue@main@@DeclaredTypedMeta}, {x, 1}, {x, 0}]}}.
    {move, {y, 11}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 8, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_val_decorator_catalogue@main@@Declared}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {x, 0}]}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 40}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 86}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 6}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {call, 0, {f, 7}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 89}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 89}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 90}}.
  {label, 89}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:29:16">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 90}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 40}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 19}.
    return.
% What `#[setting]` records: its key and the `val`'s declared type.

{function, '__bp_loaded_main', 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_val_decorator_catalogue@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_val_decorator_catalogue@main}, {atom, '__bp_loaded_main'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {call, 0, {f, 11}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main_off', 0, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_val_decorator_catalogue@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_val_decorator_catalogue@main}, {atom, '__bp_loaded_main_off'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_info', 0, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_val_decorator_catalogue@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_val_decorator_catalogue@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/val_decorator_catalogue|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_val_decorator_catalogue@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_val_decorator_catalogue@main}, {atom, '_botopink_main'}, 0}.
  {label, 19}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 11}, 0}.

{function, main, 1, 21}.
  {label, 20}.
    {line, [{location, "bp_load_cases_val_decorator_catalogue@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_val_decorator_catalogue@main}, {atom, main}, 1}.
  {label, 21}.
    {call_only, 0, {f, 19}}.

{function, 'array_first', 1, 34}.
  {label, 33}.
    {line, [{location, "bp_load_cases_val_decorator_catalogue@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_val_decorator_catalogue@main}, {atom, 'array_first'}, 1}.
  {label, 34}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_last, 2, {f, 92}, 1}.

{function, '__bp_priv__array_first', 1, 97}.
  {label, 96}.
    {line, [{location, "bp_load_cases_val_decorator_catalogue@main.erl", 13}]}.
    {func_info, {atom, bp_load_cases_val_decorator_catalogue@main}, {atom, '__bp_priv__array_first'}, 1}.
  {label, 97}.
    {call_only, 1, {f, 34}}.

{function, '__bp_priv__array_range', 2, 99}.
  {label, 98}.
    {line, [{location, "bp_load_cases_val_decorator_catalogue@main.erl", 14}]}.
    {func_info, {atom, bp_load_cases_val_decorator_catalogue@main}, {atom, '__bp_priv__array_range'}, 2}.
  {label, 99}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__array_repeat', 2, 101}.
  {label, 100}.
    {line, [{location, "bp_load_cases_val_decorator_catalogue@main.erl", 15}]}.
    {func_info, {atom, bp_load_cases_val_decorator_catalogue@main}, {atom, '__bp_priv__array_repeat'}, 2}.
  {label, 101}.
    {call_only, 2, {f, 5}}.

{function, '__bp_print', 1, 40}.
  {label, 39}.
    {line, [{location, "bp_load_cases_val_decorator_catalogue@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_val_decorator_catalogue@main}, {atom, '__bp_print'}, 1}.
  {label, 40}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 44}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 44}.
  {label, 43}.
    {line, [{location, "bp_load_cases_val_decorator_catalogue@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_val_decorator_catalogue@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 44}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 42}}.

{function, '-bp_show_elem-', 1, 46}.
  {label, 45}.
    {line, [{location, "bp_load_cases_val_decorator_catalogue@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_val_decorator_catalogue@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 46}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 42}}.

{function, '__bp_show', 2, 42}.
  {label, 41}.
    {line, [{location, "bp_load_cases_val_decorator_catalogue@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_val_decorator_catalogue@main}, {atom, '__bp_show'}, 2}.
  {label, 42}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 54}, [{x, 0}]}.
    {test, is_eq, {f, 53}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 53}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 54}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 55}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 46}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 55}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 57}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 56}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 56}, [{x, 0}]}.
    {test, is_ne_exact, {f, 56}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 56}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 56}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 61}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 62}}.
  {label, 61}.
    {test, is_eq_exact, {f, 58}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 62}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 42}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 56}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 46}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 57}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 59}, [{x, 0}]}.
    {test, is_ne_exact, {f, 59}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 59}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 60}, [{x, 0}, {atom, undefined}]}.
  {label, 58}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 48}, 2}.
  {label, 59}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 60}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 48}.
  {label, 47}.
    {line, [{location, "bp_load_cases_val_decorator_catalogue@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_val_decorator_catalogue@main}, {atom, '__bp_tagged'}, 2}.
  {label, 48}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 63}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 63}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 63}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 64}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 50}, 3}.
  {label, 64}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 50}.
  {label, 49}.
    {line, [{location, "bp_load_cases_val_decorator_catalogue@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_val_decorator_catalogue@main}, {atom, '__bp_render'}, 1}.
  {label, 50}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 65}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 65}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 66}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 66}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 52}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 52}.
  {label, 51}.
    {line, [{location, "bp_load_cases_val_decorator_catalogue@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_val_decorator_catalogue@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 52}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 42}}.
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

{function, '-bp_stringify-', 1, 78}.
  {label, 77}.
    {line, [{location, "bp_load_cases_val_decorator_catalogue@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_val_decorator_catalogue@main}, {atom, '-bp_stringify-'}, 1}.
  {label, 78}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 79}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 79}.
    {test, is_integer, {f, 80}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 80}.
    {call, 1, {f, 44}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '-main/0-fun-0-', 0, 82}.
  {label, 81}.
    {line, [{location, "bp_load_cases_val_decorator_catalogue@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_val_decorator_catalogue@main}, {atom, '-main/0-fun-0-'}, 0}.
  {label, 82}.
    {allocate, 0, 0}.
    {move, {literal, <<"host">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_val_decorator_catalogue@main@@Setting}, {x, 1}, {x, 0}]}}.
    {deallocate, 0}.
    return.

{function, '-main/0-fun-1-', 0, 84}.
  {label, 83}.
    {line, [{location, "bp_load_cases_val_decorator_catalogue@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_val_decorator_catalogue@main}, {atom, '-main/0-fun-1-'}, 0}.
  {label, 84}.
    {allocate, 0, 0}.
    {move, {literal, <<"port">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"i32">>}, {x, 0}}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_val_decorator_catalogue@main@@Setting}, {x, 1}, {x, 0}]}}.
    {deallocate, 0}.
    return.

{function, '-main/0-fun-2-', 1, 86}.
  {label, 85}.
    {line, [{location, "bp_load_cases_val_decorator_catalogue@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_val_decorator_catalogue@main}, {atom, '-main/0-fun-2-'}, 1}.
  {label, 86}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 87}, [{x, 0}, 7, {atom, bp_load_cases_val_decorator_catalogue@main@@Declared}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 87}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 88}, [{x, 0}, 7, {atom, bp_load_cases_val_decorator_catalogue@main@@Declared}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 88}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 78}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 40}}.
    {deallocate, 2}.
    return.

{function, '-bp_at-', 2, 92}.
  {label, 91}.
    {line, [{location, "bp_load_cases_val_decorator_catalogue@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_val_decorator_catalogue@main}, {atom, '-bp_at-'}, 2}.
  {label, 92}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_ge, {f, 94}, [{y, 0}, {integer, 0}]}.
    {test, is_lt, {f, 93}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 94}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 93}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 93}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_prim_append', 2, 27}.
  {label, 26}.
    {line, [{location, "bp_load_cases_val_decorator_catalogue@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_val_decorator_catalogue@main}, {atom, '__bp_prim_append'}, 2}.
  {label, 27}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 95}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 2}.
  {label, 95}.
    %% unresolved_method: append/2
    {move, {literal, {unresolved_method, append, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.
