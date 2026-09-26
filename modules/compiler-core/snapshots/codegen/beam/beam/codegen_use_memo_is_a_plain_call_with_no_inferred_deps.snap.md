----- SOURCE CODE -- main.bp
```botopink
val Element = type() implement @Context<Element>
fn state(initial: i32) -> @Component<Element, i32> {
    initial;
}
fn memo() -> @Component<Element, i32> {
    0;
}
fn Counter() -> @Component<Element, Element> {
    val {count, setCount} = use state(0);
    val doubled = use memo { -> return count * 2; };
    Element();
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, []}.
{attributes, []}.
{labels, 14}.

{function, state, 1, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, state}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, memo, 0, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, memo}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {move, {integer, 0}, {x, 0}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, 'Counter', 0, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, 'Counter'}, 0}.
  {label, 7}.
    {allocate, 3, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {integer, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {move, {x, 0}, {x, 1}}.
    {test, is_map, {f, 8}, [{x, 1}]}.
    {get_map_elements, {f, 10}, {x, 1}, {list, [{atom, count}, {x, 0}]}}.
  {label, 10}.
    {move, {x, 0}, {y, 0}}.
    {get_map_elements, {f, 11}, {x, 1}, {list, [{atom, setCount}, {x, 0}]}}.
  {label, 11}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 9}}.
  {label, 8}.
    {move, {atom, undefined}, {y, 0}}.
    {move, {atom, undefined}, {y, 1}}.
  {label, 9}.
    {move, {x, 1}, {x, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 13}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 1}, {x, 0}}.
    %% unresolved_call: memo/1
    {move, {literal, {unresolved_call, memo, 1}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, test@main@@Element}]}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '-Counter/0-fun-0-', 1, 13}.
  {label, 12}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-Counter/0-fun-0-'}, 1}.
  {label, 13}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {integer, 2}], {x, 0}}.
    {deallocate, 1}.
    return.
```

----- BEAM ASSEMBLY -- test@main@@Element.S
```erlang
{module, test@main@@Element}.
{exports, [{'__bp_format', 1}]}.
{attributes, []}.
{labels, 4}.

{function, '__bp_format', 1, 3}.
  {label, 2}.
    {line, [{location, "test@main@@Element.erl", 1}]}.
    {func_info, {atom, test@main@@Element}, {atom, '__bp_format'}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Element">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
