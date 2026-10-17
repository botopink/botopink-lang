----- SOURCE CODE -- main.bp
```botopink
pub fn main() {
    val xs = [3, 1, 2];
    @print(xs.reverse());
    @print(xs.slice(1));
    @print(xs.slice(0, 2));
    @print(xs.take(2));
    @print(xs.drop(1));
    @print(xs.rest());
    @print(xs.append([9, 8]));
    @print(xs.prepend(7));
    @print(xs.indexOf(2));
    @print(xs.indexOf(5));
    @print(xs.lastIndexOf(1));
    @print(xs.contains(1));
    @print(xs.contains(8));
    @print(xs.join("-"));
    val ws = ["a", "b", "c"];
    @print(ws.reverse());
    @print(ws.join(", "));
    @print(ws.indexOf("c"));
    @print(ws.contains("z"));
    val ns = [-5, 0, 123];
    @print(ns.join("|"));
    val fs = [1.5, 2.5];
    @print(fs.reverse());
    @print(fs.indexOf(2.5));
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_priv__Array_drop', 2}, {'__bp_priv__Array_range', 2}, {'__bp_priv__Array_repeat', 2}, {'__bp_priv__Array_rest', 1}, {'__bp_priv__Array_take', 2}]}.
{attributes, []}.
{labels, 101}.

{function, 'Array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, 'Array_range'}, 2}.
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

{function, 'Array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, 'Array_repeat'}, 2}.
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
    {allocate, 9, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 23}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 23}}.
    {gc_bif, '+', {f, 0}, 0, [{integer, 0}, {integer, 1}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{integer, 2}, {integer, 0}], {x, 1}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 23}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 2}, {x, 1}}.
    {call, 2, {f, 51}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 23}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 2, {f, 53}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 23}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 55}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 23}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 8}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 9}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 23}}.
    {test_heap, 2, 0}.
    {put_list, {integer, 7}, {y, 1}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 23}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 2}, {x, 1}}.
    {move, {integer, 0}, {x, 2}}.
    {call, 3, {f, 57}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 23}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 5}, {x, 1}}.
    {move, {integer, 0}, {x, 2}}.
    {call, 3, {f, 57}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 23}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 2, {f, 61}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 23}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, member, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 23}}.
    {move, {integer, 8}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, member, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 23}}.
    {move, {literal, <<"-">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 23}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"c">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"b">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 23}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 4}, {x, 0}}.
    {call, 2, {f, 79}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 23}}.
    {move, {literal, <<"c">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 2}}.
    {call, 3, {f, 57}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 23}}.
    {move, {literal, <<"z">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, member, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 23}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {integer, 123}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {integer, -5}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, <<"|">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 6}, {x, 0}}.
    {call, 2, {f, 79}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 23}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {float, 2.5}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {float, 1.5}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 23}}.
    {move, {y, 8}, {x, 0}}.
    {move, {float, 2.5}, {x, 1}}.
    {move, {integer, 0}, {x, 2}}.
    {call, 3, {f, 57}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 23}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 9}.
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

{function, 'Array_take', 2, 51}.
  {label, 50}.
    {line, [{location, "test@main.erl", 6}]}.
    {func_info, {atom, test@main}, {atom, 'Array_take'}, 2}.
  {label, 51}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ne_exact, {f, 84}, [{y, 1}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 0, [{integer, 0}, {integer, 1}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 1}, {integer, 0}], {x, 1}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 3, {extfunc, lists, sublist, 3}, 2}.
  {label, 84}.
    {move, {integer, 0}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nthtail, 2}, 2}.

{function, 'Array_drop', 2, 53}.
  {label, 52}.
    {line, [{location, "test@main.erl", 7}]}.
    {func_info, {atom, test@main}, {atom, 'Array_drop'}, 2}.
  {label, 53}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_ne_exact, {f, 86}, [{x, 0}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 1, [{y, 1}, {integer, 1}], {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 0}, {y, 1}], {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 3, {extfunc, lists, sublist, 3}, 2}.
  {label, 86}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nthtail, 2}, 2}.

{function, 'Array_rest', 1, 55}.
  {label, 54}.
    {line, [{location, "test@main.erl", 8}]}.
    {func_info, {atom, test@main}, {atom, 'Array_rest'}, 1}.
  {label, 55}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_ne_exact, {f, 88}, [{x, 0}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 1}, {integer, 1}], {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 0}, {integer, 1}], {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 3, {extfunc, lists, sublist, 3}, 1}.
  {label, 88}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nthtail, 2}, 1}.

{function, '__bp_priv__Array_drop', 2, 92}.
  {label, 91}.
    {line, [{location, "test@main.erl", 10}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Array_drop'}, 2}.
  {label, 92}.
    {call_only, 2, {f, 53}}.

{function, '__bp_priv__Array_range', 2, 94}.
  {label, 93}.
    {line, [{location, "test@main.erl", 11}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Array_range'}, 2}.
  {label, 94}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__Array_repeat', 2, 96}.
  {label, 95}.
    {line, [{location, "test@main.erl", 12}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Array_repeat'}, 2}.
  {label, 96}.
    {call_only, 2, {f, 5}}.

{function, '__bp_priv__Array_rest', 1, 98}.
  {label, 97}.
    {line, [{location, "test@main.erl", 13}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Array_rest'}, 1}.
  {label, 98}.
    {call_only, 1, {f, 55}}.

{function, '__bp_priv__Array_take', 2, 100}.
  {label, 99}.
    {line, [{location, "test@main.erl", 14}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Array_take'}, 2}.
  {label, 100}.
    {call_only, 2, {f, 51}}.

{function, '__bp_print', 1, 23}.
  {label, 22}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_print'}, 1}.
  {label, 23}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 27}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 27}.
  {label, 26}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 27}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 25}}.

{function, '-bp_show_elem-', 1, 29}.
  {label, 28}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 29}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 25}}.

{function, '__bp_show', 2, 25}.
  {label, 24}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_show'}, 2}.
  {label, 25}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 37}, [{x, 0}]}.
    {test, is_eq, {f, 36}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 36}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 37}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 38}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 29}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 38}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 40}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 39}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 39}, [{x, 0}]}.
    {test, is_ne_exact, {f, 39}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 39}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 39}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 44}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 45}}.
  {label, 44}.
    {test, is_eq_exact, {f, 41}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 45}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 25}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 39}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 29}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 40}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 42}, [{x, 0}]}.
    {test, is_ne_exact, {f, 42}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 42}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 43}, [{x, 0}, {atom, undefined}]}.
  {label, 41}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 31}, 2}.
  {label, 42}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 43}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 31}.
  {label, 30}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_tagged'}, 2}.
  {label, 31}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 46}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 46}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 46}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 47}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 33}, 3}.
  {label, 47}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 33}.
  {label, 32}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_render'}, 1}.
  {label, 33}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 48}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 48}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 49}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 49}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 35}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 35}.
  {label, 34}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 35}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 25}}.
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

{function, '-bp_indexOf-', 3, 57}.
  {label, 56}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-bp_indexOf-'}, 3}.
  {label, 57}.
    {test, is_nonempty_list, {f, 58}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 3}, {x, 4}}.
    {test, is_eq, {f, 59}, [{x, 3}, {x, 1}]}.
    {move, {x, 2}, {x, 0}}.
    return.
  {label, 59}.
    {move, {x, 4}, {x, 0}}.
    {gc_bif, '+', {f, 0}, 3, [{x, 2}, {integer, 1}], {x, 2}}.
    {call_only, 3, {f, 57}}.
  {label, 58}.
    {move, {integer, -1}, {x, 0}}.
    return.

{function, '__bp_tpl_0--t/2-fun-0--fun-1-', 4, 69}.
  {label, 68}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0--t/2-fun-0--fun-1-'}, 4}.
  {label, 69}.
    {allocate, 11, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {x, 2}, {y, 5}}.
    {move, {x, 3}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 69}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nonempty_list, {f, 71}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 6}, {y, 7}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {y, 2}}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 73}, [{x, 0}, {atom, true}]}.
    {move, {y, 3}, {y, 10}}.
    {jump, {f, 72}}.
  {label, 73}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 74}, [{x, 0}, {atom, false}]}.
    {move, {y, 5}, {y, 10}}.
    {jump, {f, 72}}.
  {label, 74}.
    {move, {y, 9}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 72}.
    {move, {y, 8}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {y, 10}, {x, 2}}.
    {move, {y, 0}, {x, 3}}.
    {call_last, 4, {f, 69}, 11}.
  {label, 71}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 75}, [{x, 0}, nil]}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 75}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {y, 5}, {x, 2}}.
    {move, {y, 0}, {x, 3}}.
    {deallocate, 11}.
    {jump, {f, 68}}.

{function, '__bp_tpl_0-t/2-fun-0-', 2, 65}.
  {label, 64}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0-t/2-fun-0-'}, 2}.
  {label, 65}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 69}, 0, 0, {x, 0}, {list, [{y, 2}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 77}}.
  {label, 77}.
    {move, {integer, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {integer, -1}, {x, 2}}.
    {move, {y, 0}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_0', 2, 61}.
  {label, 60}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0'}, 2}.
  {label, 61}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 65}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '-bp_stringify-', 1, 81}.
  {label, 80}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-bp_stringify-'}, 1}.
  {label, 81}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 82}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 82}.
    {test, is_integer, {f, 83}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 83}.
    {call, 1, {f, 27}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '-bp_join-', 2, 79}.
  {label, 78}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-bp_join-'}, 2}.
  {label, 79}.
    {allocate, 1, 2}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 81}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 1}.

{function, '__bp_prim_append', 2, 17}.
  {label, 16}.
    {line, [{location, "test@main.erl", 9}]}.
    {func_info, {atom, test@main}, {atom, '__bp_prim_append'}, 2}.
  {label, 17}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 90}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 2}.
  {label, 90}.
    %% unresolved_method: append/2
    {move, {literal, {unresolved_method, append, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
[2, 1, 3]
[1, 2]
[3, 1]
[3, 1]
[1, 2]
[1, 2]
[3, 1, 2, 9, 8]
[7, 3, 1, 2]
2
-1
1
true
false
3-1-2
["c", "b", "a"]
a, b, c
2
false
-5|0|123
[2.5, 1.5]
1
```
