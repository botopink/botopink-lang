----- SOURCE CODE -- main.bp
```botopink
pub fn shout(comptime q: @Expr<string>) -> @Expr<string> {
    val t = q.text().trim();
    val words = t.split(" ").map({ w -> w.toUpper() });
    val lead = t.slice(0, 5);
    val rest = t.slice(6, t.length);
    val all = words.append(["END"]).reverse();
    val at = if (words.at(1) == "BIG") { "at"; } else { "-"; };
    val big = if (t.contains("big")) { "contains"; } else { "-"; };
    val greet = if (lead.startsWith("hel")) { "startsWith"; } else { "-"; };
    val where = if (words.indexOf("WORLD") == 2) { "indexOf"; } else { "-"; };
    return q.build("\"" + all.join(",") + "|" + lead + "|" + rest + "|" + at + "|" + big + "|" + greet + "|" + where + "\"");
}

val s = shout " hello big world ";

fn main() {
    @print(s);
}
```

----- COMPTIME BEAM ASSEMBLY -- template shout
```erlang
{module, template_module}.
{exports, [{shout, 1}, {main, 1}]}.
{attributes, []}.
{labels, 212}.

{function, '-shout/1-fun-0-', 1, 38}.
  {label, 37}.
    {func_info, {atom, template_module}, {atom, '-shout/1-fun-0-'}, 1}.
  {label, 38}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 10}, 1}.

{function, shout, 1, 2}.
  {label, 1}.
    {func_info, {atom, template_module}, {atom, shout}, 1}.
  {label, 2}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_template, text, 1}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call, 1, {f, 4}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 0}}.
    {jump, {f, 36}}.
  {label, 36}.
    {move, {y, 0}, {x, 0}}.
    {move, {literal, <<" ">>}, {x, 1}}.
    {call, 2, {f, 8}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 38}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 10}, {x, 0}}.
    {move, {y, 11}, {x, 1}}.
    {call, 2, {f, 6}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 1}}.
    {jump, {f, 42}}.
  {label, 42}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {move, {integer, 5}, {x, 2}}.
    {call, 3, {f, 12}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 2}}.
    {jump, {f, 44}}.
  {label, 44}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, length}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_len', 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 6}, {x, 1}}.
    {move, {y, 10}, {x, 2}}.
    {call, 3, {f, 12}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 3}}.
    {jump, {f, 46}}.
  {label, 46}.
    {move, {y, 1}, {x, 0}}.
    {move, {literal, [<<"END">>]}, {x, 1}}.
    {call, 2, {f, 16}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call, 1, {f, 14}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 4}}.
    {jump, {f, 48}}.
  {label, 48}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 2, {f, 18}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {move, {literal, <<"BIG">>}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {test, is_eq_exact, {f, 50}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"at">>}, {y, 11}}.
    {jump, {f, 49}}.
  {label, 50}.
    {move, {y, 10}, {x, 0}}.
    {test, is_eq_exact, {f, 51}, [{x, 0}, {atom, false}]}.
    {move, {literal, <<"-">>}, {y, 11}}.
    {jump, {f, 49}}.
  {label, 51}.
    {move, {y, 10}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 49}.
    {move, {y, 11}, {y, 5}}.
    {jump, {f, 53}}.
  {label, 53}.
    {move, {y, 0}, {x, 0}}.
    {move, {literal, <<"big">>}, {x, 1}}.
    {call, 2, {f, 20}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {test, is_eq_exact, {f, 55}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"contains">>}, {y, 11}}.
    {jump, {f, 54}}.
  {label, 55}.
    {move, {y, 10}, {x, 0}}.
    {test, is_eq_exact, {f, 56}, [{x, 0}, {atom, false}]}.
    {move, {literal, <<"-">>}, {y, 11}}.
    {jump, {f, 54}}.
  {label, 56}.
    {move, {y, 10}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 54}.
    {move, {y, 11}, {y, 6}}.
    {jump, {f, 58}}.
  {label, 58}.
    {move, {y, 2}, {x, 0}}.
    {move, {literal, <<"hel">>}, {x, 1}}.
    {call, 2, {f, 22}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {test, is_eq_exact, {f, 60}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"startsWith">>}, {y, 11}}.
    {jump, {f, 59}}.
  {label, 60}.
    {move, {y, 10}, {x, 0}}.
    {test, is_eq_exact, {f, 61}, [{x, 0}, {atom, false}]}.
    {move, {literal, <<"-">>}, {y, 11}}.
    {jump, {f, 59}}.
  {label, 61}.
    {move, {y, 10}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 59}.
    {move, {y, 11}, {y, 7}}.
    {jump, {f, 63}}.
  {label, 63}.
    {move, {y, 1}, {x, 0}}.
    {move, {literal, <<"WORLD">>}, {x, 1}}.
    {call, 2, {f, 24}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {move, {integer, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {test, is_eq_exact, {f, 65}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"indexOf">>}, {y, 11}}.
    {jump, {f, 64}}.
  {label, 65}.
    {move, {y, 10}, {x, 0}}.
    {test, is_eq_exact, {f, 66}, [{x, 0}, {atom, false}]}.
    {move, {literal, <<"-">>}, {y, 11}}.
    {jump, {f, 64}}.
  {label, 66}.
    {move, {y, 10}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 64}.
    {move, {y, 11}, {y, 8}}.
    {jump, {f, 68}}.
  {label, 68}.
    {move, {y, 4}, {x, 0}}.
    {move, {literal, <<",">>}, {x, 1}}.
    {call, 2, {f, 26}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, <<"\"">>}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {move, {literal, <<"|">>}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {move, {literal, <<"|">>}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {move, {literal, <<"|">>}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {move, {literal, <<"|">>}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {move, {literal, <<"|">>}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {move, {literal, <<"|">>}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {move, {literal, <<"\"">>}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 9}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext_last, 2, {extfunc, bp_comptime_template, build, 2}, 12}.

{function, '__bp_prim_trim', 1, 4}.
  {label, 3}.
    {func_info, {atom, template_module}, {atom, '__bp_prim_trim'}, 1}.
  {label, 4}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 70}, [{x, 0}]}.
    {jump, {f, 71}}.
  {label, 71}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, string, trim, 1}, 2}.
  {label, 70}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_unsupported_method}, {literal, <<"trim">>}, {integer, 0}, {y, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 2}.

{function, '__bp_prim_map', 2, 6}.
  {label, 5}.
    {func_info, {atom, template_module}, {atom, '__bp_prim_map'}, 2}.
  {label, 6}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 74}, [{x, 0}]}.
    {jump, {f, 75}}.
  {label, 75}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, map, 2}, 3}.
  {label, 74}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_unsupported_method}, {literal, <<"map">>}, {integer, 1}, {y, 0}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 3}.

{function, '-__bp_prim_split/2-fun-1-', 2, 81}.
  {label, 80}.
    {func_info, {atom, template_module}, {atom, '-__bp_prim_split/2-fun-1-'}, 2}.
  {label, 81}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 83}, [{x, 0}, {literal, <<"">>}]}.
    {move, nil, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {test, is_list, {f, 85}, [{x, 0}]}.
    {jump, {f, 86}}.
  {label, 85}.
    {test, is_tuple, {f, 87}, [{x, 0}]}.
    {test, test_arity, {f, 87}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 86}}.
  {label, 87}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 1}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 86}.
    {move, {x, 0}, {y, 4}}.
  {label, 88}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nonempty_list, {f, 89}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 4}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 91}, [{x, 0}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {test, is_binary, {f, 91}, [{x, 0}]}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 92}}.
  {label, 91}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 92}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 88}}.
  {label, 89}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nil, {f, 90}, [{x, 0}]}.
    {jump, {f, 84}}.
  {label, 90}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 84}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 83}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {atom, all}, {x, 2}}.
    {call_ext_last, 3, {extfunc, string, split, 3}, 7}.

{function, '__bp_prim_split', 2, 8}.
  {label, 7}.
    {func_info, {atom, template_module}, {atom, '__bp_prim_split'}, 2}.
  {label, 8}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 78}, [{x, 0}]}.
    {jump, {f, 79}}.
  {label, 79}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 81}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.
  {label, 78}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_unsupported_method}, {literal, <<"split">>}, {integer, 1}, {y, 0}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 3}.

{function, '__bp_prim_toUpper', 1, 10}.
  {label, 9}.
    {func_info, {atom, template_module}, {atom, '__bp_prim_toUpper'}, 1}.
  {label, 10}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 96}, [{x, 0}]}.
    {jump, {f, 97}}.
  {label, 97}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, string, uppercase, 1}, 2}.
  {label, 96}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_unsupported_method}, {literal, <<"toUpper">>}, {integer, 0}, {y, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 2}.

{function, '__bp_prim_slice', 3, 12}.
  {label, 11}.
    {func_info, {atom, template_module}, {atom, '__bp_prim_slice'}, 3}.
  {label, 12}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 100}, [{x, 0}]}.
    {jump, {f, 101}}.
  {label, 101}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_last, 3, {f, 28}, 4}.
  {label, 100}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 102}, [{x, 0}]}.
    {jump, {f, 103}}.
  {label, 103}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_last, 3, {f, 30}, 4}.
  {label, 102}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_unsupported_method}, {literal, <<"slice">>}, {integer, 2}, {y, 0}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 4}.

{function, '__bp_prim_reverse', 1, 14}.
  {label, 13}.
    {func_info, {atom, template_module}, {atom, '__bp_prim_reverse'}, 1}.
  {label, 14}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 106}, [{x, 0}]}.
    {jump, {f, 107}}.
  {label, 107}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, lists, reverse, 1}, 2}.
  {label, 106}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_unsupported_method}, {literal, <<"reverse">>}, {integer, 0}, {y, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 2}.

{function, '__bp_prim_append', 2, 16}.
  {label, 15}.
    {func_info, {atom, template_module}, {atom, '__bp_prim_append'}, 2}.
  {label, 16}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 110}, [{x, 0}]}.
    {jump, {f, 111}}.
  {label, 111}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '++', 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 110}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_unsupported_method}, {literal, <<"append">>}, {integer, 1}, {y, 0}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 3}.

{function, '-__bp_prim_at/2-fun-2-', 2, 117}.
  {label, 116}.
    {func_info, {atom, template_module}, {atom, '-__bp_prim_at/2-fun-2-'}, 2}.
  {label, 117}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '>=', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 120}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 2}}.
    {jump, {f, 122}}.
  {label, 120}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 121}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 2}}.
    {jump, {f, 122}}.
  {label, 121}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 3}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 122}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 124}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 5}.
  {label, 124}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 125}, [{x, 0}, {atom, false}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 125}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '-__bp_prim_at/2-fun-3-', 2, 129}.
  {label, 128}.
    {func_info, {atom, template_module}, {atom, '-__bp_prim_at/2-fun-3-'}, 2}.
  {label, 129}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '>=', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 132}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, string, length, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 2}}.
    {jump, {f, 134}}.
  {label, 132}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 133}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 2}}.
    {jump, {f, 134}}.
  {label, 133}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 3}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 134}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 136}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext_last, 3, {extfunc, string, slice, 3}, 5}.
  {label, 136}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 137}, [{x, 0}, {atom, false}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 137}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_prim_at', 2, 18}.
  {label, 17}.
    {func_info, {atom, template_module}, {atom, '__bp_prim_at'}, 2}.
  {label, 18}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 114}, [{x, 0}]}.
    {jump, {f, 115}}.
  {label, 115}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 117}, 2, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.
  {label, 114}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 126}, [{x, 0}]}.
    {jump, {f, 127}}.
  {label, 127}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 129}, 3, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.
  {label, 126}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_unsupported_method}, {literal, <<"at">>}, {integer, 1}, {y, 0}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 3}.

{function, '__bp_prim_contains', 2, 20}.
  {label, 19}.
    {func_info, {atom, template_module}, {atom, '__bp_prim_contains'}, 2}.
  {label, 20}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 140}, [{x, 0}]}.
    {jump, {f, 141}}.
  {label, 141}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, member, 2}, 3}.
  {label, 140}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 142}, [{x, 0}]}.
    {jump, {f, 143}}.
  {label, 143}.
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
  {label, 142}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_unsupported_method}, {literal, <<"contains">>}, {integer, 1}, {y, 0}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 3}.

{function, '__bp_prim_startsWith', 2, 22}.
  {label, 21}.
    {func_info, {atom, template_module}, {atom, '__bp_prim_startsWith'}, 2}.
  {label, 22}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 146}, [{x, 0}]}.
    {jump, {f, 147}}.
  {label, 147}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {atom, nomatch}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 146}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_unsupported_method}, {literal, <<"startsWith">>}, {integer, 1}, {y, 0}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 3}.

{function, '--__bp_prim_indexOf/2-fun-4--fun-5-', 3, 157}.
  {label, 156}.
    {func_info, {atom, template_module}, {atom, '--__bp_prim_indexOf/2-fun-4--fun-5-'}, 3}.
  {label, 157}.
    {allocate, 10, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {x, 1}, {y, 5}}.
    {move, {x, 2}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 157}, 4, 0, {x, 0}, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_nonempty_list, {f, 159}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 6}, {y, 7}}.
    {move, {y, 6}, {y, 2}}.
    {move, {y, 7}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 161}, [{x, 0}, {atom, true}]}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 161}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 162}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {move, {y, 0}, {x, 2}}.
    {call_last, 3, {f, 157}, 10}.
  {label, 162}.
    {move, {y, 8}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 159}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 163}, [{x, 0}, nil]}.
    {move, {integer, -1}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 163}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {move, {y, 0}, {x, 2}}.
    {deallocate, 10}.
    {jump, {f, 156}}.

{function, '-__bp_prim_indexOf/2-fun-4-', 2, 153}.
  {label, 152}.
    {func_info, {atom, template_module}, {atom, '-__bp_prim_indexOf/2-fun-4-'}, 2}.
  {label, 153}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 157}, 4, 0, {x, 0}, {list, [{y, 2}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 165}}.
  {label, 165}.
    {move, {integer, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 0}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 4}.
    return.

{function, '-__bp_prim_indexOf/2-fun-6-', 2, 169}.
  {label, 168}.
    {func_info, {atom, template_module}, {atom, '-__bp_prim_indexOf/2-fun-6-'}, 2}.
  {label, 169}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 173}, [{x, 0}, {literal, <<"">>}]}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 173}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 176}, [{x, 0}, {atom, nomatch}]}.
    {move, {integer, -1}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 176}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 177}, [{x, 0}]}.
    {test, test_arity, {f, 177}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 177}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_prim_indexOf', 2, 24}.
  {label, 23}.
    {func_info, {atom, template_module}, {atom, '__bp_prim_indexOf'}, 2}.
  {label, 24}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 150}, [{x, 0}]}.
    {jump, {f, 151}}.
  {label, 151}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 153}, 5, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.
  {label, 150}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 166}, [{x, 0}]}.
    {jump, {f, 167}}.
  {label, 167}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 169}, 6, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.
  {label, 166}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_unsupported_method}, {literal, <<"indexOf">>}, {integer, 1}, {y, 0}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 3}.

{function, '-__bp_prim_join/2-fun-7-', 1, 183}.
  {label, 182}.
    {func_info, {atom, template_module}, {atom, '-__bp_prim_join/2-fun-7-'}, 1}.
  {label, 183}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 187}, [{x, 0}]}.
    {jump, {f, 188}}.
  {label, 188}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 187}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 189}, [{x, 0}]}.
    {jump, {f, 190}}.
  {label, 190}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 2}.
  {label, 189}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 191}, [{x, 0}]}.
    {jump, {f, 192}}.
  {label, 192}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 191}.
    {jump, {f, 194}}.
  {label, 194}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, [126, 112]}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 2}.

{function, '__bp_prim_join', 2, 26}.
  {label, 25}.
    {func_info, {atom, template_module}, {atom, '__bp_prim_join'}, 2}.
  {label, 26}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 180}, [{x, 0}]}.
    {jump, {f, 181}}.
  {label, 181}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 183}, 7, 0, {x, 0}, {list, []}}.
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
  {label, 180}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_unsupported_method}, {literal, <<"join">>}, {integer, 1}, {y, 0}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 3}.

{function, array_slice, 3, 28}.
  {label, 27}.
    {func_info, {atom, template_module}, {atom, array_slice}, 3}.
  {label, 28}.
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
    {test, is_eq_exact, {f, 199}, [{x, 0}, {atom, true}]}.
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
  {label, 199}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 200}, [{x, 0}, {atom, false}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nthtail, 2}, 6}.
  {label, 200}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.

{function, string_slice, 3, 30}.
  {label, 29}.
    {func_info, {atom, template_module}, {atom, string_slice}, 3}.
  {label, 30}.
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
    {test, is_eq_exact, {f, 204}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 4}, {x, 2}}.
    {call_ext_last, 3, {extfunc, string, slice, 3}, 5}.
  {label, 204}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 205}, [{x, 0}, {atom, false}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, string, slice, 2}, 5}.
  {label, 205}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.

{function, main, 1, 32}.
  {label, 31}.
    {func_info, {atom, template_module}, {atom, main}, 1}.
  {label, 32}.
    {allocate, 19, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 207}, [{x, 0}]}.
    {test, test_arity, {f, 207}, [{x, 0}, 1]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {move, {y, 7}, {y, 0}}.
    {'try', {y, 18}, {f, 208}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_template, '__bp_reply', 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, json, encode, 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 8}}.
    {try_end, {y, 18}}.
    {jump, {f, 209}}.
  {label, 208}.
    {try_case, {y, 18}}.
    {move, {x, 0}, {y, 9}}.
    {move, {x, 1}, {y, 10}}.
    {move, {x, 2}, {y, 11}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 211}, [{x, 0}, {atom, throw}]}.
    {move, {y, 10}, {x, 0}}.
    {test, is_tuple, {f, 211}, [{x, 0}]}.
    {test, test_arity, {f, 211}, [{x, 0}, 4]}.
    {get_tuple_element, {x, 0}, 0, {y, 12}}.
    {get_tuple_element, {x, 0}, 1, {y, 13}}.
    {get_tuple_element, {x, 0}, 2, {y, 14}}.
    {get_tuple_element, {x, 0}, 3, {y, 15}}.
    {move, {y, 12}, {x, 0}}.
    {test, is_eq_exact, {f, 211}, [{x, 0}, {atom, '__bp_template_fail'}]}.
    {move, {y, 13}, {y, 1}}.
    {move, {y, 14}, {y, 2}}.
    {move, {y, 15}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_template, '__bp_text', 1}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_template, '__bp_json', 1}}.
    {move, {x, 0}, {y, 17}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, kind}, {literal, <<"fail">>}, {atom, message}, {y, 16}, {atom, param}, {y, 2}, {atom, span}, {y, 17}]}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {x, 0}}.
    {call_ext, 1, {extfunc, json, encode, 1}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {y, 8}}.
    {jump, {f, 210}}.
  {label, 211}.
    {move, {y, 9}, {y, 4}}.
    {move, {y, 10}, {y, 5}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_template, '__bp_text', 1}}.
    {move, {x, 0}, {y, 12}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, kind}, {literal, <<"error">>}, {atom, message}, {y, 12}]}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {call_ext, 1, {extfunc, json, encode, 1}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {y, 8}}.
    {jump, {f, 210}}.
  {label, 210}.
  {label, 209}.
    {move, {y, 8}, {x, 0}}.
    {deallocate, 19}.
    return.
  {label, 207}.
    {move, {y, 6}, {x, 0}}.
    {deallocate, 19}.
    {jump, {f, 31}}.

%% main/1 argument — an external term, not part of the module:
%% Arg0 = #{
%%     '__bp_capture' => <<"q">>,
%%     text => <<" hello big world ">>,
%%     parts => [
%%         #{
%%             kind => <<"Text">>,
%%             text => <<" hello big world ">>,
%%             span => #{start => 0, 'end' => 17, line => 1}
%%         }
%%     ],
%%     source => #{file => <<"">>, line => 14, col => 15},
%%     context => #{
%%         source => #{file => <<"">>, line => 14, col => 15},
%%         text => <<" hello big world ">>,
%%         multiline => false
%%     },
%%     bindings => [
%%         #{name => <<"shout">>, kind => 'Fn'},
%%         #{name => <<"s">>, kind => 'Val'},
%%         #{name => <<"main">>, kind => 'Fn'}
%%     ]
%% }
```

