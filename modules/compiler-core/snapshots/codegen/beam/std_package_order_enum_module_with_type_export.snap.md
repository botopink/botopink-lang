----- SOURCE CODE -- std/order.bp
```botopink
//// Gleam-style `order` module, inspired by `gleam/order`. A sum type — the
//// `type Order` (type-exported to importers) plus companion functions.
//// Construct via the module fns (`order.lt()`); `toInt`/`reverse` operate on
//// an `Order`. Enums are concrete types, not interfaces.

pub type Order {
    Lt,
    Eq,
    Gt,
}

pub fn lt() -> Order {
    return Order.Lt;
}

pub fn eq() -> Order {
    return Order.Eq;
}

pub fn gt() -> Order {
    return Order.Gt;
}

pub fn toInt(o: Order) -> i32 {
    val n = case o {
        Lt -> -1;
        Eq -> 0;
        _ -> 1;
    };
    return n;
}

pub fn reverse(o: Order) -> Order {
    val r = case o {
        Lt -> Order.Gt;
        Gt -> Order.Lt;
        _ -> Order.Eq;
    };
    return r;
}

test "order toInt" {
    assert toInt(lt()) == -1;
    assert toInt(eq()) == 0;
    assert toInt(gt()) == 1;
}

test "order reverse" {
    assert toInt(reverse(lt())) == 1;
    assert toInt(reverse(gt())) == -1;
    assert toInt(reverse(eq())) == 0;
}

test "order case over Order" {
    val o = reverse(lt());
    val s = case o {
        Lt -> "less";
        Gt -> "greater";
        _ -> "equal";
    };
    assert s == "greater";
}

```

----- BEAM ASSEMBLY -- std/order.S
```erlang
{module, std@order}.
{exports, [{lt, 0}, {eq, 0}, {gt, 0}, {toInt, 1}, {reverse, 1}]}.
{attributes, []}.
{labels, 18}.
%%% Gleam-style `order` module, inspired by `gleam/order`. A sum type — the
%%% `type Order` (type-exported to importers) plus companion functions.
%%% Construct via the module fns (`order.lt()`); `toInt`/`reverse` operate on
%%% an `Order`. Enums are concrete types, not interfaces.

{function, lt, 0, 3}.
  {label, 2}.
    {line, [{location, "std@order.erl", 1}]}.
    {func_info, {atom, std@order}, {atom, lt}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {atom, 'Lt'}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, eq, 0, 5}.
  {label, 4}.
    {line, [{location, "std@order.erl", 2}]}.
    {func_info, {atom, std@order}, {atom, eq}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {move, {atom, 'Eq'}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, gt, 0, 7}.
  {label, 6}.
    {line, [{location, "std@order.erl", 3}]}.
    {func_info, {atom, std@order}, {atom, gt}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {move, {atom, 'Gt'}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, toInt, 1, 9}.
  {label, 8}.
    {line, [{location, "std@order.erl", 4}]}.
    {func_info, {atom, std@order}, {atom, toInt}, 1}.
  {label, 9}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 13}, [{x, 0}, {atom, 'Lt'}]}.
    {move, {integer, -1}, {x, 0}}.
    {jump, {f, 12}}.
  {label, 13}.
    {test, is_eq, {f, 14}, [{x, 0}, {atom, 'Eq'}]}.
    {move, {integer, 0}, {x, 0}}.
    {jump, {f, 12}}.
  {label, 14}.
    {move, {integer, 1}, {x, 0}}.
    {jump, {f, 12}}.
  {label, 12}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, reverse, 1, 11}.
  {label, 10}.
    {line, [{location, "std@order.erl", 5}]}.
    {func_info, {atom, std@order}, {atom, reverse}, 1}.
  {label, 11}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 16}, [{x, 0}, {atom, 'Lt'}]}.
    {move, {atom, 'Gt'}, {x, 0}}.
    {jump, {f, 15}}.
  {label, 16}.
    {test, is_eq, {f, 17}, [{x, 0}, {atom, 'Gt'}]}.
    {move, {atom, 'Lt'}, {x, 0}}.
    {jump, {f, 15}}.
  {label, 17}.
    {move, {atom, 'Eq'}, {x, 0}}.
    {jump, {f, 15}}.
  {label, 15}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 4}.
    return.
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {order} from "std";

fn describe(o: Order) -> string {
    val s = case o {
        Lt -> "less";
        Gt -> "greater";
        _ -> "equal";
    };
    return s;
}

fn main() {
    @print(order.toInt(order.lt()));
    @print(describe(order.reverse(order.lt())));
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 26}.

{function, describe, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, describe}, 1}.
  {label, 3}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 11}, [{x, 0}, {atom, 'Lt'}]}.
    {move, {literal, <<"less">>}, {x, 0}}.
    {jump, {f, 10}}.
  {label, 11}.
    {test, is_eq, {f, 12}, [{x, 0}, {atom, 'Gt'}]}.
    {move, {literal, <<"greater">>}, {x, 0}}.
    {jump, {f, 10}}.
  {label, 12}.
    {move, {literal, <<"equal">>}, {x, 0}}.
    {jump, {f, 10}}.
  {label, 10}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, main, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 5}.
    {allocate, 4, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {call_ext, 0, {extfunc, std@order, lt, 0}}.
    {call_ext, 1, {extfunc, std@order, toInt, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 14}}.
    {call_ext, 0, {extfunc, std@order, lt, 0}}.
    {call_ext, 1, {extfunc, std@order, reverse, 1}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 14}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 4}.
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

{function, '__bp_print', 1, 14}.
  {label, 13}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '__bp_print'}, 1}.
  {label, 14}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 18}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 18}.
  {label, 17}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '-bp_show_top-'}, 1}.
  {label, 18}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 16}}.

{function, '-bp_show_elem-', 1, 20}.
  {label, 19}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 20}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 16}}.

{function, '__bp_show', 2, 16}.
  {label, 15}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '__bp_show'}, 2}.
  {label, 16}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 22}, [{x, 0}]}.
    {test, is_eq, {f, 21}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 21}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 22}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 23}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 20}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 93}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 91}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 23}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 25}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 24}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 24}, [{x, 0}]}.
    {test, is_ne_exact, {f, 24}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 24}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 24}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 25}}.
  {label, 24}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 20}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 40}, {x, 0}, {x, 0}}.
    {put_list, {integer, 35}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 25}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
```

----- RUN LOG -----
```logs
-1
greater
```
