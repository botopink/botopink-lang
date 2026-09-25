----- SOURCE CODE -- main.bp
```botopink
val Element = type implement @Context<Element> { }
fn cleanup() {
    0;
}
#[@use]
fn effect() -> @Use<Element, i32> {
    0;
}
#[@use]
fn Widget() -> @Component<Element> {
    use effect { -> cleanup(); };
    Element();
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, []}.
{attributes, []}.
{labels, 10}.

{function, cleanup, 0, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, cleanup}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {integer, 0}, {x, 0}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, effect, 0, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, effect}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {move, {integer, 0}, {x, 0}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, 'Widget', 0, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, 'Widget'}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 9}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 1}, {x, 0}}.
    %% unresolved_call: effect/1
    {move, {literal, {unresolved_call, effect, 1}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {test_heap, 2, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, test@main@@Element}]}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '-Widget/0-fun-0-', 0, 9}.
  {label, 8}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-Widget/0-fun-0-'}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {call, 0, {f, 3}}.
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
