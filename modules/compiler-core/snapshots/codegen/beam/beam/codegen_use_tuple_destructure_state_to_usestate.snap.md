----- SOURCE CODE -- main.bp
```botopink
val Element = struct implement @Context<Element, Element> { }
fn state(initial: i32) -> @Context<Element, i32> {
    initial;
}
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
    {allocate, 0, 1}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, 'Counter', 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, 'Counter'}, 0}.
  {label, 5}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {integer, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {get_tuple_element, {x, 0}, 0, {x, 1}}.
    {move, {x, 1}, {y, 0}}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, #{}}, {x, 0}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
