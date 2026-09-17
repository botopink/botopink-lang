----- SOURCE CODE -- main.bp
```botopink
#[@future]
fn fetch(x: i32) -> @Future<i32> {
    return x;
}
#[@future]
fn loadTwice(x: i32) -> @Future<i32> {
    val a = await fetch(x);
    return a + a;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 6}.

%% #[@future] / #[@asyncGenerator] — eager lowering
{function, fetch, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, fetch}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

%% #[@future] / #[@asyncGenerator] — eager lowering
{function, loadTwice, 1, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, loadTwice}, 1}.
  {label, 5}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {y, 1}], {x, 0}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
