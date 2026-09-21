----- SOURCE CODE -- main.bp
```botopink
val Counter = type(
    count: i32 = 0) {
    fn inc() {
        self.count += 1;
    }
};
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 2}.
```

----- BEAM ASSEMBLY -- main__t__counter.S
```erlang
{module, main__t__counter}.
{exports, [{inc, 1}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 10}.

{function, inc, 1, 3}.
  {label, 2}.
    {line, [{location, "main__t__counter.erl", 1}]}.
    {func_info, {atom, main__t__counter}, {atom, inc}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 4}, [{x, 0}, 2, {atom, main__t__counter}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 4}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 2}}.
    {move, {atom, count}, {x, 0}}.
    {call_ext, 3, {extfunc, maps, update, 3}}.
    {move, {x, 0}, {y, 0}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_get', 2, 6}.
  {label, 5}.
    {line, [{location, "main__t__counter.erl", 2}]}.
    {func_info, {atom, main__t__counter}, {atom, '__bp_get'}, 2}.
  {label, 6}.
    {test, is_eq_exact, {f, 7}, [{x, 1}, {atom, count}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 7}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 9}.
  {label, 8}.
    {line, [{location, "main__t__counter.erl", 2}]}.
    {func_info, {atom, main__t__counter}, {atom, '__bp_format'}, 1}.
  {label, 9}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"count">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Counter">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
