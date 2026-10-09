----- SOURCE CODE -- main.bp
```botopink
val COMMANDS = comptime ["calc", "noop", "help"];

fn execute(comptime slug: string, input: i32) -> i32 {
    var output = 0;
    for (COMMANDS) { cmd ->
        if (cmd == slug) {
            output = case cmd {
                "calc" -> input * 2;
                "noop" -> input;
                _ -> 0;
            };
        };
    };
    return output;
}

fn main() {
    val r1 = execute("calc", 10);
    val r2 = execute("noop", 42);
}
```

----- COMPTIME VALUES -- main
```text
ct_0: val COMMANDS = comptime ["calc", "noop", "help"] → ["calc", "noop", "help"]
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 16}.

{function, 'COMMANDS', 0, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, 'COMMANDS'}, 0}.
  {label, 3}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"help">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"noop">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"calc">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, main, 0, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, main}, 0}.
  {label, 5}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {integer, 10}, {x, 0}}.
    {call, 1, {f, 7}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 42}, {x, 0}}.
    {call, 1, {f, 9}}.
    {move, {x, 0}, {y, 1}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, 'execute_$0', 1, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, 'execute_$0'}, 1}.
  {label, 7}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 14}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 14}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 15}}.
  {label, 14}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at test@main.bp:8:33">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 15}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, 'execute_$1', 1, 9}.
  {label, 8}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, 'execute_$1'}, 1}.
  {label, 9}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
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
