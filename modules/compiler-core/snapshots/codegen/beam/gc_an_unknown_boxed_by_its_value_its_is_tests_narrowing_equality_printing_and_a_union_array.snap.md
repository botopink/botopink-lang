----- SOURCE CODE -- main.bp
```botopink
fn describe(x: unknown) -> string {
    return case x {
        i32 { n ->
            "number " + n.toString()
        }
        string { s ->
            "text " + s
        }
        _ {
            "other"
        }
    };
}

fn show(x: unknown) -> string {
    if (x is i32) return "i32";
    if (x is f64) return "f64";
    if (x is string) return "string";
    if (x is bool) return "bool";
    return "other";
}

pub fn main() -> void {
    print(describe(3));
    print(describe("a"));
    print(describe(true));
    print(show(1), show(2.5), show("s"), show(false));
    val two: unknown = 2.0;
    print(two == 2, two == 3);
    val t: unknown = "hi";
    print(t == "hi", t);
    val b: unknown = true;
    print(b);
    print(300 is i8, 100 is i8, 2 is f64);
    val xs = [1, "a", true];
    print(xs);
}

import {io.terminal.print} from "std";
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_priv__describe', 1}, {'__bp_priv__show', 1}]}.
{attributes, []}.
{labels, 84}.

{function, describe, 1, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, describe}, 1}.
  {label, 3}.
    {allocate, 7, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_integer, {f, 15}, [{x, 0}]}.
    {jump, {f, 14}}.
  {label, 15}.
    {test, is_float, {f, 13}, [{x, 0}]}.
    {gc_bif, trunc, {f, 0}, 1, [{x, 0}], {x, 1}}.
    {test, is_eq, {f, 13}, [{x, 0}, {x, 1}]}.
  {label, 14}.
    {test, is_ge, {f, 13}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 13}, [{integer, 2147483647}, {x, 0}]}.
    {gc_bif, trunc, {f, 0}, 1, [{x, 0}], {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"number ">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 46}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 12}}.
  {label, 13}.
    {test, is_binary, {f, 49}, [{x, 0}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"text ">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 46}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 12}}.
  {label, 49}.
    {move, {literal, <<"other">>}, {x, 0}}.
    {jump, {f, 12}}.
  {label, 12}.
    {deallocate, 7}.
    return.

{function, show, 1, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, show}, 1}.
  {label, 5}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 54}, [{x, 0}]}.
    {jump, {f, 53}}.
  {label, 54}.
    {test, is_float, {f, 51}, [{x, 0}]}.
    {gc_bif, trunc, {f, 0}, 1, [{x, 0}], {x, 1}}.
    {test, is_eq, {f, 51}, [{x, 0}, {x, 1}]}.
  {label, 53}.
    {test, is_ge, {f, 51}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 51}, [{integer, 2147483647}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 52}}.
  {label, 51}.
    {move, {atom, false}, {x, 0}}.
  {label, 52}.
    {test, is_eq, {f, 50}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, trunc, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"i32">>}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 50}.
    {move, {y, 0}, {x, 0}}.
    {test, is_number, {f, 56}, [{x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 57}}.
  {label, 56}.
    {move, {atom, false}, {x, 0}}.
  {label, 57}.
    {test, is_eq, {f, 55}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, float, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"f64">>}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 55}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 59}, [{x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 60}}.
  {label, 59}.
    {move, {atom, false}, {x, 0}}.
  {label, 60}.
    {test, is_eq, {f, 58}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"string">>}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 58}.
    {move, {y, 0}, {x, 0}}.
    {test, is_boolean, {f, 62}, [{x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 63}}.
  {label, 62}.
    {move, {atom, false}, {x, 0}}.
  {label, 63}.
    {test, is_eq, {f, 61}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"bool">>}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 61}.
    {move, {literal, <<"other">>}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, main, 0, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, main}, 0}.
  {label, 7}.
    {allocate, 16, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}]}}.
    {move, {integer, 3}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 17}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 17}}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 17}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {atom, false}, {x, 0}}.
    {call, 1, {f, 5}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"s">>}, {x, 0}}.
    {call, 1, {f, 5}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {float, 2.5}, {x, 0}}.
    {call, 1, {f, 5}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {call, 1, {f, 5}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 17}}.
    {move, {float, 2.0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_eq, {f, 64}, [{y, 1}, {integer, 3}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 65}}.
  {label, 64}.
    {move, {atom, false}, {x, 0}}.
  {label, 65}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_eq, {f, 66}, [{y, 1}, {integer, 2}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 67}}.
  {label, 66}.
    {move, {atom, false}, {x, 0}}.
  {label, 67}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 17}}.
    {move, {literal, <<"hi">>}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"hi">>}, {x, 0}}.
    {test, is_eq, {f, 68}, [{y, 3}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 69}}.
  {label, 68}.
    {move, {atom, false}, {x, 0}}.
  {label, 69}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 17}}.
    {move, {atom, true}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 17}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {integer, 2}, {x, 0}}.
    {test, is_number, {f, 70}, [{x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 71}}.
  {label, 70}.
    {move, {atom, false}, {x, 0}}.
  {label, 71}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {integer, 100}, {x, 0}}.
    {test, is_integer, {f, 75}, [{x, 0}]}.
    {jump, {f, 74}}.
  {label, 75}.
    {test, is_float, {f, 72}, [{x, 0}]}.
    {gc_bif, trunc, {f, 0}, 1, [{x, 0}], {x, 1}}.
    {test, is_eq, {f, 72}, [{x, 0}, {x, 1}]}.
  {label, 74}.
    {test, is_ge, {f, 72}, [{x, 0}, {integer, -128}]}.
    {test, is_ge, {f, 72}, [{integer, 127}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 73}}.
  {label, 72}.
    {move, {atom, false}, {x, 0}}.
  {label, 73}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {integer, 300}, {x, 0}}.
    {test, is_integer, {f, 79}, [{x, 0}]}.
    {jump, {f, 78}}.
  {label, 79}.
    {test, is_float, {f, 76}, [{x, 0}]}.
    {gc_bif, trunc, {f, 0}, 1, [{x, 0}], {x, 1}}.
    {test, is_eq, {f, 76}, [{x, 0}, {x, 1}]}.
  {label, 78}.
    {test, is_ge, {f, 76}, [{x, 0}, {integer, -128}]}.
    {test, is_ge, {f, 76}, [{integer, 127}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 77}}.
  {label, 76}.
    {move, {atom, false}, {x, 0}}.
  {label, 77}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 17}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {atom, true}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 17}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 16}.
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

{function, '__bp_priv__describe', 1, 81}.
  {label, 80}.
    {line, [{location, "test@main.erl", 6}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__describe'}, 1}.
  {label, 81}.
    {call_only, 1, {f, 3}}.

{function, '__bp_priv__show', 1, 83}.
  {label, 82}.
    {line, [{location, "test@main.erl", 7}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__show'}, 1}.
  {label, 83}.
    {call_only, 1, {f, 5}}.

{function, '__bp_print', 1, 17}.
  {label, 16}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '__bp_print'}, 1}.
  {label, 17}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 21}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 21}.
  {label, 20}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 21}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 19}}.

{function, '-bp_show_elem-', 1, 23}.
  {label, 22}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 23}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 19}}.

{function, '__bp_show', 2, 19}.
  {label, 18}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '__bp_show'}, 2}.
  {label, 19}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 31}, [{x, 0}]}.
    {test, is_eq, {f, 30}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 30}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 31}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 32}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 23}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 32}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 34}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 33}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 33}, [{x, 0}]}.
    {test, is_ne_exact, {f, 33}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 33}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 33}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 39}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 40}}.
  {label, 39}.
    {test, is_eq_exact, {f, 35}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 40}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 19}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 33}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 23}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 34}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 36}, [{x, 0}]}.
    {test, is_ne_exact, {f, 36}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 36}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 38}, [{x, 0}, {atom, undefined}]}.
  {label, 35}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 25}, 2}.
  {label, 36}.
    {move, {y, 0}, {x, 0}}.
    {test, is_function, {f, 37}, [{x, 0}]}.
    {move, {atom, arity}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, fun_info, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {call_ext, 1, {extfunc, erlang, integer_to_list, 1}}.
    {test_heap, 4, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {put_list, {literal, <<"fn/">>}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 37}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 38}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 25}.
  {label, 24}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '__bp_tagged'}, 2}.
  {label, 25}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 41}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 41}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 41}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 42}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 27}, 3}.
  {label, 42}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 27}.
  {label, 26}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '__bp_render'}, 1}.
  {label, 27}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 43}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 43}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 44}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 44}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 29}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 29}.
  {label, 28}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 29}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 19}}.
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

{function, '-bp_stringify-', 1, 46}.
  {label, 45}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '-bp_stringify-'}, 1}.
  {label, 46}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 47}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 47}.
    {test, is_integer, {f, 48}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 48}.
    {call, 1, {f, 21}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.
```

----- RUN LOG -----
```logs
number 3
text a
other
i32 f64 string bool
true false
true hi
true
false true true
[1, "a", true]
```
