----- SOURCE CODE -- main.bp
```botopink
val Element = struct implement @Context<Element, Element> { }
fn state(initial: i32) -> @Context<Element, i32> {
    initial;
}
fn memo() -> @Context<Element, i32> {
    0;
}
fn Counter() -> Element {
    val {count, setCount} = use state(0);
    val doubled = use memo { -> return count * 2; };
    Element();
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 12}.

{function, state, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, state}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, memo, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, memo}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {move, {integer, 0}, {x, 0}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, 'Counter', 0, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, 'Counter'}, 0}.
  {label, 7}.
    {allocate, 3, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {integer, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {move, {x, 0}, {x, 0}}.
    {get_map_elements, {f, 8}, {x, 0}, {list, [{atom, count}, {x, 0}]}}.
  {label, 8}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {get_map_elements, {f, 9}, {x, 0}, {list, [{atom, setCount}, {x, 0}]}}.
  {label, 9}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 0}, {x, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 11}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 0}}.
    {call, 0, {f, 5}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, #{}}, {x, 0}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '-Counter/0-fun-0-', 0, 11}.
  {label, 10}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '-Counter/0-fun-0-'}, 0}.
  {label, 11}.
    {allocate, 0, 0}.
    {move, {atom, count}, {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {integer, 2}], {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
