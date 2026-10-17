----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val p = Pair.of(1, "one");
    @print(Pair.first(p));
    @print(Function.identity(42));
    val inc = Function.compose({ x -> x + 1 }, { y -> y * 2 });
    @print(inc(10));
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {'__bp_priv__Function_compose', 2}, {'__bp_priv__Function_constant', 1}, {'__bp_priv__Function_flip', 1}, {'__bp_priv__Function_identity', 1}, {'__bp_priv__Pair_first', 1}, {'__bp_priv__Pair_mapFirst', 2}, {'__bp_priv__Pair_mapSecond', 2}, {'__bp_priv__Pair_of', 2}, {'__bp_priv__Pair_second', 1}, {'__bp_priv__Pair_swap', 1}, {'__bp_priv__main', 0}]}.
{attributes, []}.
{labels, 92}.

{function, 'Function_identity', 1, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, 'Function_identity'}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, 'Function_compose', 2, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, 'Function_compose'}, 2}.
  {label, 5}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 29}, 0, 0, {x, 0}, {list, [{y, 1}, {y, 0}]}}.
    {deallocate, 2}.
    return.

{function, 'Function_flip', 1, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, 'Function_flip'}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 31}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {deallocate, 1}.
    return.

{function, 'Function_constant', 1, 9}.
  {label, 8}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, 'Function_constant'}, 1}.
  {label, 9}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 33}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {deallocate, 1}.
    return.

{function, 'Pair_of', 2, 11}.
  {label, 10}.
    {line, [{location, "test@main.erl", 5}]}.
    {func_info, {atom, test@main}, {atom, 'Pair_of'}, 2}.
  {label, 11}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {deallocate, 2}.
    return.

{function, 'Pair_first', 1, 13}.
  {label, 12}.
    {line, [{location, "test@main.erl", 6}]}.
    {func_info, {atom, test@main}, {atom, 'Pair_first'}, 1}.
  {label, 13}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {deallocate, 1}.
    return.

{function, 'Pair_second', 1, 15}.
  {label, 14}.
    {line, [{location, "test@main.erl", 7}]}.
    {func_info, {atom, test@main}, {atom, 'Pair_second'}, 1}.
  {label, 15}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {deallocate, 1}.
    return.

{function, 'Pair_swap', 1, 17}.
  {label, 16}.
    {line, [{location, "test@main.erl", 8}]}.
    {func_info, {atom, test@main}, {atom, 'Pair_swap'}, 1}.
  {label, 17}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{y, 1}, {x, 0}]}}.
    {deallocate, 3}.
    return.

{function, 'Pair_mapFirst', 2, 19}.
  {label, 18}.
    {line, [{location, "test@main.erl", 9}]}.
    {func_info, {atom, test@main}, {atom, 'Pair_mapFirst'}, 2}.
  {label, 19}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{y, 2}, {x, 0}]}}.
    {deallocate, 4}.
    return.

{function, 'Pair_mapSecond', 2, 21}.
  {label, 20}.
    {line, [{location, "test@main.erl", 10}]}.
    {func_info, {atom, test@main}, {atom, 'Pair_mapSecond'}, 2}.
  {label, 21}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{y, 2}, {x, 0}]}}.
    {deallocate, 4}.
    return.

{function, main, 0, 23}.
  {label, 22}.
    {line, [{location, "test@main.erl", 11}]}.
    {func_info, {atom, test@main}, {atom, main}, 0}.
  {label, 23}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {literal, <<"one">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call, 2, {f, 11}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 13}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 35}}.
    {move, {integer, 42}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 35}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 63}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 67}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 10}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 35}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '_botopink_main', 0, 25}.
  {label, 24}.
    {line, [{location, "test@main.erl", 12}]}.
    {func_info, {atom, test@main}, {atom, '_botopink_main'}, 0}.
  {label, 25}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 23}, 0}.

{function, main, 1, 27}.
  {label, 26}.
    {line, [{location, "test@main.erl", 13}]}.
    {func_info, {atom, test@main}, {atom, main}, 1}.
  {label, 27}.
    {call_only, 0, {f, 25}}.

