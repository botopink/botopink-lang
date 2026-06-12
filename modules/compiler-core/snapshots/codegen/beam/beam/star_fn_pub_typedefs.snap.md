----- SOURCE CODE -- main.bp
```botopink
#[@future]
pub fn loadOne(x: i32) -> @Future<i32> {
    return x;
}
#[@iterator]
pub fn count() -> @Iterator<i32> {
    yield 1;
}
#[@asyncGenerator]
pub fn pulses() -> @AsyncIterator<i32, string> {
    yield 1;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{loadOne, 1}, {count, 0}, {pulses, 0}]}.
{attributes, []}.
{labels, 8}.

%% #[@future] / #[@asyncGenerator] — eager lowering
{function, loadOne, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, loadOne}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {deallocate, 0}.
    return.

%% #[@future] / #[@asyncGenerator] — eager lowering
{function, count, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, count}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {move, {integer, 1}, {x, 0}}.
    {deallocate, 0}.
    return.

%% #[@future] / #[@asyncGenerator] — eager lowering
{function, pulses, 0, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, pulses}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {move, {integer, 1}, {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