----- COMPTIME REPLY -- template shout
```json
{
  "kind": "code",
  "source": "\"END,WORLD,BIG,HELLO|hello|big world|at|contains|startsWith|indexOf\""
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (data (i32.const 256) "\42\00\00\00END,WORLD,BIG,HELLO|hello|big world|at|contains|startsWith|indexOf")
  (global $__heap_ptr (mut i32) (i32.const 328))
  (global $s (mut i32) (i32.const 256))
  (func $main
    global.get $s
    call $__print_str
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
  ;; Scratch layout below the data section (which starts at 256):
  ;;   0..8  WASI iovec   8  newline byte
  ;;  16..32 bool text   32..64 float fraction   64..128 i32 digits
  (func $__write_bytes (param $p i32) (param $n i32)
    i32.const 0
    local.get $p
    i32.store
    i32.const 4
    local.get $n
    i32.store
    i32.const 1
    i32.const 0
    i32.const 1
    i32.const 8
    call $fd_write
    drop
  )
  (func $__print_nl
    i32.const 8
    i32.const 10
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
  )
  ;; separator between the arguments of a multi-argument `@print`
  (func $__print_sp
    i32.const 8
    i32.const 32
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
  )
  (func $__print_i32 (param $n i32)
    local.get $n
    call $__print_i32_raw
    call $__print_nl
  )
  (func $__print_i32_raw (param $n i32)
    (local $buf i32) (local $len i32) (local $neg i32) (local $d i32)
    (local $i i32) (local $j i32) (local $tmp i32)
    i32.const 64
    local.set $buf
    local.get $n
    i32.const 0
    i32.lt_s
    (if
      (then
        i32.const 1
        local.set $neg
        i32.const 0
        local.get $n
        i32.sub
        local.set $n
      )
    )
    (block $done
      (loop $digits
        local.get $n
        i32.const 10
        i32.rem_u
        i32.const 48
        i32.add
        local.set $d
        local.get $buf
        local.get $len
        i32.add
        local.get $d
        i32.store8
        local.get $len
        i32.const 1
        i32.add
        local.set $len
        local.get $n
        i32.const 10
        i32.div_u
        local.set $n
        local.get $n
        i32.const 0
        i32.gt_u
        br_if $digits
      )
    )
    ;; reverse
    i32.const 0
    local.set $i
    local.get $len
    i32.const 1
    i32.sub
    local.set $j
    (block $rdone
      (loop $rev
        local.get $i
        local.get $j
        i32.ge_u
        br_if $rdone
        local.get $buf
        local.get $i
        i32.add
        i32.load8_u
        local.set $tmp
        local.get $buf
        local.get $i
        i32.add
        local.get $buf
        local.get $j
        i32.add
        i32.load8_u
        i32.store8
        local.get $buf
        local.get $j
        i32.add
        local.get $tmp
        i32.store8
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        local.get $j
        i32.const 1
        i32.sub
        local.set $j
        br $rev
      )
    )
    ;; add neg sign + newline
    ;; shift the digits one byte right to make room for '-'
    ;; (dst = buf+1, NOT buf+len: the latter moved them `len`
    ;;  bytes and printed -12 as -21)
    local.get $neg
    (if
      (then
        local.get $buf
        i32.const 1
        i32.add
        local.get $buf
        local.get $len
        call $__memmove
        local.get $buf
        i32.const 45
        i32.store8
        local.get $len
        i32.const 1
        i32.add
        local.set $len
      )
    )
    local.get $buf
    local.get $len
    call $__write_bytes
  )
  (func $__memmove (param $dst i32) (param $src i32) (param $len i32)
    (local $i i32)
    local.get $len
    i32.const 1
    i32.sub
    local.set $i
    (block $done
      (loop $loop
        local.get $i
        i32.const 0
        i32.lt_s
        br_if $done
        local.get $dst
        local.get $i
        i32.add
        local.get $src
        local.get $i
        i32.add
        i32.load8_u
        i32.store8
        local.get $i
        i32.const 1
        i32.sub
        local.set $i
        br $loop
      )
    )
  )
  (func $__print_str_raw (param $s i32)
    local.get $s
    i32.const 256
    i32.lt_u
    (if
      (then
        ;; a pointer below the data floor is not a string
        unreachable
      )
    )
    local.get $s
    i32.const 4
    i32.add
    local.get $s
    i32.load
    call $__write_bytes
  )
  (func $__print_str (param $s i32)
    local.get $s
    call $__print_str_raw
    call $__print_nl
  )
)
```

----- RUN LOG -----
```logs
END,WORLD,BIG,HELLO|hello|big world|at|contains|startsWith|indexOf
```
