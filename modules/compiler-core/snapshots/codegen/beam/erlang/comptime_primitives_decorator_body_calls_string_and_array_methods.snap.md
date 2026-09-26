----- SOURCE CODE -- main.bp
```botopink
pub fn describe(comptime decl: @Decl) {
    val names = decl.fields.map({ f -> f.name });
    val upper = names.map({ n -> n.toUpper() }).join("_");
    val hidden = if (names.contains("secret")) { "hidden"; } else { "open"; };
    val short = decl.name.slice(0, 3);
    val size = if (decl.name.length() == 4) { "four"; } else { "other"; };
    @emit("pub fn describe" + decl.name + "() -> string { return \"" + upper + ":" + hidden + ":" + short + ":" + size + "\"; }");
}

#[describe]
type User(name: string, secret: string, age: i32)

fn main() {
    @print(describeUser());
}
```

----- COMPTIME BEAM ASSEMBLY -- decorator describe
```erlang
{module, decorator_module}.
{exports, [{describe, 1}, {main, 1}]}.
{attributes, []}.
{labels, 106}.

{function, '-describe/1-fun-0-', 1, 24}.
  {label, 23}.
    {func_info, {atom, decorator_module}, {atom, '-describe/1-fun-0-'}, 1}.
  {label, 24}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {atom, name}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, maps, get, 2}, 1}.

{function, '-describe/1-fun-1-', 1, 30}.
  {label, 29}.
    {func_info, {atom, decorator_module}, {atom, '-describe/1-fun-1-'}, 1}.
  {label, 30}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 8}, 1}.

{function, describe, 1, 2}.
  {label, 1}.
    {func_info, {atom, decorator_module}, {atom, describe}, 1}.
  {label, 2}.
    {allocate, 8, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {atom, fields}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, maps, get, 2}}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 24}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call, 2, {f, 4}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 0}}.
    {jump, {f, 28}}.
  {label, 28}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 30}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call, 2, {f, 4}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {literal, <<"_">>}, {x, 1}}.
    {call, 2, {f, 6}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 1}}.
    {jump, {f, 34}}.
  {label, 34}.
    {move, {y, 0}, {x, 0}}.
    {move, {literal, <<"secret">>}, {x, 1}}.
    {call, 2, {f, 10}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 36}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"hidden">>}, {y, 7}}.
    {jump, {f, 35}}.
  {label, 36}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 37}, [{x, 0}, {atom, false}]}.
    {move, {literal, <<"open">>}, {y, 7}}.
    {jump, {f, 35}}.
  {label, 37}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 35}.
    {move, {y, 7}, {y, 2}}.
    {jump, {f, 39}}.
  {label, 39}.
    {move, {atom, name}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, maps, get, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 2}}.
    {call, 3, {f, 12}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 3}}.
    {jump, {f, 41}}.
  {label, 41}.
    {move, {atom, name}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, maps, get, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call, 1, {f, 14}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 43}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"four">>}, {y, 7}}.
    {jump, {f, 42}}.
  {label, 43}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 44}, [{x, 0}, {atom, false}]}.
    {move, {literal, <<"other">>}, {y, 7}}.
    {jump, {f, 42}}.
  {label, 44}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 42}.
    {move, {y, 7}, {y, 4}}.
    {jump, {f, 46}}.
  {label, 46}.
    {move, {atom, name}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, maps, get, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, <<"pub fn describe">>}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_decorator, '__bp_add', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {literal, <<"() -> string { return \"">>}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_decorator, '__bp_add', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_decorator, '__bp_add', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {literal, <<":">>}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_decorator, '__bp_add', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_decorator, '__bp_add', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {literal, <<":">>}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_decorator, '__bp_add', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_decorator, '__bp_add', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {literal, <<":">>}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_decorator, '__bp_add', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_decorator, '__bp_add', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {literal, <<"\"; }">>}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_decorator, '__bp_add', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext_last, 1, {extfunc, bp_comptime_decorator, emit, 1}, 8}.

{function, '__bp_prim_map', 2, 4}.
  {label, 3}.
    {func_info, {atom, decorator_module}, {atom, '__bp_prim_map'}, 2}.
  {label, 4}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 48}, [{x, 0}]}.
    {jump, {f, 49}}.
  {label, 49}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, map, 2}, 3}.
  {label, 48}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_unsupported_method}, {literal, <<"map">>}, {integer, 1}, {y, 0}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 3}.

{function, '-__bp_prim_join/2-fun-2-', 1, 55}.
  {label, 54}.
    {func_info, {atom, decorator_module}, {atom, '-__bp_prim_join/2-fun-2-'}, 1}.
  {label, 55}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 59}, [{x, 0}]}.
    {jump, {f, 60}}.
  {label, 60}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 59}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 61}, [{x, 0}]}.
    {jump, {f, 62}}.
  {label, 62}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 2}.
  {label, 61}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 63}, [{x, 0}]}.
    {jump, {f, 64}}.
  {label, 64}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 63}.
    {jump, {f, 66}}.
  {label, 66}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, [126, 112]}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 2}.

{function, '__bp_prim_join', 2, 6}.
  {label, 5}.
    {func_info, {atom, decorator_module}, {atom, '__bp_prim_join'}, 2}.
  {label, 6}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 52}, [{x, 0}]}.
    {jump, {f, 53}}.
  {label, 53}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 55}, 2, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 3}.
  {label, 52}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_unsupported_method}, {literal, <<"join">>}, {integer, 1}, {y, 0}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 3}.

{function, '__bp_prim_toUpper', 1, 8}.
  {label, 7}.
    {func_info, {atom, decorator_module}, {atom, '__bp_prim_toUpper'}, 1}.
  {label, 8}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 69}, [{x, 0}]}.
    {jump, {f, 70}}.
  {label, 70}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, string, uppercase, 1}, 2}.
  {label, 69}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_unsupported_method}, {literal, <<"toUpper">>}, {integer, 0}, {y, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 2}.

{function, '__bp_prim_contains', 2, 10}.
  {label, 9}.
    {func_info, {atom, decorator_module}, {atom, '__bp_prim_contains'}, 2}.
  {label, 10}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 73}, [{x, 0}]}.
    {jump, {f, 74}}.
  {label, 74}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, member, 2}, 3}.
  {label, 73}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 75}, [{x, 0}]}.
    {jump, {f, 76}}.
  {label, 76}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, string, find, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {atom, nomatch}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 75}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_unsupported_method}, {literal, <<"contains">>}, {integer, 1}, {y, 0}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 3}.

{function, '__bp_prim_slice', 3, 12}.
  {label, 11}.
    {func_info, {atom, decorator_module}, {atom, '__bp_prim_slice'}, 3}.
  {label, 12}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 79}, [{x, 0}]}.
    {jump, {f, 80}}.
  {label, 80}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_last, 3, {f, 16}, 4}.
  {label, 79}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 81}, [{x, 0}]}.
    {jump, {f, 82}}.
  {label, 82}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_last, 3, {f, 18}, 4}.
  {label, 81}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_unsupported_method}, {literal, <<"slice">>}, {integer, 2}, {y, 0}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 4}.

{function, '__bp_prim_length', 1, 14}.
  {label, 13}.
    {func_info, {atom, decorator_module}, {atom, '__bp_prim_length'}, 1}.
  {label, 14}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 85}, [{x, 0}]}.
    {jump, {f, 86}}.
  {label, 86}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, length, 1}, 2}.
  {label, 85}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 87}, [{x, 0}]}.
    {jump, {f, 88}}.
  {label, 88}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, string, length, 1}, 2}.
  {label, 87}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_unsupported_method}, {literal, <<"length">>}, {integer, 0}, {y, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 2}.

{function, array_slice, 3, 16}.
  {label, 15}.
    {func_info, {atom, decorator_module}, {atom, array_slice}, 3}.
  {label, 16}.
    {allocate, 6, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {atom, undefined}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 93}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {y, 5}, {x, 2}}.
    {call_ext_last, 3, {extfunc, lists, sublist, 3}, 6}.
  {label, 93}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 94}, [{x, 0}, {atom, false}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nthtail, 2}, 6}.
  {label, 94}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.

{function, string_slice, 3, 18}.
  {label, 17}.
    {func_info, {atom, decorator_module}, {atom, string_slice}, 3}.
  {label, 18}.
    {allocate, 5, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {atom, undefined}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 98}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 4}, {x, 2}}.
    {call_ext_last, 3, {extfunc, string, slice, 3}, 5}.
  {label, 98}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 99}, [{x, 0}, {atom, false}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, string, slice, 2}, 5}.
  {label, 99}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.

{function, main, 1, 20}.
  {label, 19}.
    {func_info, {atom, decorator_module}, {atom, main}, 1}.
  {label, 20}.
    {allocate, 16, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tuple, {f, 101}, [{x, 0}]}.
    {test, test_arity, {f, 101}, [{x, 0}, 1]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {move, {y, 6}, {y, 0}}.
    {move, {atom, '__bp_emitted'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, erase, 1}}.
    {move, {x, 0}, {y, 7}}.
    {'try', {y, 15}, {f, 102}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 2}}.
    {move, {x, 0}, {y, 8}}.
    {call_ext, 0, {extfunc, bp_comptime_decorator, '__bp_emitted', 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, kind}, {literal, <<"ok">>}, {atom, contributions}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, json, encode, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {try_end, {y, 15}}.
    {jump, {f, 103}}.
  {label, 102}.
    {try_case, {y, 15}}.
    {move, {x, 0}, {y, 8}}.
    {move, {x, 1}, {y, 9}}.
    {move, {x, 2}, {y, 10}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 105}, [{x, 0}, {atom, throw}]}.
    {move, {y, 9}, {x, 0}}.
    {test, is_tuple, {f, 105}, [{x, 0}]}.
    {test, test_arity, {f, 105}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 11}}.
    {get_tuple_element, {x, 0}, 1, {y, 12}}.
    {get_tuple_element, {x, 0}, 2, {y, 13}}.
    {move, {y, 11}, {x, 0}}.
    {test, is_eq_exact, {f, 105}, [{x, 0}, {atom, '__bp_decorator_fail'}]}.
    {move, {y, 12}, {y, 1}}.
    {move, {y, 13}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_decorator, '__bp_text', 1}}.
    {move, {x, 0}, {y, 14}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, kind}, {literal, <<"fail">>}, {atom, message}, {y, 14}, {atom, span}, {y, 2}]}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {x, 0}}.
    {call_ext, 1, {extfunc, json, encode, 1}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {y, 7}}.
    {jump, {f, 104}}.
  {label, 105}.
    {move, {y, 8}, {y, 3}}.
    {move, {y, 9}, {y, 4}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_decorator, '__bp_text', 1}}.
    {move, {x, 0}, {y, 11}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, kind}, {literal, <<"error">>}, {atom, message}, {y, 11}]}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {call_ext, 1, {extfunc, json, encode, 1}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {y, 7}}.
    {jump, {f, 104}}.
  {label, 104}.
  {label, 103}.
    {move, {y, 7}, {x, 0}}.
    {deallocate, 16}.
    return.
  {label, 101}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 16}.
    {jump, {f, 19}}.

%% main/1 argument — an external term, not part of the module:
%% Arg0 = #{
%%     kind => 'Type',
%%     name => <<"User">>,
%%     fields => [
%%         #{name => <<"name">>, typeName => <<"string">>, annotations => []},
%%         #{name => <<"secret">>, typeName => <<"string">>, annotations => []},
%%         #{name => <<"age">>, typeName => <<"i32">>, annotations => []}
%%     ],
%%     variants => [],
%%     methods => [],
%%     returnType => <<"">>,
%%     annotations => [#{name => <<"describe">>, args => []}]
%% }
```

