----- SOURCE CODE -- main.bp
```botopink
val ErrorKind = enum { NotFound, Timeout }
fn fetch() -> @Result(i32, ErrorKind) {
    throw ErrorKind.NotFound;
}
fn handle() -> i32 {
    val r = try fetch() catch 0;
    return r;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 9}.

{function, fetch, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, fetch}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {atom, ErrorKind}, {x, 0}}.
    {get_map_elements, {f, 6}, {x, 0}, {list, [{atom, NotFound}, {x, 0}]}}.
  {label, 6}.
    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.

{function, handle, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, handle}, 0}.
  {label, 5}.
    {allocate, 1, 0}.
    {try, {y, 0}, {f, 7}}.
    {call, 0, {f, 3}}.
    {try_end, {y, 0}}.
    {jump, {f, 8}}.
  {label, 7}.
    {try_case, {y, 0}}.
    {move, {integer, 0}, {x, 0}}.
  {label, 8}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 1}.
    return.
```

----- RUN LOG -----
```logs
```
