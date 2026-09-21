----- SOURCE CODE -- main.bp
```botopink
type State<T>(value: T, set: fn(next: T))
fn make() -> State<i32> { return State(value: 0, set: { n -> }); }
fn apply(s: State<i32>) -> i32 { s.set(s.value); return s.value; }
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 11}.

{function, make, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, make}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 7}, 0, 0, {x, 0}, {list, []}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, main__t__state}, {integer, 0}, {x, 0}]}}.
    {deallocate, 0}.
    return.

{function, apply, 1, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, apply}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 8}, [{x, 0}, 3, {atom, main__t__state}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 8}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 9}, [{x, 0}, 3, {atom, main__t__state}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 9}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_fun, 1}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 10}, [{x, 0}, 3, {atom, main__t__state}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 10}.
    {deallocate, 1}.
    return.

{function, '-make/0-fun-0-', 1, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '-make/0-fun-0-'}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.
```

----- BEAM ASSEMBLY -- main__t__state.S
```erlang
{module, main__t__state}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 8}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "main__t__state.erl", 1}]}.
    {func_info, {atom, main__t__state}, {atom, '__bp_get'}, 2}.
  {label, 3}.
    {test, is_eq_exact, {f, 4}, [{x, 1}, {atom, value}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 4}.
    {test, is_eq_exact, {f, 5}, [{x, 1}, {atom, set}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 5}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 7}.
  {label, 6}.
    {line, [{location, "main__t__state.erl", 1}]}.
    {func_info, {atom, main__t__state}, {atom, '__bp_format'}, 1}.
  {label, 7}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"set">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"value">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"State">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
