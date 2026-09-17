----- SOURCE CODE -- main.bp
```botopink
#[@result]
fn maybeFail(should_fail: bool) -> @Result<i32, string> {
    if (should_fail) {
        throw "boom";
    } else {
        return 42;
    }
}
fn main() {
    val v = try maybeFail(false) catch -1;
    @print(v);
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 23}.

{function, maybeFail, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, maybeFail}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 10}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"boom">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 1}.
    return.
  {label, 10}.
    {move, {integer, 42}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 1}.
    return.

{function, main, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 5}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {'try', {y, 0}, {f, 11}}.
    {move, {atom, false}, {x, 0}}.
    {call, 1, {f, 3}}.
    {try_end, {y, 0}}.
    {test, is_tagged_tuple, {f, 12}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 13}}.
  {label, 11}.
    {try_case, {y, 0}}.
  {label, 12}.
    {move, {integer, -1}, {x, 0}}.
  {label, 13}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 15}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
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

{function, '__bp_print', 1, 15}.
  {label, 14}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '__bp_print'}, 1}.
  {label, 15}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 1, {f, 17}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '__bp_print_fmt', 1, 17}.
  {label, 16}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '__bp_print_fmt'}, 1}.
  {label, 17}.
    {test, is_nonempty_list, {f, 20}, [{x, 0}]}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {get_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 1}, {y, 0}}.
    {call, 1, {f, 19}}.
    {test, is_binary, {f, 21}, [{y, 0}]}.
    {test_heap, 6, 1}.
    {put_list, {integer, 115}, {x, 0}, {x, 0}}.
    {put_list, {integer, 116}, {x, 0}, {x, 0}}.
    {put_list, {integer, 126}, {x, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 21}.
    {test_heap, 4, 1}.
    {put_list, {integer, 112}, {x, 0}, {x, 0}}.
    {put_list, {integer, 126}, {x, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 20}.
    {move, {literal, [126, 110]}, {x, 0}}.
    return.

{function, '__bp_print_sep', 1, 19}.
  {label, 18}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '__bp_print_sep'}, 1}.
  {label, 19}.
    {test, is_nonempty_list, {f, 22}, [{x, 0}]}.
    {allocate, 0, 1}.
    {call, 1, {f, 17}}.
    {test_heap, 2, 1}.
    {put_list, {integer, 32}, {x, 0}, {x, 0}}.
    {deallocate, 0}.
    return.
  {label, 22}.
    {move, {literal, [126, 110]}, {x, 0}}.
    return.
```

----- RUN LOG -----
```logs
42
```
