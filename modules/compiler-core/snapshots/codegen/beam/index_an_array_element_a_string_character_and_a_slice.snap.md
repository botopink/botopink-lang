----- SOURCE CODE -- main.bp
```botopink
fn main() -> void {
    val xs = [10, 20, 30];
    val i = 1;
    print(xs[0]);
    print(xs[i + 1]);
    val names = ["ana", "bo"];
    print(names[1]);
    val s = "hello";
    print(s[1]);
    print(s[1..3]);
    print(s[3..]);
    print(xs[1..]);
}

import {io.terminal.print} from "std";
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {'__bp_priv__array_range', 2}, {'__bp_priv__array_repeat', 2}, {'__bp_priv__string_slice', 3}, {'__bp_priv__main', 0}]}.
{attributes, []}.
{labels, 131}.

{function, 'array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, 'array_range'}, 2}.
  {label, 3}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_ge, {f, 12}, [{integer, 0}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 13}}.
  {label, 12}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 14}, [{x, 0}, {integer, 1}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {jump, {f, 15}}.
  {label, 14}.
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
    {call, 2, {f, 17}}.
  {label, 15}.
  {label, 13}.
    {deallocate, 6}.
    return.

{function, 'array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, 'array_repeat'}, 2}.
  {label, 5}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 18}, [{integer, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 19}}.
  {label, 18}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_eq_exact, {f, 20}, [{x, 0}, {integer, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 17}}.
    {jump, {f, 21}}.
  {label, 20}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 17}}.
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
    {call, 2, {f, 17}}.
  {label, 21}.
  {label, 19}.
    {deallocate, 6}.
    return.

{function, main, 0, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, main}, 0}.
  {label, 7}.
    {allocate, 6, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 30}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 20}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 10}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 23}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 27}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 55}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 55}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 56}}.
  {label, 55}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at test@main.bp:5:16">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 56}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 23}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 27}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"bo">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"ana">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 2, {f, 23}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 27}}.
    {move, {literal, <<"hello">>}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 2, {f, 58}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 27}}.
    {move, {y, 5}, {x, 0}}.
    {move, {integer, 3}, {x, 2}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 3, {f, 81}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 27}}.
    {move, {y, 5}, {x, 0}}.
    {move, {atom, undefined}, {x, 2}}.
    {move, {integer, 3}, {x, 1}}.
    {call, 3, {f, 81}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 27}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 27}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 6}.
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

{function, 'string_slice', 3, 81}.
  {label, 80}.
    {line, [{location, "test@main.erl", 6}]}.
    {func_info, {atom, test@main}, {atom, 'string_slice'}, 3}.
  {label, 81}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test, is_ne_exact, {f, 82}, [{y, 2}, {atom, undefined}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 3, {f, 84}, 3}.
  {label, 82}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 2, {f, 106}, 3}.

{function, '__bp_priv__array_range', 2, 124}.
  {label, 123}.
    {line, [{location, "test@main.erl", 8}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__array_range'}, 2}.
  {label, 124}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__array_repeat', 2, 126}.
  {label, 125}.
    {line, [{location, "test@main.erl", 9}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__array_repeat'}, 2}.
  {label, 126}.
    {call_only, 2, {f, 5}}.

{function, '__bp_priv__string_slice', 3, 128}.
  {label, 127}.
    {line, [{location, "test@main.erl", 10}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__string_slice'}, 3}.
  {label, 128}.
    {call_only, 3, {f, 81}}.

{function, '__bp_priv__main', 0, 130}.
  {label, 129}.
    {line, [{location, "test@main.erl", 11}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__main'}, 0}.
  {label, 130}.
    {call_only, 0, {f, 7}}.

{function, '-bp_at-', 2, 23}.
  {label, 22}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-bp_at-'}, 2}.
  {label, 23}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_ge, {f, 25}, [{y, 0}, {integer, 0}]}.
    {test, is_lt, {f, 24}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 25}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 24}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 24}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_print', 1, 27}.
  {label, 26}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_print'}, 1}.
  {label, 27}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 31}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 31}.
  {label, 30}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 31}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 29}}.

{function, '-bp_show_elem-', 1, 33}.
  {label, 32}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 33}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 29}}.

{function, '__bp_show', 2, 29}.
  {label, 28}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_show'}, 2}.
  {label, 29}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 41}, [{x, 0}]}.
    {test, is_eq, {f, 40}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 40}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 41}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 42}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 33}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 42}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 44}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 43}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 43}, [{x, 0}]}.
    {test, is_ne_exact, {f, 43}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 43}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 43}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 49}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 50}}.
  {label, 49}.
    {test, is_eq_exact, {f, 45}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 50}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 29}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 43}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 33}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 44}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 46}, [{x, 0}]}.
    {test, is_ne_exact, {f, 46}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 46}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 48}, [{x, 0}, {atom, undefined}]}.
  {label, 45}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 35}, 2}.
  {label, 46}.
    {move, {y, 0}, {x, 0}}.
    {test, is_function, {f, 47}, [{x, 0}]}.
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
  {label, 47}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 48}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 35}.
  {label, 34}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_tagged'}, 2}.
  {label, 35}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 51}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 51}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 51}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 52}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 37}, 3}.
  {label, 52}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 37}.
  {label, 36}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_render'}, 1}.
  {label, 37}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 53}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 53}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 54}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 54}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 39}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 39}.
  {label, 38}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 39}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 29}}.
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

{function, '__bp_tpl_0-t/2-fun-0-', 2, 62}.
  {label, 61}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0-t/2-fun-0-'}, 2}.
  {label, 62}.
    {allocate, 8, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 0}}.
    {jump, {f, 66}}.
  {label, 66}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 68}}.
  {label, 68}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 70}, [{x, 0}, {atom, true}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 6}}.
    {jump, {f, 69}}.
  {label, 70}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 71}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {y, 6}}.
    {jump, {f, 69}}.
  {label, 71}.
    {move, {y, 5}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 69}.
    {move, {y, 6}, {y, 2}}.
    {jump, {f, 73}}.
  {label, 73}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '>=', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 74}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 5}}.
    {jump, {f, 76}}.
  {label, 74}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 75}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 5}}.
    {jump, {f, 76}}.
  {label, 75}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 6}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 76}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 78}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nth, 2}}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 8}.
  {label, 78}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 79}, [{x, 0}, {atom, false}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 79}.
    {move, {y, 5}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_0', 2, 58}.
  {label, 57}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0'}, 2}.
  {label, 58}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 62}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_1-t/3-fun-0-', 3, 88}.
  {label, 87}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_1-t/3-fun-0-'}, 3}.
  {label, 88}.
    {allocate, 9, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {x, 2}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 0}}.
    {jump, {f, 92}}.
  {label, 92}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 1}}.
    {jump, {f, 94}}.
  {label, 94}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 96}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 95}}.
  {label, 96}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 97}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 95}}.
  {label, 97}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 95}.
    {move, {y, 7}, {y, 2}}.
    {jump, {f, 99}}.
  {label, 99}.
    {move, {y, 5}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 101}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 100}}.
  {label, 101}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 102}, [{x, 0}, {atom, false}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 100}}.
  {label, 102}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 100}.
    {move, {y, 7}, {y, 1}}.
    {jump, {f, 104}}.
  {label, 104}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {y, 7}, {x, 2}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 9}.

{function, '__bp_tpl_1', 3, 84}.
  {label, 83}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_1'}, 3}.
  {label, 84}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 88}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_2-t/2-fun-0-', 2, 110}.
  {label, 109}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_2-t/2-fun-0-'}, 2}.
  {label, 110}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 114}}.
  {label, 114}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 116}}.
  {label, 116}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 118}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 117}}.
  {label, 118}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 119}, [{x, 0}, {atom, false}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 117}}.
  {label, 119}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 117}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 121}}.
  {label, 121}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 7}.

{function, '__bp_tpl_2', 2, 106}.
  {label, 105}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_2'}, 2}.
  {label, 106}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 110}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_prim_append', 2, 17}.
  {label, 16}.
    {line, [{location, "test@main.erl", 7}]}.
    {func_info, {atom, test@main}, {atom, '__bp_prim_append'}, 2}.
  {label, 17}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 122}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 2}.
  {label, 122}.
    %% unresolved_method: append/2
    {move, {literal, {unresolved_method, append, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
10
30
bo
e
el
lo
[20, 30]
```
