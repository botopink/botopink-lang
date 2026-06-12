----- SOURCE CODE -- main.bp
```botopink
val E = struct implement @Context<E, E> { tag: string, n: i32 }
fn mk() -> E {
    return E(tag: "x", n: 5);
}
fn main() {
    @print(mk().n);
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 11}.

{function, mk, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, mk}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {literal, <<"x">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 5}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {put_map_assoc, {f, 0}, {literal, #{}}, {x, 0}, 3, {list, [{atom, tag}, {x, 1}, {atom, n}, {x, 2}]}}.
    {deallocate, 0}.
    return.

{function, main, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {call, 0, {f, 3}}.
    {test, is_map, {f, 10}, [{x, 0}]}.
    {get_map_elements, {f, 10}, {x, 0}, {list, [{atom, n}, {x, 0}]}}.
  {label, 10}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '_botopink_main'}, 0}.
  {label, 7}.
    {call_only, 0, {f, 5}}.

{function, main, 1, 9}.
  {label, 8}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, main}, 1}.
  {label, 9}.
    {call_only, 0, {f, 7}}.
```

----- RUN LOG -----
```logs
5
```
