----- SOURCE CODE -- main.bp
```botopink
interface Bounded {
    fn min(self: Self, other: Self) -> Self,
    fn max(self: Self, other: Self) -> Self,

    default fn clamp(self: Self, lo: Self, hi: Self) -> Self {
        return self.max(lo).min(hi);
    }
}

record Money implement Bounded {
    cents: i32,

    fn min(self: Self, other: Self) -> Self {
        return if (self.cents < other.cents) { self; } else { other; };
    }

    fn max(self: Self, other: Self) -> Self {
        return if (self.cents > other.cents) { self; } else { other; };
    }
}

fn main() {
    val m = Money(cents: 500).clamp(Money(cents: 0), Money(cents: 120));
    @print(m.cents);
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 30}.

{function, 'Money_min', 2, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, 'Money_min'}, 2}.
  {label, 3}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_map, {f, 13}, [{x, 0}]}.
    {get_map_elements, {f, 13}, {x, 0}, {list, [{atom, cents}, {x, 0}]}}.
  {label, 13}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_map, {f, 14}, [{x, 0}]}.
    {get_map_elements, {f, 14}, {x, 0}, {list, [{atom, cents}, {x, 0}]}}.
  {label, 14}.
    {test, is_lt, {f, 12}, [{x, 1}, {x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {jump, {f, 15}}.
  {label, 12}.
    {move, {y, 1}, {x, 0}}.
  {label, 15}.
    {deallocate, 2}.
    return.

{function, 'Money_max', 2, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, 'Money_max'}, 2}.
  {label, 5}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_map, {f, 17}, [{x, 0}]}.
    {get_map_elements, {f, 17}, {x, 0}, {list, [{atom, cents}, {x, 0}]}}.
  {label, 17}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_map, {f, 18}, [{x, 0}]}.
    {get_map_elements, {f, 18}, {x, 0}, {list, [{atom, cents}, {x, 0}]}}.
  {label, 18}.
    {test, is_lt, {f, 16}, [{x, 0}, {x, 1}]}.
    {move, {y, 0}, {x, 0}}.
    {jump, {f, 19}}.
  {label, 16}.
    {move, {y, 1}, {x, 0}}.
  {label, 19}.
    {deallocate, 2}.
    return.

{function, main, 0, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 7}.
    {allocate, 4, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {put_map_assoc, {f, 0}, {literal, #{}}, {x, 0}, 0, {list, [{atom, cents}, {integer, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {put_map_assoc, {f, 0}, {literal, #{}}, {x, 0}, 0, {list, [{atom, cents}, {integer, 120}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    %% unresolved_method: clamp/3
    {move, {literal, {unresolved_method, clamp, 3}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_map, {f, 20}, [{x, 0}]}.
    {get_map_elements, {f, 20}, {x, 0}, {list, [{atom, cents}, {x, 0}]}}.
  {label, 20}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 22}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 4}.
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

{function, '__bp_print', 1, 22}.
  {label, 21}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '__bp_print'}, 1}.
  {label, 22}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 1, {f, 24}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '__bp_print_fmt', 1, 24}.
  {label, 23}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '__bp_print_fmt'}, 1}.
  {label, 24}.
    {test, is_nonempty_list, {f, 27}, [{x, 0}]}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {get_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 1}, {y, 0}}.
    {call, 1, {f, 26}}.
    {test, is_binary, {f, 28}, [{y, 0}]}.
    {test_heap, 6, 1}.
    {put_list, {integer, 115}, {x, 0}, {x, 0}}.
    {put_list, {integer, 116}, {x, 0}, {x, 0}}.
    {put_list, {integer, 126}, {x, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 28}.
    {test_heap, 4, 1}.
    {put_list, {integer, 112}, {x, 0}, {x, 0}}.
    {put_list, {integer, 126}, {x, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 27}.
    {move, {literal, [126, 110]}, {x, 0}}.
    return.

{function, '__bp_print_sep', 1, 26}.
  {label, 25}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '__bp_print_sep'}, 1}.
  {label, 26}.
    {test, is_nonempty_list, {f, 29}, [{x, 0}]}.
    {allocate, 0, 1}.
    {call, 1, {f, 24}}.
    {test_heap, 2, 1}.
    {put_list, {integer, 32}, {x, 0}, {x, 0}}.
    {deallocate, 0}.
    return.
  {label, 29}.
    {move, {literal, [126, 110]}, {x, 0}}.
    return.
```

----- RUN LOG -----
```logs
```
