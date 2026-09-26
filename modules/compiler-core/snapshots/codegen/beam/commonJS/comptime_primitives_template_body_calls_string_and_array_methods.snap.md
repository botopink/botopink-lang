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
{labels, 226}.

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
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 121}}.
  {label, 121}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 123}, [{x, 0}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 122}}.
  {label, 123}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 124}, [{x, 0}, {atom, false}]}.
    {move, {y, 3}, {y, 5}}.
    {jump, {f, 122}}.
  {label, 124}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 122}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 126}}.
  {label, 126}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '>=', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 127}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 4}}.
    {jump, {f, 129}}.
  {label, 127}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 128}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 4}}.
    {jump, {f, 129}}.
  {label, 128}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 5}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 129}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 131}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 7}.
  {label, 131}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 132}, [{x, 0}, {atom, false}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 132}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '-__bp_prim_at/2-fun-3-', 2, 136}.
  {label, 135}.
    {func_info, {atom, template_module}, {atom, '-__bp_prim_at/2-fun-3-'}, 2}.
  {label, 136}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, string, length, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 140}}.
  {label, 140}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 142}, [{x, 0}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 141}}.
  {label, 142}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 143}, [{x, 0}, {atom, false}]}.
    {move, {y, 3}, {y, 5}}.
    {jump, {f, 141}}.
  {label, 143}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 141}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 145}}.
  {label, 145}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '>=', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 146}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 4}}.
    {jump, {f, 148}}.
  {label, 146}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 147}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 4}}.
    {jump, {f, 148}}.
  {label, 147}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 5}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 148}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 150}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext_last, 3, {extfunc, string, slice, 3}, 7}.
  {label, 150}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 151}, [{x, 0}, {atom, false}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 151}.
    {move, {y, 4}, {x, 0}}.
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
    {test, is_binary, {f, 133}, [{x, 0}]}.
    {jump, {f, 134}}.
  {label, 134}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 136}, 3, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.
  {label, 133}.
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
    {test, is_list, {f, 154}, [{x, 0}]}.
    {jump, {f, 155}}.
  {label, 155}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, member, 2}, 3}.
  {label, 154}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 156}, [{x, 0}]}.
    {jump, {f, 157}}.
  {label, 157}.
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
  {label, 156}.
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
    {test, is_binary, {f, 160}, [{x, 0}]}.
    {jump, {f, 161}}.
  {label, 161}.
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
  {label, 160}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_unsupported_method}, {literal, <<"startsWith">>}, {integer, 1}, {y, 0}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 3}.

{function, '--__bp_prim_indexOf/2-fun-4--fun-5-', 3, 171}.
  {label, 170}.
    {func_info, {atom, template_module}, {atom, '--__bp_prim_indexOf/2-fun-4--fun-5-'}, 3}.
  {label, 171}.
    {allocate, 10, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {x, 1}, {y, 5}}.
    {move, {x, 2}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 171}, 4, 0, {x, 0}, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_nonempty_list, {f, 173}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 6}, {y, 7}}.
    {move, {y, 6}, {y, 2}}.
    {move, {y, 7}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 175}, [{x, 0}, {atom, true}]}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 175}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 176}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {move, {y, 0}, {x, 2}}.
    {call_last, 3, {f, 171}, 10}.
  {label, 176}.
    {move, {y, 8}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 173}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 177}, [{x, 0}, nil]}.
    {move, {integer, -1}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 177}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {move, {y, 0}, {x, 2}}.
    {deallocate, 10}.
    {jump, {f, 170}}.

{function, '-__bp_prim_indexOf/2-fun-4-', 2, 167}.
  {label, 166}.
    {func_info, {atom, template_module}, {atom, '-__bp_prim_indexOf/2-fun-4-'}, 2}.
  {label, 167}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 171}, 4, 0, {x, 0}, {list, [{y, 2}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 179}}.
  {label, 179}.
    {move, {integer, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 0}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 4}.
    return.

