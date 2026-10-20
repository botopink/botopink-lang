----- SOURCE CODE -- main.bp
```botopink
fn calc(factor: i32, f: fn(i32, i32) -> i32) -> i32 {
    panic("not implemented");
}
fn main() -> void {
    val r = calc(2) { a, b ->
        return 0;
    };
}

import {failure.panic} from "std";
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {'__bp_priv__calc', 2}, {'__bp_priv__main', 0}]}.
{attributes, []}.
{labels, 16}.

{function, calc, 2, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, calc}, 2}.
  {label, 3}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"not implemented">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, main, 0, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, main}, 0}.
  {label, 5}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 11}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 0}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '_botopink_main', 0, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '_botopink_main'}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 5}, 0}.

{function, main, 1, 9}.
  {label, 8}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, main}, 1}.
  {label, 9}.
    {call_only, 0, {f, 7}}.

{function, '__bp_priv__calc', 2, 13}.
  {label, 12}.
    {line, [{location, "test@main.erl", 5}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__calc'}, 2}.
  {label, 13}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__main', 0, 15}.
  {label, 14}.
    {line, [{location, "test@main.erl", 6}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__main'}, 0}.
  {label, 15}.
    {call_only, 0, {f, 5}}.

{function, '-main/0-fun-0-', 2, 11}.
  {label, 10}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '-main/0-fun-0-'}, 2}.
  {label, 11}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
