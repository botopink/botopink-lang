----- SOURCE CODE -- main.bp
```botopink
type DbError(msg: string)
#[@result]
fn inner() -> @Result<i32, DbError> {
    throw DbError(msg: "conn refused");
}
#[@result]
fn outer() -> @Result<i32, DbError> {
    throw DbError(msg: "timeout");
}
fn process() -> i32 {
    val a = try inner() catch 0;
    val b = try outer() catch a;
    @print(a, b);
    return a + b;
}
fn main() {
    @print(process());
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 32}.

{function, inner, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, inner}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {literal, <<"conn refused">>}, {x, 0}}.
    {put_map_assoc, {f, 0}, {literal, #{}}, {x, 0}, 1, {list, [{atom, msg}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, outer, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, outer}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {move, {literal, <<"timeout">>}, {x, 0}}.
    {put_map_assoc, {f, 0}, {literal, #{}}, {x, 0}, 1, {list, [{atom, msg}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, process, 0, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, process}, 0}.
  {label, 7}.
    {allocate, 5, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {'try', {y, 0}, {f, 14}}.
    {call, 0, {f, 3}}.
    {try_end, {y, 0}}.
    {test, is_tagged_tuple, {f, 15}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 16}}.
  {label, 14}.
    {try_case, {y, 0}}.
  {label, 15}.
    {move, {integer, 0}, {x, 0}}.
  {label, 16}.
    {move, {x, 0}, {y, 1}}.
    {'try', {y, 2}, {f, 17}}.
    {call, 0, {f, 5}}.
    {try_end, {y, 2}}.
    {test, is_tagged_tuple, {f, 18}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 19}}.
  {label, 17}.
    {try_case, {y, 2}}.
  {label, 18}.
    {move, {y, 1}, {x, 0}}.
  {label, 19}.
    {move, {x, 0}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call, 2, {f, 30}}.
    {deallocate, 5}.
    return.

{function, main, 0, 9}.
  {label, 8}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {call, 0, {f, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 11}.
  {label, 10}.
    {line, [{location, "main.erl", 5}]}.
    {func_info, {atom, main}, {atom, '_botopink_main'}, 0}.
  {label, 11}.
    {call_only, 0, {f, 9}}.

{function, main, 1, 13}.
  {label, 12}.
    {line, [{location, "main.erl", 6}]}.
    {func_info, {atom, main}, {atom, main}, 1}.
  {label, 13}.
    {call_only, 0, {f, 11}}.

{function, '__bp_print', 1, 21}.
  {label, 20}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '__bp_print'}, 1}.
  {label, 21}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 1, {f, 23}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '__bp_print_fmt', 1, 23}.
  {label, 22}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '__bp_print_fmt'}, 1}.
  {label, 23}.
    {test, is_nonempty_list, {f, 26}, [{x, 0}]}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {get_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 1}, {y, 0}}.
    {call, 1, {f, 25}}.
    {test, is_binary, {f, 27}, [{y, 0}]}.
    {test_heap, 6, 1}.
    {put_list, {integer, 115}, {x, 0}, {x, 0}}.
    {put_list, {integer, 116}, {x, 0}, {x, 0}}.
    {put_list, {integer, 126}, {x, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 27}.
    {test_heap, 4, 1}.
    {put_list, {integer, 112}, {x, 0}, {x, 0}}.
    {put_list, {integer, 126}, {x, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 26}.
    {move, {literal, [126, 110]}, {x, 0}}.
    return.

{function, '__bp_print_sep', 1, 25}.
  {label, 24}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '__bp_print_sep'}, 1}.
  {label, 25}.
    {test, is_nonempty_list, {f, 28}, [{x, 0}]}.
    {allocate, 0, 1}.
    {call, 1, {f, 23}}.
    {test_heap, 2, 1}.
    {put_list, {integer, 32}, {x, 0}, {x, 0}}.
    {deallocate, 0}.
    return.
  {label, 28}.
    {move, {literal, [126, 110]}, {x, 0}}.
    return.

{function, '__bp_add', 2, 30}.
  {label, 29}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '__bp_add'}, 2}.
  {label, 30}.
    {test, is_binary, {f, 31}, [{x, 0}]}.
    {test, is_binary, {f, 31}, [{x, 1}]}.
    {test_heap, 4, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call_ext_only, 1, {extfunc, erlang, iolist_to_binary, 1}}.
  {label, 31}.
    {gc_bif, '+', {f, 0}, 2, [{x, 0}, {x, 1}], {x, 0}}.
    return.
```

----- RUN LOG -----
```logs
0 0
0
```
