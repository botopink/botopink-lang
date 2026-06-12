----- SOURCE CODE -- main.bp
```botopink
val Element = struct implement @Context<Element, Element> { }
fn cleanup() {
    0;
}
fn effect() -> @Context<Element, i32> {
    0;
}
fn Widget() -> Element {
    use effect { -> cleanup(); };
    Element();
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 10}.

{function, cleanup, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, cleanup}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {integer, 0}, {x, 0}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, effect, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, effect}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {move, {integer, 0}, {x, 0}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, 'Widget', 0, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, 'Widget'}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 9}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 0}}.
    {call, 0, {f, 5}}.
    {move, {literal, #{}}, {x, 0}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '-Widget/0-fun-0-', 0, 9}.
  {label, 8}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '-Widget/0-fun-0-'}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {call, 0, {f, 3}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
