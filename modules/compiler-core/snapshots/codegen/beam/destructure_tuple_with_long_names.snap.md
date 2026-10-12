----- SOURCE CODE -- main.bp
```botopink
fn get_coordinates() -> #(f64, f64) {
    return #(0.0, 0.0);
}
fn extract_coordinates() {
    val #(longitude, latitude) = get_coordinates();
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'__bp_priv__extract_coordinates', 0}, {'__bp_priv__get_coordinates', 0}]}.
{attributes, []}.
{labels, 10}.

{function, get_coordinates, 0, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, get_coordinates}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{float, 0.0}, {float, 0.0}]}}.
    {deallocate, 0}.
    return.

{function, extract_coordinates, 0, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, extract_coordinates}, 0}.
  {label, 5}.
    {allocate, 3, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {call, 0, {f, 3}}.
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
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_priv__extract_coordinates', 0, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__extract_coordinates'}, 0}.
  {label, 7}.
    {call_only, 0, {f, 5}}.

{function, '__bp_priv__get_coordinates', 0, 9}.
  {label, 8}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__get_coordinates'}, 0}.
  {label, 9}.
    {call_only, 0, {f, 3}}.
```

----- RUN LOG -----
```logs
```
