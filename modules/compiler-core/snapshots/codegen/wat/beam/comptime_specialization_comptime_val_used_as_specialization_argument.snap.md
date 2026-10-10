----- SOURCE CODE -- main.bp
```botopink
val base = comptime 10 + 5;

fn scale(comptime factor: @Expr<i32>, value: i32) -> i32 {
    return value * factor.value;
}

fn main() {
    val doubled = scale(2, base);
    val tripled = scale(3, base);
    val doubledAgain = scale(2, 100);
}
```

----- COMPTIME VALUES -- main
```text
ct_0: val base = comptime 10 + 5 → 15
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 18}.

{function, base, 0, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, base}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {integer, 15}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, main, 0, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, main}, 0}.
  {label, 5}.
    {allocate, 3, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {call, 0, {f, 3}}.
    {call, 1, {f, 7}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 3}}.
    {call, 1, {f, 9}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 100}, {x, 0}}.
    {call, 1, {f, 7}}.
    {move, {x, 0}, {y, 2}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, 'scale_$0', 1, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, 'scale_$0'}, 1}.
  {label, 7}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {y, 1}], {x, 0}}.
    {test, is_ge, {f, 14}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 14}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 15}}.
  {label, 14}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at test@main.bp:4:18">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 15}.
    {deallocate, 2}.
    return.

{function, 'scale_$1', 1, 9}.
  {label, 8}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, 'scale_$1'}, 1}.
  {label, 9}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {y, 1}], {x, 0}}.
    {test, is_ge, {f, 16}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 16}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 17}}.
  {label, 16}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at test@main.bp:4:18">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 17}.
    {deallocate, 2}.
    return.

{function, '_botopink_main', 0, 11}.
  {label, 10}.
    {line, [{location, "test@main.erl", 5}]}.
    {func_info, {atom, test@main}, {atom, '_botopink_main'}, 0}.
  {label, 11}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 5}, 0}.

{function, main, 1, 13}.
  {label, 12}.
    {line, [{location, "test@main.erl", 6}]}.
    {func_info, {atom, test@main}, {atom, main}, 1}.
  {label, 13}.
    {call_only, 0, {f, 11}}.
```

----- RUN LOG -----
```logs
```
