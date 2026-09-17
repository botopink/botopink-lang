----- SOURCE CODE -- main.bp
```botopink
pub fn html(comptime q: @Expr<string>) -> @Expr<string> {
    return q;
}
val name = "world";
val page = html
    \\<div>
    \\  <p>${name}</p>
    \\</div>
;
fn main() {
    @print(page);
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 25}.

{function, name, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, name}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {literal, <<"world">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, page, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, page}, 0}.
  {label, 5}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"</p>\n</div>">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 3}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"<div>\n  <p>">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 13}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 1}.
    return.

{function, main, 0, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {call, 0, {f, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 17}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 9}.
  {label, 8}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '_botopink_main'}, 0}.
  {label, 9}.
    {call_only, 0, {f, 7}}.

{function, main, 1, 11}.
  {label, 10}.
    {line, [{location, "main.erl", 5}]}.
    {func_info, {atom, main}, {atom, main}, 1}.
  {label, 11}.
    {call_only, 0, {f, 9}}.

{function, '-bp_stringify-', 1, 13}.
  {label, 12}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '-bp_stringify-'}, 1}.
  {label, 13}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 14}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 14}.
    {test, is_integer, {f, 15}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 15}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 0}.

{function, '__bp_print', 1, 17}.
  {label, 16}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '__bp_print'}, 1}.
  {label, 17}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 1, {f, 19}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '__bp_print_fmt', 1, 19}.
  {label, 18}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '__bp_print_fmt'}, 1}.
  {label, 19}.
    {test, is_nonempty_list, {f, 22}, [{x, 0}]}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {get_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 1}, {y, 0}}.
    {call, 1, {f, 21}}.
    {test, is_binary, {f, 23}, [{y, 0}]}.
    {test_heap, 6, 1}.
    {put_list, {integer, 115}, {x, 0}, {x, 0}}.
    {put_list, {integer, 116}, {x, 0}, {x, 0}}.
    {put_list, {integer, 126}, {x, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 23}.
    {test_heap, 4, 1}.
    {put_list, {integer, 112}, {x, 0}, {x, 0}}.
    {put_list, {integer, 126}, {x, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 22}.
    {move, {literal, [126, 110]}, {x, 0}}.
    return.

{function, '__bp_print_sep', 1, 21}.
  {label, 20}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '__bp_print_sep'}, 1}.
  {label, 21}.
    {test, is_nonempty_list, {f, 24}, [{x, 0}]}.
    {allocate, 0, 1}.
    {call, 1, {f, 19}}.
    {test_heap, 2, 1}.
    {put_list, {integer, 32}, {x, 0}, {x, 0}}.
    {deallocate, 0}.
    return.
  {label, 24}.
    {move, {literal, [126, 110]}, {x, 0}}.
    return.
```

----- RUN LOG -----
```logs
<div>
  <p>world</p>
</div>
```
