----- SOURCE CODE -- main.bp
```botopink
fn firstSquareOver(n: i32) -> i32 {
    var k = 0;
    loop {
        k = k + 1;
        if (k * k > n) { break; };
    };
    return k;
}
fn nested() -> i32 {
    var outer = 0;
    var inner = 0;
    loop (outer < 3) {
        outer = outer + 1;
        loop {
            inner = inner + 1;
            break;
        };
    };
    return outer * 10 + inner;
}
fn main() {
    @print(firstSquareOver(20));
    @print(nested());
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 28}.

{function, firstSquareOver, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, firstSquareOver}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
  {label, 12}.
    {move, {atom, true}, {x, 0}}.
    {test, is_eq_exact, {f, 13}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 1}, {y, 1}], {x, 0}}.
    {test, is_lt, {f, 14}, [{y, 0}, {x, 0}]}.
    {jump, {f, 13}}.
  {label, 14}.
    {jump, {f, 12}}.
  {label, 13}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, nested, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, nested}, 0}.
  {label, 5}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
  {label, 15}.
    {test, is_lt, {f, 16}, [{y, 0}, {integer, 3}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {x, 0}, {y, 0}}.
  {label, 17}.
    {move, {atom, true}, {x, 0}}.
    {test, is_eq_exact, {f, 18}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 18}}.
  {label, 18}.
    {jump, {f, 15}}.
  {label, 16}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {integer, 10}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 1}], {x, 0}}.
    {deallocate, 2}.
    return.

{function, main, 0, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {move, {integer, 20}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 20}}.
    {call, 0, {f, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 20}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 9}.
  {label, 8}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '_botopink_main'}, 0}.
  {label, 9}.
    {call_only, 0, {f, 7}}.

{function, main, 1, 11}.
  {label, 10}.
    {line, [{location, "main.erl", 5}]}.
    {func_info, {atom, main}, {atom, main}, 1}.
  {label, 11}.
    {call_only, 0, {f, 9}}.

{function, '__bp_print', 1, 20}.
  {label, 19}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '__bp_print'}, 1}.
  {label, 20}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 1, {f, 22}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '__bp_print_fmt', 1, 22}.
  {label, 21}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '__bp_print_fmt'}, 1}.
  {label, 22}.
    {test, is_nonempty_list, {f, 25}, [{x, 0}]}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {get_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 1}, {y, 0}}.
    {call, 1, {f, 24}}.
    {test, is_binary, {f, 26}, [{y, 0}]}.
    {test_heap, 6, 1}.
    {put_list, {integer, 115}, {x, 0}, {x, 0}}.
    {put_list, {integer, 116}, {x, 0}, {x, 0}}.
    {put_list, {integer, 126}, {x, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 26}.
    {test_heap, 4, 1}.
    {put_list, {integer, 112}, {x, 0}, {x, 0}}.
    {put_list, {integer, 126}, {x, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 25}.
    {move, {literal, [126, 110]}, {x, 0}}.
    return.

{function, '__bp_print_sep', 1, 24}.
  {label, 23}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '__bp_print_sep'}, 1}.
  {label, 24}.
    {test, is_nonempty_list, {f, 27}, [{x, 0}]}.
    {allocate, 0, 1}.
    {call, 1, {f, 22}}.
    {test_heap, 2, 1}.
    {put_list, {integer, 32}, {x, 0}, {x, 0}}.
    {deallocate, 0}.
    return.
  {label, 27}.
    {move, {literal, [126, 110]}, {x, 0}}.
    return.
```

----- RUN LOG -----
```logs
5
33
```