{function, '-__bp_prim_indexOf/2-fun-6-', 2, 183}.
  {label, 182}.
    {func_info, {atom, template_module}, {atom, '-__bp_prim_indexOf/2-fun-6-'}, 2}.
  {label, 183}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 187}, [{x, 0}, {literal, <<"">>}]}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 187}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 190}, [{x, 0}, {atom, nomatch}]}.
    {move, {integer, -1}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 190}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 191}, [{x, 0}]}.
    {test, test_arity, {f, 191}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 191}.
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
    {test, is_list, {f, 164}, [{x, 0}]}.
    {jump, {f, 165}}.
  {label, 165}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 167}, 5, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.
  {label, 164}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 180}, [{x, 0}]}.
    {jump, {f, 181}}.
  {label, 181}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 183}, 6, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.
  {label, 180}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_unsupported_method}, {literal, <<"indexOf">>}, {integer, 1}, {y, 0}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 3}.

{function, '-__bp_prim_join/2-fun-7-', 1, 197}.
  {label, 196}.
    {func_info, {atom, template_module}, {atom, '-__bp_prim_join/2-fun-7-'}, 1}.
  {label, 197}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 201}, [{x, 0}]}.
    {jump, {f, 202}}.
  {label, 202}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 201}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 203}, [{x, 0}]}.
    {jump, {f, 204}}.
  {label, 204}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 2}.
  {label, 203}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 205}, [{x, 0}]}.
    {jump, {f, 206}}.
  {label, 206}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 205}.
    {jump, {f, 208}}.
  {label, 208}.
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
    {test, is_list, {f, 194}, [{x, 0}]}.
    {jump, {f, 195}}.
  {label, 195}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 197}, 7, 0, {x, 0}, {list, []}}.
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
  {label, 194}.
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
    {test, is_eq_exact, {f, 213}, [{x, 0}, {atom, true}]}.
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
  {label, 213}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 214}, [{x, 0}, {atom, false}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nthtail, 2}, 6}.
  {label, 214}.
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
    {test, is_eq_exact, {f, 218}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 4}, {x, 2}}.
    {call_ext_last, 3, {extfunc, string, slice, 3}, 5}.
  {label, 218}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 219}, [{x, 0}, {atom, false}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, string, slice, 2}, 5}.
  {label, 219}.
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
    {test, is_tuple, {f, 221}, [{x, 0}]}.
    {test, test_arity, {f, 221}, [{x, 0}, 1]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {move, {y, 7}, {y, 0}}.
    {'try', {y, 18}, {f, 222}}.
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
    {jump, {f, 223}}.
  {label, 222}.
    {try_case, {y, 18}}.
    {move, {x, 0}, {y, 9}}.
    {move, {x, 1}, {y, 10}}.
    {move, {x, 2}, {y, 11}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 225}, [{x, 0}, {atom, throw}]}.
    {move, {y, 10}, {x, 0}}.
    {test, is_tuple, {f, 225}, [{x, 0}]}.
    {test, test_arity, {f, 225}, [{x, 0}, 4]}.
    {get_tuple_element, {x, 0}, 0, {y, 12}}.
    {get_tuple_element, {x, 0}, 1, {y, 13}}.
    {get_tuple_element, {x, 0}, 2, {y, 14}}.
    {get_tuple_element, {x, 0}, 3, {y, 15}}.
    {move, {y, 12}, {x, 0}}.
    {test, is_eq_exact, {f, 225}, [{x, 0}, {atom, '__bp_template_fail'}]}.
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
    {jump, {f, 224}}.
  {label, 225}.
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
    {jump, {f, 224}}.
  {label, 224}.
  {label, 223}.
    {move, {y, 8}, {x, 0}}.
    {deallocate, 19}.
    return.
  {label, 221}.
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

