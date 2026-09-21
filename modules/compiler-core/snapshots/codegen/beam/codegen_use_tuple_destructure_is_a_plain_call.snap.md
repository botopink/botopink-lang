----- SOURCE CODE -- main.bp
```botopink
val Element = type implement @Context<Element, Element> { }
fn state(initial: i32) -> @Context<Element, i32> {
    initial;
}
#[@context]
fn Counter() -> Element {
    val #(count, setCount) = use state(0);
    Element();
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 6}.

{function, state, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, state}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, 'Counter', 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, 'Counter'}, 0}.
  {label, 5}.
    {allocate, 3, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {integer, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, main__t__element}]}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.
```

----- BEAM ASSEMBLY -- main__t__element.S
```erlang
{module, main__t__element}.
{exports, [{'__bp_format', 1}]}.
{attributes, []}.
{labels, 4}.

{function, '__bp_format', 1, 3}.
  {label, 2}.
    {line, [{location, "main__t__element.erl", 1}]}.
    {func_info, {atom, main__t__element}, {atom, '__bp_format'}, 1}.
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
