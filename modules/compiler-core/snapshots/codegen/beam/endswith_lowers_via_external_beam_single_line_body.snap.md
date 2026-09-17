----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val s = "foobar";
    @print(s.endsWith("bar"));
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 17}.

{function, main, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 3}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, <<"foobar">>}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"bar">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, byte_size, {f, 0}, 2, [{x, 0}], {x, 2}}.
    {gc_bif, byte_size, {f, 0}, 3, [{x, 1}], {x, 3}}.
    {gc_bif, '-', {f, 0}, 4, [{x, 2}, {x, 3}], {x, 3}}.
    {gc_bif, abs, {f, 0}, 4, [{x, 3}], {x, 4}}.
    {gc_bif, '+', {f, 0}, 5, [{x, 3}, {x, 4}], {x, 3}}.
    {gc_bif, 'div', {f, 0}, 4, [{x, 3}, {integer, 2}], {x, 3}}.
    {gc_bif, '-', {f, 0}, 4, [{x, 2}, {x, 3}], {x, 2}}.
    {gc_bif, binary_part, {f, 0}, 4, [{x, 0}, {x, 3}, {x, 2}], {x, 0}}.
    {bif, '=:=', {f, 0}, [{x, 0}, {x, 1}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 9}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '_botopink_main', 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '_botopink_main'}, 0}.
  {label, 5}.
    {call_only, 0, {f, 3}}.

{function, main, 1, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, main}, 1}.
  {label, 7}.
    {call_only, 0, {f, 5}}.

{function, '__bp_print', 1, 9}.
  {label, 8}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '__bp_print'}, 1}.
  {label, 9}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 1, {f, 11}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '__bp_print_fmt', 1, 11}.
  {label, 10}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '__bp_print_fmt'}, 1}.
  {label, 11}.
    {test, is_nonempty_list, {f, 14}, [{x, 0}]}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {get_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 1}, {y, 0}}.
    {call, 1, {f, 13}}.
    {test, is_binary, {f, 15}, [{y, 0}]}.
    {test_heap, 6, 1}.
    {put_list, {integer, 115}, {x, 0}, {x, 0}}.
    {put_list, {integer, 116}, {x, 0}, {x, 0}}.
    {put_list, {integer, 126}, {x, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 15}.
    {test_heap, 4, 1}.
    {put_list, {integer, 112}, {x, 0}, {x, 0}}.
    {put_list, {integer, 126}, {x, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 14}.
    {move, {literal, [126, 110]}, {x, 0}}.
    return.

{function, '__bp_print_sep', 1, 13}.
  {label, 12}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '__bp_print_sep'}, 1}.
  {label, 13}.
    {test, is_nonempty_list, {f, 16}, [{x, 0}]}.
    {allocate, 0, 1}.
    {call, 1, {f, 11}}.
    {test_heap, 2, 1}.
    {put_list, {integer, 32}, {x, 0}, {x, 0}}.
    {deallocate, 0}.
    return.
  {label, 16}.
    {move, {literal, [126, 110]}, {x, 0}}.
    return.
```

----- RUN LOG -----
```logs
true
```
