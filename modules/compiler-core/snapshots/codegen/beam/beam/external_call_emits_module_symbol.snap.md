----- SOURCE CODE -- main.bp
```botopink
#[@external(erlang, "string", "length"),
  @external(node, "./gleam_stdlib.mjs", "string_length")]
pub declare fn str_length(s: string) -> i32;

fn main() {
    @print(str_length("hello"));
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {str_length, 1}]}.
{attributes, []}.
{labels, 10}.

{function, str_length, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, str_length}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, main, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {move, {literal, <<"hello">>}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
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
ok
```
