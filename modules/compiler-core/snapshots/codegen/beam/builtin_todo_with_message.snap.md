----- SOURCE CODE -- main.bp
```botopink
fn notImplemented() -> void {
    panic("implement this function");
}

import {failure.panic} from "std";
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'__bp_priv__notImplemented', 0}]}.
{attributes, []}.
{labels, 6}.

{function, notImplemented, 0, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, notImplemented}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {literal, <<"implement this function">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_priv__notImplemented', 0, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__notImplemented'}, 0}.
  {label, 5}.
    {call_only, 0, {f, 3}}.
```

----- RUN LOG -----
```logs
```
