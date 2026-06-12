----- SOURCE CODE -- main.bp
```botopink
fn coerce(comptime v: type string | int | bool, x: i32) -> i32 {
    return x;
}

fn main() {
    val a = coerce("s", 1);
    val b = coerce(7, 2);
    val c = coerce("s", 3);
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 12}.

{function, main, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 3}.
    {allocate, 3, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {integer, 1}, {x, 0}}.
    {call, 1, {f, 5}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {call, 1, {f, 7}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call, 1, {f, 5}}.
    {move, {x, 0}, {y, 2}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, 'coerce_$0', 1, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, 'coerce_$0'}, 1}.
  {label, 5}.
    {allocate, 0, 1}.
    {deallocate, 0}.
    return.

{function, 'coerce_$1', 1, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, 'coerce_$1'}, 1}.
  {label, 7}.
    {allocate, 0, 1}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 9}.
  {label, 8}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '_botopink_main'}, 0}.
  {label, 9}.
    {call_only, 0, {f, 3}}.

{function, main, 1, 11}.
  {label, 10}.
    {line, [{location, "main.erl", 5}]}.
    {func_info, {atom, main}, {atom, main}, 1}.
  {label, 11}.
    {call_only, 0, {f, 9}}.
```

----- RUN LOG -----
```logs
```
