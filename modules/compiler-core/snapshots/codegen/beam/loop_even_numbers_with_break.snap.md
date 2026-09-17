----- SOURCE CODE -- main.bp
```botopink
val processamento = loop (0..10) { i ->
    if (i % 2 == 0) {
        break i;
    };
};
fn main() {
    @print(processamento);
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 22}.

{function, processamento, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, processamento}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {gc_bif, '-', {f, 0}, 0, [{integer, 10}, {integer, 1}], {x, 1}}.
    {move, {integer, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, seq, 2}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 11}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, filtermap, 2}}.
    {deallocate, 0}.
    return.

{function, main, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {call, 0, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 14}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '_botopink_main'}, 0}.
  {label, 7}.
    {call_only, 0, {f, 5}}.

{function, main, 1, 9}.
  {label, 8}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, main}, 1}.
  {label, 9}.
    {call_only, 0, {f, 7}}.

{function, '-/0-fun-0-', 1, 11}.
  {label, 10}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '-/0-fun-0-'}, 1}.
  {label, 11}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 0}, {integer, 2}], {x, 0}}.
    {test, is_eq, {f, 12}, [{x, 0}, {integer, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, true}, {x, 1}]}}.
    {deallocate, 1}.
    return.
  {label, 12}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_print', 1, 14}.
  {label, 13}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '__bp_print'}, 1}.
  {label, 14}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 1, {f, 16}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '__bp_print_fmt', 1, 16}.
  {label, 15}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '__bp_print_fmt'}, 1}.
  {label, 16}.
    {test, is_nonempty_list, {f, 19}, [{x, 0}]}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {get_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 1}, {y, 0}}.
    {call, 1, {f, 18}}.
    {test, is_binary, {f, 20}, [{y, 0}]}.
    {test_heap, 6, 1}.
    {put_list, {integer, 115}, {x, 0}, {x, 0}}.
    {put_list, {integer, 116}, {x, 0}, {x, 0}}.
    {put_list, {integer, 126}, {x, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 20}.
    {test_heap, 4, 1}.
    {put_list, {integer, 112}, {x, 0}, {x, 0}}.
    {put_list, {integer, 126}, {x, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 19}.
    {move, {literal, [126, 110]}, {x, 0}}.
    return.

{function, '__bp_print_sep', 1, 18}.
  {label, 17}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '__bp_print_sep'}, 1}.
  {label, 18}.
    {test, is_nonempty_list, {f, 21}, [{x, 0}]}.
    {allocate, 0, 1}.
    {call, 1, {f, 16}}.
    {test_heap, 2, 1}.
    {put_list, {integer, 32}, {x, 0}, {x, 0}}.
    {deallocate, 0}.
    return.
  {label, 21}.
    {move, {literal, [126, 110]}, {x, 0}}.
    return.
```

----- RUN LOG -----
```logs
[0,2,4,6,8]
```