----- JAVASCRIPT -- main.js
```javascript
function __bp_show(v, s, top, a) {
    if ((typeof v === "string")) {
        a.push(top ? v : (("\"" + Array.from(v, (c) => ((c === "\"") || (c === "\\")) ? ("\\" + c) : (c === "\n") ? "\\n" : (c === "\r") ? "\\r" : (c === "\t") ? "\\t" : c).join("")) + "\""));
        return "%s";
    }
    if (((typeof v === "number") && (s === "f"))) {
        a.push(Number.isInteger(v) ? v.toFixed(1) : String(v));
        return "%s";
    }
    if (Array.isArray(v)) {
        const t = ((s != null) && (s[0] === "#"));
        return (((t ? "#(" : "[") + v.map((e, i) => __bp_show(e, (s == null) ? null : t ? s[i + 1] : s[1], false, a)).join(", ")) + (t ? ")" : "]"));
    }
    if (((v != null) && (typeof v.__bp === "string"))) {
        if ((typeof v.display === "function")) {
            a.push(v.display());
            return "%s";
        }
        const k = Object.keys(v);
        return (((typeof v.tag === "string") ? ((v.__bp + ".") + v.tag) : v.__bp) + ((k.length === 0) ? "" : (("(" + k.map((n) => ((n + ": ") + __bp_show(v[n], null, false, a))).join(", ")) + ")")));
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
//   fn padStart(...)
//   fn padEnd(...)
//   fn repeat(...)
//   fn replaceAll(...)
//   fn chars(...)
//   fn lines(...)
//   fn words(...)
//   fn charCodeAt(...)
//   fn lastIndexOf(...)
String.prototype.slice = function(start, end) {
    const self = this.valueOf();
    if ((end != null)) { return ((__s, __a, __e) => { const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return __s.substring(__b, Math.max(__b, __f)); })(self, start, end); } else { return ((__s, __a) => { const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return __s.substring(__b); })(self, start); }
};
String.prototype.chars = function() { return (Array.from(this.valueOf())); };
String.prototype.lines = function() { return this.valueOf().split(/\r?\n/); };
String.prototype.words = function() { return this.valueOf().split(/[ \t\n\r]+/).filter(__w => __w.length > 0); };
String.prototype.charCodeAt = function(index) { return ((this.valueOf().codePointAt(index) ?? -1) | 0); };

// behavior Array
//   length: i32
//   fn at(...)
//   fn push(...)
//   fn pop(...)
//   default fn slice(...)
//   fn join(...)
//   fn reverse(...)
//   fn indexOf(...)
//   fn forEach(...)
//   fn map(...)
//   fn filter(...)
//   fn zip(...)
//   default fn range(...)
//   default fn repeat(...)
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
Array.range = function(start, stop) {
    return (() => { if ((start >= stop)) { return []; } else { const head = start; return [head, ...(Array.range((start + 1), stop))]; } })();
};
Array.repeat = function(value, times) {
    return (() => { if ((times <= 0)) { return []; } else { const head = value; return [head, ...(Array.repeat(value, (times - 1)))]; } })();
};
Array.prototype.slice = function(start, end) {
    if ((end != null)) { return ((__xs, __a, __e) => { const __n = __xs.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return Array.from({ length: Math.max(__f - __b, 0) }, (_, __i) => __xs[__b + __i]); })(this, start, end); } else { return ((__xs, __a) => { const __n = __xs.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return Array.from({ length: __n - __b }, (_, __i) => __xs[__b + __i]); })(this, start); }
};
Array.prototype.zip = function(other) { return this.map((__x, __i) => [__x, (other)[__i]]).slice(0, Math.min(this.length, (other).length)); };
Array.prototype.isEmpty = function() {
    return (this.length === 0);
};
Array.prototype.contains = function(x) {
    return (this.indexOf(x) !== (-1));
};
Array.prototype.first = function() {
    return this.at(0);
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
    (() => { if (((k % n) === 0)) { return out = out.concat([this.slice(k, (k + n))]); } })();
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
    let first = true;
    let prev = this.at(0);
    this.forEach((x) => {
    (() => { if (first) { out = out.concat([x]); return first = false; } else { return (() => { if ((prev !== x)) { return out = out.concat([x]); } })(); } })();
    prev = x;
});
    return out;
};

const s = "END,WORLD,BIG,HELLO|hello|big world|at|contains|startsWith|indexOf";

function main() {
    __bp_print(s);
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
END,WORLD,BIG,HELLO|hello|big world|at|contains|startsWith|indexOf
```
