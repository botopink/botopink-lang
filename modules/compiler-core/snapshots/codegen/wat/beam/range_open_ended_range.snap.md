----- SOURCE CODE -- main.bp
```botopink
fn countUp(x: i32) {
    for (x..) { i ->
        if (i > 100) {
          break;
        };
    };
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, []}.
{attributes, []}.
{labels, 11}.

{function, countUp, 1, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, countUp}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, infinity}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, seq, 2}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 5}, 0, 0, {x, 0}, {list, []}}.
    {'try', {y, 1}, {f, 8}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {try_end, {y, 1}}.
    {jump, {f, 10}}.
  {label, 8}.
    {try_case, {y, 1}}.
    {test, is_eq_exact, {f, 9}, [{x, 0}, {atom, throw}]}.
    {test, is_tagged_tuple, {f, 9}, [{x, 1}, 2, {atom, '__bp_break'}]}.
    {get_tuple_element, {x, 1}, 1, {x, 0}}.
    {jump, {f, 10}}.
  {label, 9}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.
  {label, 10}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-countUp/1-fun-0-', 1, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '-countUp/1-fun-0-'}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_lt, {f, 6}, [{integer, 100}, {y, 0}]}.
    {move, {atom, ok}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, '__bp_break'}, {x, 0}]}}.
    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.
    {jump, {f, 7}}.
  {label, 6}.
  {label, 7}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.
```

----- RUN LOG -----
```logs
```
