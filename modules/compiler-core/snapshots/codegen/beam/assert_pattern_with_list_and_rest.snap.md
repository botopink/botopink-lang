----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val assert [first, second, ..rest] = items catch [];
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 6}.

{function, f, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, f}, 0}.
  {label, 3}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    %% unresolved identifier: items
    {move, {literal, {unresolved_identifier, items}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {test, is_nonempty_list, {f, 5}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 0}}.
    {test, is_nonempty_list, {f, 5}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    %% unresolved identifier: items
    {move, {literal, {unresolved_identifier, items}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {jump, {f, 4}}.
  {label, 5}.
    {move, nil, {x, 0}}.
    {jump, {f, 4}}.
  {label, 4}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.
```

----- RUN LOG -----
```logs
```
