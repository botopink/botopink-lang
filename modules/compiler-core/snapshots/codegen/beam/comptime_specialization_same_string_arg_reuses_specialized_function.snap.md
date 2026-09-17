----- SOURCE CODE -- main.bp
```botopink
fn build(comptime prefix: string, name: string) -> string {
    return prefix + ": " + name;
}

fn main() {
    val r1 = build("INFO", "Sistema iniciado");
    val r2 = build("INFO", "Log replicado");
    @print(r1);
    @print(r2);
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 23}.

{function, main, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 3}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {literal, <<"Sistema iniciado">>}, {x, 0}}.
    {call, 1, {f, 5}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"Log replicado">>}, {x, 0}}.
    {call, 1, {f, 5}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 11}}.
    {move, {y, 1}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 11}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, 'build_$0', 1, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, 'build_$0'}, 1}.
  {label, 5}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"INFO">>}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<": ">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 20}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 3}.
    return.

{function, '_botopink_main', 0, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '_botopink_main'}, 0}.
  {label, 7}.
    {call_only, 0, {f, 3}}.

{function, main, 1, 9}.
  {label, 8}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, main}, 1}.
  {label, 9}.
    {call_only, 0, {f, 7}}.

{function, '__bp_print', 1, 11}.
  {label, 10}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '__bp_print'}, 1}.
  {label, 11}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 1, {f, 13}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '__bp_print_fmt', 1, 13}.
  {label, 12}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '__bp_print_fmt'}, 1}.
  {label, 13}.
    {test, is_nonempty_list, {f, 16}, [{x, 0}]}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {get_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 1}, {y, 0}}.
    {call, 1, {f, 15}}.
    {test, is_binary, {f, 17}, [{y, 0}]}.
    {test_heap, 6, 1}.
    {put_list, {integer, 115}, {x, 0}, {x, 0}}.
    {put_list, {integer, 116}, {x, 0}, {x, 0}}.
    {put_list, {integer, 126}, {x, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 17}.
    {test_heap, 4, 1}.
    {put_list, {integer, 112}, {x, 0}, {x, 0}}.
    {put_list, {integer, 126}, {x, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 16}.
    {move, {literal, [126, 110]}, {x, 0}}.
    return.

{function, '__bp_print_sep', 1, 15}.
  {label, 14}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '__bp_print_sep'}, 1}.
  {label, 15}.
    {test, is_nonempty_list, {f, 18}, [{x, 0}]}.
    {allocate, 0, 1}.
    {call, 1, {f, 13}}.
    {test_heap, 2, 1}.
    {put_list, {integer, 32}, {x, 0}, {x, 0}}.
    {deallocate, 0}.
    return.
  {label, 18}.
    {move, {literal, [126, 110]}, {x, 0}}.
    return.

{function, '-bp_stringify-', 1, 20}.
  {label, 19}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '-bp_stringify-'}, 1}.
  {label, 20}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 21}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 21}.
    {test, is_integer, {f, 22}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 22}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 0}.
```

----- RUN LOG -----
```logs
INFO: Sistema iniciado
INFO: Log replicado
```
