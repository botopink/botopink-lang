----- SOURCE CODE -- a.bp
```botopink
pub fn twice(x: i32) -> i32 {
    return x * 2;
}
```

----- BEAM ASSEMBLY -- a.S
```erlang
{module, a}.
{exports, [{twice, 1}]}.
{attributes, []}.
{labels, 4}.

{function, twice, 1, 3}.
  {label, 2}.
    {line, [{location, "a.erl", 1}]}.
    {func_info, {atom, a}, {atom, twice}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {integer, 2}], {x, 0}}.
    {deallocate, 1}.
    return.
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- b.bp
```botopink
import { twice };

pub fn quad(x: i32) -> i32 {
    return twice(twice(x));
}

pub fn main() {
    @print(quad(3));
}
```

----- BEAM ASSEMBLY -- b.S
```erlang
{module, b}.
{exports, [{'_botopink_main', 0}, {main, 1}, {quad, 1}, {main, 0}]}.
{attributes, []}.
{labels, 19}.

{function, quad, 1, 3}.
  {label, 2}.
    {line, [{location, "b.erl", 1}]}.
    {func_info, {atom, b}, {atom, quad}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, a, twice, 1}}.
    {call_ext_last, 1, {extfunc, a, twice, 1}, 1}.

{function, main, 0, 5}.
  {label, 4}.
    {line, [{location, "b.erl", 2}]}.
    {func_info, {atom, b}, {atom, main}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {move, {integer, 3}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 11}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 7}.
  {label, 6}.
    {line, [{location, "b.erl", 3}]}.
    {func_info, {atom, b}, {atom, '_botopink_main'}, 0}.
  {label, 7}.
    {call_only, 0, {f, 5}}.

{function, main, 1, 9}.
  {label, 8}.
    {line, [{location, "b.erl", 4}]}.
    {func_info, {atom, b}, {atom, main}, 1}.
  {label, 9}.
    {call_only, 0, {f, 7}}.

{function, '__bp_print', 1, 11}.
  {label, 10}.
    {line, [{location, "b.erl", 3}]}.
    {func_info, {atom, b}, {atom, '__bp_print'}, 1}.
  {label, 11}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 1, {f, 13}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '__bp_print_fmt', 1, 13}.
  {label, 12}.
    {line, [{location, "b.erl", 3}]}.
    {func_info, {atom, b}, {atom, '__bp_print_fmt'}, 1}.
  {label, 13}.
    {test, is_nonempty_list, {f, 16}, [{x, 0}]}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {get_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 1}, {y, 0}}.
    {call, 1, {f, 15}}.
    {test, is_binary, {f, 17}, [{y, 0}]}.
    {test_heap, 6, 1}.
    {put_list, {integer, 115}, {x, 0}, {x, 0}}.
    {put_list, {integer, 116}, {x, 0}, {x, 0}}.
    {put_list, {integer, 126}, {x, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 17}.
    {test_heap, 4, 1}.
    {put_list, {integer, 112}, {x, 0}, {x, 0}}.
    {put_list, {integer, 126}, {x, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 16}.
    {move, {literal, [126, 110]}, {x, 0}}.
    return.

{function, '__bp_print_sep', 1, 15}.
  {label, 14}.
    {line, [{location, "b.erl", 3}]}.
    {func_info, {atom, b}, {atom, '__bp_print_sep'}, 1}.
  {label, 15}.
    {test, is_nonempty_list, {f, 18}, [{x, 0}]}.
    {allocate, 0, 1}.
    {call, 1, {f, 13}}.
    {test_heap, 2, 1}.
    {put_list, {integer, 32}, {x, 0}, {x, 0}}.
    {deallocate, 0}.
    return.
  {label, 18}.
    {move, {literal, [126, 110]}, {x, 0}}.
    return.
```

----- RUN LOG -----
```logs
12
```
