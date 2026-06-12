----- SOURCE CODE -- main.bp
```botopink
fn abs(n: i32) -> i32 {
    val result = if (n < 0) -n else n;
    return result;
}
fn main() {
    @print(abs(-5));
    @print(abs(3));
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 12}.

{function, abs, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, abs}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {test, is_lt, {f, 10}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '-', {f, 0}, 1, [{integer, 0}, {x, 0}], {x, 0}}.
    {jump, {f, 11}}.
  {label, 10}.
  {label, 11}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, main, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {move, {integer, -5}, {x, 0}}.
    {call, 1, {f, 3}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {integer, 3}, {x, 0}}.
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
5
3
```
