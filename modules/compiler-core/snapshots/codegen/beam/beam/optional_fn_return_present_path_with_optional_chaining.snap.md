----- SOURCE CODE -- main.bp
```botopink
record R { kind: i32 }
fn pick(present: bool) -> ?R {
    if (present) {
        return R(kind: 7);
    } else {
        return null;
    }
}
fn main() {
    @print(pick(true)?.kind);
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 14}.

{function, pick, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, pick}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {test, is_eq, {f, 10}, [{x, 0}, {atom, true}]}.
    {move, {integer, 7}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {put_map_assoc, {f, 0}, {literal, #{}}, {x, 0}, 2, {list, [{atom, kind}, {x, 1}]}}.
    {deallocate, 0}.
    return.
  {label, 10}.
    {move, {atom, nil}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, main, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {move, {atom, true}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 11}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 13}}.
  {label, 11}.
    {test, is_map, {f, 12}, [{x, 0}]}.
    {get_map_elements, {f, 12}, {x, 0}, {list, [{atom, kind}, {x, 0}]}}.
    {jump, {f, 13}}.
  {label, 12}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 13}.
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
7
```
