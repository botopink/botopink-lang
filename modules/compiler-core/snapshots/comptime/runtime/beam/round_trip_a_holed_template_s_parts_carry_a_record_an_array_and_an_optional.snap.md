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

----- COMPTIME BEAM ASSEMBLY -- template holes
```erlang
{module, template_module}.
{exports, [{holes, 1}, {main, 1}]}.
{attributes, []}.
{labels, 82}.

{function, '-holes/1-fun-0-', 2, 22}.
  {label, 21}.
    {func_info, {atom, template_module}, {atom, '-holes/1-fun-0-'}, 2}.
  {label, 22}.
    {allocate, 12, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {x, 1}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tuple, {f, 24}, [{x, 0}]}.
    {test, test_arity, {f, 24}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {get_tuple_element, {x, 0}, 1, {y, 7}}.
    {get_tuple_element, {x, 0}, 2, {y, 8}}.
    {move, {y, 6}, {y, 0}}.
    {move, {y, 7}, {y, 1}}.
    {move, {y, 8}, {y, 2}}.
    {move, {atom, kind}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, maps, get, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {move, {literal, <<"Interp">>}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 26}, [{x, 0}, {atom, true}]}.
    {move, {atom, code}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, maps, get, 2}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 11}, {x, 1}}.
    {call, 2, {f, 4}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {y, 3}}.
    {jump, {f, 28}}.
  {label, 28}.
    {move, {y, 3}, {y, 10}}.
    {jump, {f, 25}}.
  {label, 26}.
    {move, {y, 0}, {y, 10}}.
    {jump, {f, 25}}.
  {label, 25}.
    {move, {y, 10}, {y, 0}}.
    {jump, {f, 31}}.
  {label, 31}.
    {move, {atom, kind}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, maps, get, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {move, {literal, <<"Text">>}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 33}, [{x, 0}, {atom, true}]}.
    {move, {atom, text}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, maps, get, 2}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 11}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {y, 3}}.
    {jump, {f, 35}}.
  {label, 35}.
    {move, {y, 3}, {y, 10}}.
    {jump, {f, 32}}.
  {label, 33}.
    {move, {y, 1}, {y, 10}}.
    {jump, {f, 32}}.
  {label, 32}.
    {move, {y, 10}, {y, 1}}.
    {jump, {f, 38}}.
  {label, 38}.
    {move, {atom, span}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, maps, get, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {atom, start}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, maps, get, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call, 1, {f, 6}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {move, {literal, <<"-">>}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {atom, span}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, maps, get, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {atom, 'end'}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, maps, get, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call, 1, {f, 6}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 9}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {move, {literal, <<";">>}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 2}}.
    {jump, {f, 40}}.
  {label, 40}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {deallocate, 12}.
    return.
  {label, 24}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {deallocate, 12}.
    {jump, {f, 21}}.

{function, holes, 1, 2}.
  {label, 1}.
    {func_info, {atom, template_module}, {atom, holes}, 1}.
  {label, 2}.
    {allocate, 8, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, nil, {y, 0}}.
    {jump, {f, 16}}.
  {label, 16}.
    {move, {literal, <<"">>}, {y, 1}}.
    {jump, {f, 18}}.
  {label, 18}.
    {move, {literal, <<"">>}, {y, 2}}.
    {jump, {f, 20}}.
  {label, 20}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 22}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 4}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_template, parts, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {move, {y, 6}, {x, 2}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 41}, [{x, 0}]}.
    {test, test_arity, {f, 41}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 5}}.
    {get_tuple_element, {x, 0}, 1, {y, 6}}.
    {get_tuple_element, {x, 0}, 2, {y, 7}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {y, 2}}.
    {jump, {f, 42}}.
  {label, 41}.
    {move, {y, 4}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 42}.
    {move, {y, 0}, {x, 0}}.
    {move, {literal, <<", ">>}, {x, 1}}.
    {call, 2, {f, 8}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"#(">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {move, {literal, <<", \"">>}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {move, {literal, <<"\", \"">>}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {move, {literal, <<"\")">>}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext_last, 2, {extfunc, bp_comptime_template, build, 2}, 8}.

{function, '__bp_prim_push', 2, 4}.
  {label, 3}.
    {func_info, {atom, template_module}, {atom, '__bp_prim_push'}, 2}.
  {label, 4}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 44}, [{x, 0}]}.
    {jump, {f, 45}}.
  {label, 45}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '++', 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 44}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_unsupported_method}, {literal, <<"push">>}, {integer, 1}, {y, 0}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 3}.

{function, '__bp_prim_toString', 1, 6}.
  {label, 5}.
    {func_info, {atom, template_module}, {atom, '__bp_prim_toString'}, 1}.
  {label, 6}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 48}, [{x, 0}]}.
    {jump, {f, 49}}.
  {label, 49}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 10}, 1}.
  {label, 48}.
    {move, {y, 0}, {x, 0}}.
    {test, is_boolean, {f, 50}, [{x, 0}]}.
    {jump, {f, 51}}.
  {label, 51}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, atom_to_binary, 1}, 1}.
  {label, 50}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 52}, [{x, 0}]}.
    {jump, {f, 53}}.
  {label, 53}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 1}.
  {label, 52}.
    {move, {y, 0}, {x, 0}}.
    {test, is_float, {f, 54}, [{x, 0}]}.
    {jump, {f, 55}}.
  {label, 55}.
    {move, {y, 0}, {x, 0}}.
    {move, {literal, [short]}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, float_to_binary, 2}, 1}.
  {label, 54}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, bp_comptime_template, '__bp_text', 1}, 1}.

{function, '-__bp_prim_join/2-fun-1-', 1, 61}.
  {label, 60}.
    {func_info, {atom, template_module}, {atom, '-__bp_prim_join/2-fun-1-'}, 1}.
  {label, 61}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 65}, [{x, 0}]}.
    {jump, {f, 66}}.
  {label, 66}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 65}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 67}, [{x, 0}]}.
    {jump, {f, 68}}.
  {label, 68}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 2}.
  {label, 67}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 69}, [{x, 0}]}.
    {jump, {f, 70}}.
  {label, 70}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 69}.
    {jump, {f, 72}}.
  {label, 72}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, [126, 112]}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 2}.

{function, '__bp_prim_join', 2, 8}.
  {label, 7}.
    {func_info, {atom, template_module}, {atom, '__bp_prim_join'}, 2}.
  {label, 8}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 58}, [{x, 0}]}.
    {jump, {f, 59}}.
  {label, 59}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 61}, 1, 0, {x, 0}, {list, []}}.
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
  {label, 58}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_unsupported_method}, {literal, <<"join">>}, {integer, 1}, {y, 0}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 3}.

{function, string_toString, 1, 10}.
  {label, 9}.
    {func_info, {atom, template_module}, {atom, string_toString}, 1}.
  {label, 10}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, main, 1, 12}.
  {label, 11}.
    {func_info, {atom, template_module}, {atom, main}, 1}.
  {label, 12}.
    {allocate, 16, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 77}, [{x, 0}]}.
    {test, test_arity, {f, 77}, [{x, 0}, 1]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {'try', {y, 15}, {f, 78}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_template, '__bp_reply', 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext, 1, {extfunc, json, encode, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {try_end, {y, 15}}.
    {jump, {f, 79}}.
  {label, 78}.
    {try_case, {y, 15}}.
    {move, {x, 0}, {y, 6}}.
    {move, {x, 1}, {y, 7}}.
    {move, {x, 2}, {y, 8}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 81}, [{x, 0}, {atom, throw}]}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 81}, [{x, 0}]}.
    {test, test_arity, {f, 81}, [{x, 0}, 4]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {get_tuple_element, {x, 0}, 1, {y, 10}}.
    {get_tuple_element, {x, 0}, 2, {y, 11}}.
    {get_tuple_element, {x, 0}, 3, {y, 12}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 81}, [{x, 0}, {atom, '__bp_template_fail'}]}.
    {move, {y, 10}, {y, 0}}.
    {move, {y, 11}, {y, 1}}.
    {move, {y, 12}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_template, '__bp_text', 1}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_template, '__bp_json', 1}}.
    {move, {x, 0}, {y, 14}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, kind}, {literal, <<"fail">>}, {atom, message}, {y, 13}, {atom, param}, {y, 1}, {atom, span}, {y, 14}]}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {call_ext, 1, {extfunc, json, encode, 1}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {y, 5}}.
    {jump, {f, 80}}.
  {label, 81}.
    {move, {y, 6}, {y, 0}}.
    {move, {y, 7}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_template, '__bp_text', 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, kind}, {literal, <<"error">>}, {atom, message}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, json, encode, 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 5}}.
    {jump, {f, 80}}.
  {label, 80}.
  {label, 79}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 16}.
    return.
  {label, 77}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 16}.
    {jump, {f, 11}}.

%% main/1 argument — an external term, not part of the module:
%% Arg0 = #{
%%     '__bp_capture' => <<"q">>,
%%     text => <<"p=__bp_hole_q_0 xs=__bp_hole_q_1 m=__bp_hole_q_2">>,
%%     parts => [
%%         #{
%%             kind => <<"Text">>,
%%             text => <<"p=">>,
%%             span => #{start => 0, 'end' => 2, line => 1}
%%         },
%%         #{
%%             kind => <<"Interp">>,
%%             code => <<"__bp_hole_q_0">>,
%%             span => #{start => 2, 'end' => 15, line => 1},
%%             known => false,
%%             value => undefined
%%         },
%%         #{
%%             kind => <<"Text">>,
%%             text => <<" xs=">>,
%%             span => #{start => 15, 'end' => 19, line => 1}
%%         },
%%         #{
%%             kind => <<"Interp">>,
%%             code => <<"__bp_hole_q_1">>,
%%             span => #{start => 19, 'end' => 32, line => 1},
%%             known => false,
%%             value => undefined
%%         },
%%         #{
%%             kind => <<"Text">>,
%%             text => <<" m=">>,
%%             span => #{start => 32, 'end' => 35, line => 1}
%%         },
%%         #{
%%             kind => <<"Interp">>,
%%             code => <<"__bp_hole_q_2">>,
%%             span => #{start => 35, 'end' => 48, line => 1},
%%             known => true,
%%             value => undefined
%%         }
%%     ],
%%     source => #{file => <<"">>, line => 16, col => 17},
%%     context => #{
%%         source => #{file => <<"">>, line => 16, col => 17},
%%         text => <<"p=__bp_hole_q_0 xs=__bp_hole_q_1 m=__bp_hole_q_2">>,
%%         multiline => true
%%     },
%%     bindings => [
%%         #{
%%             name => <<"xs">>,
%%             kind => 'Val',
%%             identity => <<"main@@xs">>,
%%             local => <<"xs">>
%%         }
%%     ],
%%     words => [<<"p">>, <<"xs">>, <<"m">>]
%% }
```

----- COMPTIME REPLY -- template holes
```json
{
  "kind": "code",
  "source": "#(__bp_hole_q_0, __bp_hole_q_1, __bp_hole_q_2, \"p= xs= m=\", \"0-2;2-15;15-19;19-32;32-35;35-48;\")"
}
```

