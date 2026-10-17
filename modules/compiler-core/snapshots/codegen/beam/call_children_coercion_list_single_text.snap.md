----- SOURCE CODE -- main.bp
```botopink
fn node() -> string { return "n"; }
fn box(children: Children) -> string { return "x"; }
val many = box([node(), node()]);
val one = box(node());
val txt = box("hi");
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'_botopink_init', 0}, {'__bp_priv__box', 1}, {'__bp_priv__many', 0}, {'__bp_priv__node', 0}, {'__bp_priv__one', 0}, {'__bp_priv__txt', 0}]}.
{attributes, []}.
{labels, 27}.

{function, node, 0, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, node}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {literal, <<"n">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, box, 1, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, box}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"x">>}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, many, 0, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, many}, 0}.
  {label, 7}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {literal, {test@main, many}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 14}, [{x, 0}, {atom, '$bp_unset'}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 3}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 3}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 5}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {test@main, many}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 1}, {x, 0}}.
  {label, 14}.
    {deallocate, 2}.
    return.

{function, one, 0, 9}.
  {label, 8}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, one}, 0}.
  {label, 9}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {test@main, one}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 15}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 3}}.
    {call, 1, {f, 5}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {test@main, one}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 15}.
    {deallocate, 1}.
    return.

{function, txt, 0, 11}.
  {label, 10}.
    {line, [{location, "test@main.erl", 5}]}.
    {func_info, {atom, test@main}, {atom, txt}, 0}.
  {label, 11}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {test@main, txt}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 16}, [{x, 0}, {atom, '$bp_unset'}]}.
    {move, {literal, <<"hi">>}, {x, 0}}.
    {call, 1, {f, 5}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {test@main, txt}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 16}.
    {deallocate, 1}.
    return.

{function, '_botopink_init', 0, 13}.
  {label, 12}.
    {line, [{location, "test@main.erl", 6}]}.
    {func_info, {atom, test@main}, {atom, '_botopink_init'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {call, 0, {f, 7}}.
    {call, 0, {f, 9}}.
    {call, 0, {f, 11}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_priv__box', 1, 18}.
  {label, 17}.
    {line, [{location, "test@main.erl", 7}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__box'}, 1}.
  {label, 18}.
    {call_only, 1, {f, 5}}.

{function, '__bp_priv__many', 0, 20}.
  {label, 19}.
    {line, [{location, "test@main.erl", 8}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__many'}, 0}.
  {label, 20}.
    {call_only, 0, {f, 7}}.

{function, '__bp_priv__node', 0, 22}.
  {label, 21}.
    {line, [{location, "test@main.erl", 9}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__node'}, 0}.
  {label, 22}.
    {call_only, 0, {f, 3}}.

{function, '__bp_priv__one', 0, 24}.
  {label, 23}.
    {line, [{location, "test@main.erl", 10}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__one'}, 0}.
  {label, 24}.
    {call_only, 0, {f, 9}}.

{function, '__bp_priv__txt', 0, 26}.
  {label, 25}.
    {line, [{location, "test@main.erl", 11}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__txt'}, 0}.
  {label, 26}.
    {call_only, 0, {f, 11}}.
```

----- RUN LOG -----
```logs
```
