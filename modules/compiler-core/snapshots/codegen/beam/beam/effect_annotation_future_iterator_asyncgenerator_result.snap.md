----- SOURCE CODE -- main.bp
```botopink
#[@future]
fn fetch(x: i32) -> @Future<i32> {
    return x;
}
#[@iterator]
fn counter() -> @Iterator<i32> {
    yield 1;
    yield 2;
}
#[@asyncGenerator]
fn stream() -> @AsyncIterator<i32, string> {
    yield 1;
}
#[@result]
fn parse(n: i32) -> @Result<i32, string> {
    if (n < 0) { throw "negative"; };
    return n;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 11}.

%% *fn (async/generator) — eager lowering
{function, fetch, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, fetch}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {deallocate, 0}.
    return.

%% *fn (async/generator) — eager lowering
{function, counter, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, counter}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {move, {integer, 1}, {x, 0}}.
    {deallocate, 0}.
    return.
    {move, {integer, 2}, {x, 0}}.
    {deallocate, 0}.
    return.

%% *fn (async/generator) — eager lowering
{function, stream, 0, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, stream}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {move, {integer, 1}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, parse, 1, 9}.
  {label, 8}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, parse}, 1}.
  {label, 9}.
    {allocate, 0, 1}.
    {test, is_lt, {f, 10}, [{x, 0}, {integer, 0}]}.
    {move, {literal, <<"negative">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, 3, 3}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 2}]}}.
    {deallocate, 0}.
    return.
  {label, 10}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, 3, 3}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 2}]}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