{function, '__bp_priv__Function_compose', 2, 71}.
  {label, 70}.
    {line, [{location, "test@main.erl", 14}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Function_compose'}, 2}.
  {label, 71}.
    {call_only, 2, {f, 5}}.

{function, '__bp_priv__Function_constant', 1, 73}.
  {label, 72}.
    {line, [{location, "test@main.erl", 15}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Function_constant'}, 1}.
  {label, 73}.
    {call_only, 1, {f, 9}}.

{function, '__bp_priv__Function_flip', 1, 75}.
  {label, 74}.
    {line, [{location, "test@main.erl", 16}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Function_flip'}, 1}.
  {label, 75}.
    {call_only, 1, {f, 7}}.

{function, '__bp_priv__Function_identity', 1, 77}.
  {label, 76}.
    {line, [{location, "test@main.erl", 17}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Function_identity'}, 1}.
  {label, 77}.
    {call_only, 1, {f, 3}}.

{function, '__bp_priv__Pair_first', 1, 79}.
  {label, 78}.
    {line, [{location, "test@main.erl", 18}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Pair_first'}, 1}.
  {label, 79}.
    {call_only, 1, {f, 13}}.

{function, '__bp_priv__Pair_mapFirst', 2, 81}.
  {label, 80}.
    {line, [{location, "test@main.erl", 19}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Pair_mapFirst'}, 2}.
  {label, 81}.
    {call_only, 2, {f, 19}}.

{function, '__bp_priv__Pair_mapSecond', 2, 83}.
  {label, 82}.
    {line, [{location, "test@main.erl", 20}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Pair_mapSecond'}, 2}.
  {label, 83}.
    {call_only, 2, {f, 21}}.

{function, '__bp_priv__Pair_of', 2, 85}.
  {label, 84}.
    {line, [{location, "test@main.erl", 21}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Pair_of'}, 2}.
  {label, 85}.
    {call_only, 2, {f, 11}}.

{function, '__bp_priv__Pair_second', 1, 87}.
  {label, 86}.
    {line, [{location, "test@main.erl", 22}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Pair_second'}, 1}.
  {label, 87}.
    {call_only, 1, {f, 15}}.

{function, '__bp_priv__Pair_swap', 1, 89}.
  {label, 88}.
    {line, [{location, "test@main.erl", 23}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Pair_swap'}, 1}.
  {label, 89}.
    {call_only, 1, {f, 17}}.

{function, '__bp_priv__main', 0, 91}.
  {label, 90}.
    {line, [{location, "test@main.erl", 24}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__main'}, 0}.
  {label, 91}.
    {call_only, 0, {f, 23}}.

{function, '-/2-fun-0-', 3, 29}.
  {label, 28}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '-/2-fun-0-'}, 3}.
  {label, 29}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_fun, 1}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 3}.
    return.

{function, '-/1-fun-1-', 3, 31}.
  {label, 30}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-/1-fun-1-'}, 3}.
  {label, 31}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '-/1-fun-2-', 2, 33}.
  {label, 32}.
    {line, [{location, "test@main.erl", 5}]}.
    {func_info, {atom, test@main}, {atom, '-/1-fun-2-'}, 2}.
  {label, 33}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_print', 1, 35}.
  {label, 34}.
    {line, [{location, "test@main.erl", 12}]}.
    {func_info, {atom, test@main}, {atom, '__bp_print'}, 1}.
  {label, 35}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 39}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 39}.
  {label, 38}.
    {line, [{location, "test@main.erl", 12}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 39}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 37}}.

{function, '-bp_show_elem-', 1, 41}.
  {label, 40}.
    {line, [{location, "test@main.erl", 12}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 41}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 37}}.

{function, '__bp_show', 2, 37}.
  {label, 36}.
    {line, [{location, "test@main.erl", 12}]}.
    {func_info, {atom, test@main}, {atom, '__bp_show'}, 2}.
  {label, 37}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 49}, [{x, 0}]}.
    {test, is_eq, {f, 48}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 48}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 49}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 50}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 41}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 50}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 52}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 51}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 51}, [{x, 0}]}.
    {test, is_ne_exact, {f, 51}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 51}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 51}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 56}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 57}}.
  {label, 56}.
    {test, is_eq_exact, {f, 53}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 57}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 37}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 51}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 41}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 52}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 54}, [{x, 0}]}.
    {test, is_ne_exact, {f, 54}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 54}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 55}, [{x, 0}, {atom, undefined}]}.
  {label, 53}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 43}, 2}.
  {label, 54}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 55}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 43}.
  {label, 42}.
    {line, [{location, "test@main.erl", 12}]}.
    {func_info, {atom, test@main}, {atom, '__bp_tagged'}, 2}.
  {label, 43}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 58}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 58}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 58}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 59}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 45}, 3}.
  {label, 59}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 45}.
  {label, 44}.
    {line, [{location, "test@main.erl", 12}]}.
    {func_info, {atom, test@main}, {atom, '__bp_render'}, 1}.
  {label, 45}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 60}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 60}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 61}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 61}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 47}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 47}.
  {label, 46}.
    {line, [{location, "test@main.erl", 12}]}.
    {func_info, {atom, test@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 47}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 37}}.
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

{function, '-main/0-fun-3-', 1, 63}.
  {label, 62}.
    {line, [{location, "test@main.erl", 12}]}.
    {func_info, {atom, test@main}, {atom, '-main/0-fun-3-'}, 1}.
  {label, 63}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 64}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 64}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 65}}.
  {label, 64}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at test@main.bp:5:41">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 65}.
    {deallocate, 1}.
    return.

{function, '-main/0-fun-4-', 1, 67}.
  {label, 66}.
    {line, [{location, "test@main.erl", 12}]}.
    {func_info, {atom, test@main}, {atom, '-main/0-fun-4-'}, 1}.
  {label, 67}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 68}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 68}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 69}}.
  {label, 68}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at test@main.bp:5:57">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 69}.
    {deallocate, 1}.
    return.
```

----- RUN LOG -----
```logs
1
42
22
```
