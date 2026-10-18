----- SOURCE CODE -- main.bp
```botopink
pub fn main() {
    val xs = [3, 1, 3, 2, 1];
    print(xs.unique());
    print(["a", "b", "a"].unique());
    print([[1, 2], [3]].flatten());
    print(xs.chunked(2));
    print(xs.sliding(3));
    print(xs.map({ x -> x * 2 }));
    print(xs.filter({ x -> x > 1 }));
    print(xs.fold(0, { acc, x -> acc + x }));
    print(xs.any({ x -> x == 2 }), xs.all({ x -> x > 0 }), xs.count({ x -> x == 3 }));
    print(["a", "bb"].map({ s -> s.length() }));
    print(xs.zip(["a", "b"]));
}

import {io.terminal.print} from "std";
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_priv__Array_all', 2}, {'__bp_priv__Array_any', 2}, {'__bp_priv__Array_chunked', 2}, {'__bp_priv__Array_count', 2}, {'__bp_priv__Array_flatten', 1}, {'__bp_priv__Array_fold', 3}, {'__bp_priv__Array_range', 2}, {'__bp_priv__Array_repeat', 2}, {'__bp_priv__Array_sliding', 2}, {'__bp_priv__Array_unique', 1}]}.
{attributes, []}.
{labels, 156}.

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
    {allocate, 11, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 3}, {x, 0}}.
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
    {call, 1, {f, 23}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"b">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 23}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 53}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 2}, {x, 1}}.
    {call, 2, {f, 55}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 3}, {x, 1}}.
    {call, 2, {f, 57}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 59}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 63}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 69}, 0, 0, {x, 0}, {list, []}}.
    {move, {integer, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call, 3, {f, 67}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 76}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 74}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 82}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 80}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 88}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 86}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"bb">>}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 92}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, <<"b">>}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 96}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 11}.
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

{function, 'Array_unique', 1, 23}.
  {label, 22}.
    {line, [{location, "test@main.erl", 6}]}.
    {func_info, {atom, test@main}, {atom, 'Array_unique'}, 1}.
  {label, 23}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 102}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, 'Array_flatten', 1, 53}.
  {label, 52}.
    {line, [{location, "test@main.erl", 7}]}.
    {func_info, {atom, test@main}, {atom, 'Array_flatten'}, 1}.
  {label, 53}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 114}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, 'Array_chunked', 2, 55}.
  {label, 54}.
    {line, [{location, "test@main.erl", 8}]}.
    {func_info, {atom, test@main}, {atom, 'Array_chunked'}, 2}.
  {label, 55}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_ge, {f, 115}, [{integer, 0}, {y, 1}]}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 115}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 3}, {integer, 1}], {x, 1}}.
    {move, {integer, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, seq, 2}}.
    {move, {y, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 117}, 0, 0, {x, 0}, {list, [{y, 1}, {y, 0}]}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, 'Array_sliding', 2, 57}.
  {label, 56}.
    {line, [{location, "test@main.erl", 9}]}.
    {func_info, {atom, test@main}, {atom, 'Array_sliding'}, 2}.
  {label, 57}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_ge, {f, 122}, [{integer, 0}, {y, 1}]}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 122}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {y, 1}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {test, is_ge, {f, 123}, [{integer, 0}, {y, 3}]}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 123}.
    {gc_bif, '-', {f, 0}, 0, [{y, 3}, {integer, 1}], {x, 1}}.
    {move, {integer, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, seq, 2}}.
    {move, {y, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 125}, 0, 0, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, 'Array_fold', 3, 67}.
  {label, 66}.
    {line, [{location, "test@main.erl", 10}]}.
    {func_info, {atom, test@main}, {atom, 'Array_fold'}, 3}.
  {label, 67}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 129}, 0, 0, {x, 0}, {list, [{y, 2}]}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, 'Array_count', 2, 74}.
  {label, 73}.
    {line, [{location, "test@main.erl", 11}]}.
    {func_info, {atom, test@main}, {atom, 'Array_count'}, 2}.
  {label, 74}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {deallocate, 2}.
    return.

{function, 'Array_all', 2, 80}.
  {label, 79}.
    {line, [{location, "test@main.erl", 12}]}.
    {func_info, {atom, test@main}, {atom, 'Array_all'}, 2}.
  {label, 80}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 2, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 130}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 131}}.
  {label, 130}.
    {move, {atom, false}, {x, 0}}.
  {label, 131}.
    {deallocate, 2}.
    return.

{function, 'Array_any', 2, 86}.
  {label, 85}.
    {line, [{location, "test@main.erl", 13}]}.
    {func_info, {atom, test@main}, {atom, 'Array_any'}, 2}.
  {label, 86}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_ne_exact, {f, 132}, [{x, 0}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 133}}.
  {label, 132}.
    {move, {atom, false}, {x, 0}}.
  {label, 133}.
    {deallocate, 2}.
    return.

{function, '__bp_priv__Array_all', 2, 137}.
  {label, 136}.
    {line, [{location, "test@main.erl", 16}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Array_all'}, 2}.
  {label, 137}.
    {call_only, 2, {f, 80}}.

{function, '__bp_priv__Array_any', 2, 139}.
  {label, 138}.
    {line, [{location, "test@main.erl", 17}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Array_any'}, 2}.
  {label, 139}.
    {call_only, 2, {f, 86}}.

{function, '__bp_priv__Array_chunked', 2, 141}.
  {label, 140}.
    {line, [{location, "test@main.erl", 18}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Array_chunked'}, 2}.
  {label, 141}.
    {call_only, 2, {f, 55}}.

{function, '__bp_priv__Array_count', 2, 143}.
  {label, 142}.
    {line, [{location, "test@main.erl", 19}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Array_count'}, 2}.
  {label, 143}.
    {call_only, 2, {f, 74}}.

{function, '__bp_priv__Array_flatten', 1, 145}.
  {label, 144}.
    {line, [{location, "test@main.erl", 20}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Array_flatten'}, 1}.
  {label, 145}.
    {call_only, 1, {f, 53}}.

{function, '__bp_priv__Array_fold', 3, 147}.
  {label, 146}.
    {line, [{location, "test@main.erl", 21}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Array_fold'}, 3}.
  {label, 147}.
    {call_only, 3, {f, 67}}.

{function, '__bp_priv__Array_range', 2, 149}.
  {label, 148}.
    {line, [{location, "test@main.erl", 22}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Array_range'}, 2}.
  {label, 149}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__Array_repeat', 2, 151}.
  {label, 150}.
    {line, [{location, "test@main.erl", 23}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Array_repeat'}, 2}.
  {label, 151}.
    {call_only, 2, {f, 5}}.

{function, '__bp_priv__Array_sliding', 2, 153}.
  {label, 152}.
    {line, [{location, "test@main.erl", 24}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Array_sliding'}, 2}.
  {label, 153}.
    {call_only, 2, {f, 57}}.

{function, '__bp_priv__Array_unique', 1, 155}.
  {label, 154}.
    {line, [{location, "test@main.erl", 25}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Array_unique'}, 1}.
  {label, 155}.
    {call_only, 1, {f, 23}}.

{function, '__bp_print', 1, 25}.
  {label, 24}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_print'}, 1}.
  {label, 25}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 29}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 29}.
  {label, 28}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 29}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 27}}.

{function, '-bp_show_elem-', 1, 31}.
  {label, 30}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 31}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 27}}.

{function, '__bp_show', 2, 27}.
  {label, 26}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_show'}, 2}.
  {label, 27}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 39}, [{x, 0}]}.
    {test, is_eq, {f, 38}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 38}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 39}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 40}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 31}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 40}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 42}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 41}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 41}, [{x, 0}]}.
    {test, is_ne_exact, {f, 41}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 41}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 41}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 46}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 47}}.
  {label, 46}.
    {test, is_eq_exact, {f, 43}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 47}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 27}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 41}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 31}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 42}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 44}, [{x, 0}]}.
    {test, is_ne_exact, {f, 44}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 44}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 45}, [{x, 0}, {atom, undefined}]}.
  {label, 43}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 33}, 2}.
  {label, 44}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 45}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 33}.
  {label, 32}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_tagged'}, 2}.
  {label, 33}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 48}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 48}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 48}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 49}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 35}, 3}.
  {label, 49}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 35}.
  {label, 34}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_render'}, 1}.
  {label, 35}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 50}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 50}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 51}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 51}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 37}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 37}.
  {label, 36}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 37}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 27}}.
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

{function, '-main/0-fun-0-', 1, 59}.
  {label, 58}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-main/0-fun-0-'}, 1}.
  {label, 59}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 60}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 60}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 61}}.
  {label, 60}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at test@main.bp:8:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 61}.
    {deallocate, 1}.
    return.

{function, '-main/0-fun-1-', 1, 63}.
  {label, 62}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-main/0-fun-1-'}, 1}.
  {label, 63}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_lt, {f, 64}, [{integer, 1}, {y, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 65}}.
  {label, 64}.
    {move, {atom, false}, {x, 0}}.
  {label, 65}.
    {deallocate, 1}.
    return.

{function, '__bp_add', 2, 71}.
  {label, 70}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_add'}, 2}.
  {label, 71}.
    {test, is_binary, {f, 72}, [{x, 0}]}.
    {test, is_binary, {f, 72}, [{x, 1}]}.
    {test_heap, 4, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call_ext_only, 1, {extfunc, erlang, iolist_to_binary, 1}}.
  {label, 72}.
    {gc_bif, '+', {f, 0}, 2, [{x, 0}, {x, 1}], {x, 0}}.
    return.

{function, '-main/0-fun-2-', 2, 69}.
  {label, 68}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-main/0-fun-2-'}, 2}.
  {label, 69}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 71}}.
    {deallocate, 2}.
    return.

{function, '-main/0-fun-3-', 1, 76}.
  {label, 75}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-main/0-fun-3-'}, 1}.
  {label, 76}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_eq_exact, {f, 77}, [{y, 0}, {integer, 3}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 78}}.
  {label, 77}.
    {move, {atom, false}, {x, 0}}.
  {label, 78}.
    {deallocate, 1}.
    return.

{function, '-main/0-fun-4-', 1, 82}.
  {label, 81}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-main/0-fun-4-'}, 1}.
  {label, 82}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_lt, {f, 83}, [{integer, 0}, {y, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 84}}.
  {label, 83}.
    {move, {atom, false}, {x, 0}}.
  {label, 84}.
    {deallocate, 1}.
    return.

{function, '-main/0-fun-5-', 1, 88}.
  {label, 87}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-main/0-fun-5-'}, 1}.
  {label, 88}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_eq_exact, {f, 89}, [{y, 0}, {integer, 2}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 90}}.
  {label, 89}.
    {move, {atom, false}, {x, 0}}.
  {label, 90}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_0', 1, 94}.
  {label, 93}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0'}, 1}.
  {label, 94}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, length, 1}, 2}.

{function, '-main/0-fun-6-', 1, 92}.
  {label, 91}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-main/0-fun-6-'}, 1}.
  {label, 92}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 94}}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_1-t/2-fun-0-', 2, 100}.
  {label, 99}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_1-t/2-fun-0-'}, 2}.
  {label, 100}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_1', 2, 96}.
  {label, 95}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_1'}, 2}.
  {label, 96}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 100}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, sublist, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, sublist, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {move, {y, 4}, {x, 2}}.
    {call_ext_last, 3, {extfunc, lists, zipwith, 3}, 5}.

{function, '-unique/2-fun-8-', 2, 107}.
  {label, 106}.
    {line, [{location, "test@main.erl", 7}]}.
    {func_info, {atom, test@main}, {atom, '-unique/2-fun-8-'}, 2}.
  {label, 107}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_eq_exact, {f, 108}, [{y, 0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 109}}.
  {label, 108}.
    {move, {atom, false}, {x, 0}}.
  {label, 109}.
    {deallocate, 2}.
    return.

{function, '-unique/1-fun-7-', 2, 102}.
  {label, 101}.
    {line, [{location, "test@main.erl", 7}]}.
    {func_info, {atom, test@main}, {atom, '-unique/1-fun-7-'}, 2}.
  {label, 102}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 107}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 105}}.
    {test, is_eq, {f, 110}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 111}}.
  {label, 110}.
    {move, {atom, true}, {x, 0}}.
  {label, 111}.
    {test, is_eq, {f, 103}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 17}}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 112}}.
  {label, 103}.
  {label, 112}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '-flatten/1-fun-9-', 2, 114}.
  {label, 113}.
    {line, [{location, "test@main.erl", 8}]}.
    {func_info, {atom, test@main}, {atom, '-flatten/1-fun-9-'}, 2}.
  {label, 114}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call, 2, {f, 17}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-chunked/2-fun-10-', 4, 117}.
  {label, 116}.
    {line, [{location, "test@main.erl", 9}]}.
    {func_info, {atom, test@main}, {atom, '-chunked/2-fun-10-'}, 4}.
  {label, 117}.
    {allocate, 7, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 0}, {y, 2}], {x, 0}}.
    {test, is_eq_exact, {f, 118}, [{x, 0}, {integer, 0}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {y, 2}], {x, 0}}.
    {test, is_ne_exact, {f, 119}, [{x, 0}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {integer, 1}], {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 0}, {y, 0}], {x, 2}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 120}}.
  {label, 119}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 120}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 17}}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 121}}.
  {label, 118}.
  {label, 121}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 7}.
    return.

{function, '-sliding/2-fun-11-', 4, 125}.
  {label, 124}.
    {line, [{location, "test@main.erl", 10}]}.
    {func_info, {atom, test@main}, {atom, '-sliding/2-fun-11-'}, 4}.
  {label, 125}.
    {allocate, 7, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {y, 3}], {x, 0}}.
    {test, is_ne_exact, {f, 126}, [{x, 0}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {integer, 1}], {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 0}, {y, 0}], {x, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 127}}.
  {label, 126}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 127}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 17}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 7}.
    return.

{function, '-fold/3-fun-12-', 3, 129}.
  {label, 128}.
    {line, [{location, "test@main.erl", 11}]}.
    {func_info, {atom, test@main}, {atom, '-fold/3-fun-12-'}, 3}.
  {label, 129}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_prim_append', 2, 17}.
  {label, 16}.
    {line, [{location, "test@main.erl", 14}]}.
    {func_info, {atom, test@main}, {atom, '__bp_prim_append'}, 2}.
  {label, 17}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 134}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 2}.
  {label, 134}.
    %% unresolved_method: append/2
    {move, {literal, {unresolved_method, append, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.

{function, '__bp_prim_any', 2, 105}.
  {label, 104}.
    {line, [{location, "test@main.erl", 15}]}.
    {func_info, {atom, test@main}, {atom, '__bp_prim_any'}, 2}.
  {label, 105}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 135}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 2, {f, 86}, 2}.
  {label, 135}.
    %% unresolved_method: any/2
    {move, {literal, {unresolved_method, any, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
[3, 1, 2]
["a", "b"]
[1, 2, 3]
[[3, 1], [3, 2], [1]]
[[3, 1, 3], [1, 3, 2], [3, 2, 1]]
[6, 2, 6, 4, 2]
[3, 3, 2]
10
true true 2
[1, 2]
[#(3, "a"), #(1, "b")]
```
