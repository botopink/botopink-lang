----- SOURCE CODE -- main.bp
```botopink
val Element = type() implement @Context<Element>
fn render() -> Element {
    return Element();
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, []}.
{attributes, []}.
{labels, 4}.

{function, render, 0, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, render}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {test_heap, 2, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, test@main@@Element}]}}.
    {deallocate, 0}.
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