----- COMPTIME REPLY -- decorator describe
```json
{
  "contributions": [
    "pub fn describeUser() -> string { return \"NAME_SECRET_AGE:hidden:Use:four\"; }"
  ],
  "kind": "ok"
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([describeUser/0]).

%% behavior String

%% behavior Array

array_range(Start, Stop) ->
    case (Start >= Stop) of
        true ->
            [];
        false ->
            Head = Start,
            [Head] ++ (array_range((Start + 1), Stop))
    end.

array_repeat(Value, Times) ->
    case (Times =< 0) of
        true ->
            [];
        false ->
            Head = Value,
            [Head] ++ (array_repeat(Value, (Times - 1)))
    end.

%% type User: name, secret, age

main() ->
    '__bp_print'([describeUser()]).

describeUser() ->
    <<"NAME_SECRET_AGE:hidden:Use:four">>.

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when is_binary(V) -> V;
'__bp_show'(V, _) when is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when is_tuple(V), tuple_size(V) > 0, is_atom(element(1, V)), element(1, V) =/= true, element(1, V) =/= false, element(1, V) =/= undefined -> '__bp_tagged'(element(1, V), V);
'__bp_show'(V, _) when is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- tuple_to_list(V)]), $)];
'__bp_show'(V, _) when is_atom(V), V =/= true, V =/= false, V =/= undefined -> '__bp_tagged'(V, V);
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'__bp_tagged'(A, V) ->
    M = case string:split(atom_to_list(A), "__v__") of [P, _] -> list_to_atom(P); _ -> A end,
    case code:ensure_loaded(M) =:= {module, M} andalso erlang:function_exported(M, '__bp_format', 1) of true -> '__bp_render'(apply(M, '__bp_format', [V])); false -> io_lib:format("~p", [V]) end.

'__bp_render'({text, T}) -> T;
'__bp_render'({variant, N, []}) -> N;
'__bp_render'({_, N, Fs}) -> [N, $(, lists:join(", ", [[K, ": ", '__bp_show'(Val, false)] || {K, Val} <- Fs]), $)].

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- ERLANG -- test@main@@User.erl
```erlang
-module(test@main@@User).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> element(2, V);
'__bp_get'(V, secret) -> element(3, V);
'__bp_get'(V, age) -> element(4, V).

'__bp_format'(V) -> {record, "User", [{"name", element(2, V)}, {"secret", element(3, V)}, {"age", element(4, V)}]}.
```

----- RUN LOG -----
```logs
NAME_SECRET_AGE:hidden:Use:four
```
