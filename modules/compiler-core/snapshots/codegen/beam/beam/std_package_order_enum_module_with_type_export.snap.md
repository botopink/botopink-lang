----- SOURCE CODE -- std/order.bp
```botopink
//// Gleam-style `order` module, inspired by `gleam/order`. A sum type — the
//// `enum Order` (type-exported to importers) plus companion functions.
//// Construct via the module fns (`order.lt()`); `toInt`/`reverse` operate on
//// an `Order`. Enums are concrete types, not interfaces.

pub enum Order {
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
{module, order}.
{exports, [{lt, 0}, {eq, 0}, {gt, 0}, {toInt, 1}, {reverse, 1}]}.
{attributes, []}.
{labels, 20}.
%%% Gleam-style `order` module, inspired by `gleam/order`. A sum type — the
%%% `enum Order` (type-exported to importers) plus companion functions.
%%% Construct via the module fns (`order.lt()`); `toInt`/`reverse` operate on
%%% an `Order`. Enums are concrete types, not interfaces.

{function, lt, 0, 3}.
  {label, 2}.
    {line, [{location, "order.erl", 1}]}.
    {func_info, {atom, order}, {atom, lt}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {atom, 'Order'}, {x, 0}}.
    {test, is_map, {f, 12}, [{x, 0}]}.
    {get_map_elements, {f, 12}, {x, 0}, {list, [{atom, 'Lt'}, {x, 0}]}}.
  {label, 12}.
    {deallocate, 0}.
    return.

{function, eq, 0, 5}.
  {label, 4}.
    {line, [{location, "order.erl", 2}]}.
    {func_info, {atom, order}, {atom, eq}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {move, {atom, 'Order'}, {x, 0}}.
    {test, is_map, {f, 13}, [{x, 0}]}.
    {get_map_elements, {f, 13}, {x, 0}, {list, [{atom, 'Eq'}, {x, 0}]}}.
  {label, 13}.
    {deallocate, 0}.
    return.

{function, gt, 0, 7}.
  {label, 6}.
    {line, [{location, "order.erl", 3}]}.
    {func_info, {atom, order}, {atom, gt}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {move, {atom, 'Order'}, {x, 0}}.
    {test, is_map, {f, 14}, [{x, 0}]}.
    {get_map_elements, {f, 14}, {x, 0}, {list, [{atom, 'Gt'}, {x, 0}]}}.
  {label, 14}.
    {deallocate, 0}.
    return.

{function, toInt, 1, 9}.
  {label, 8}.
    {line, [{location, "order.erl", 4}]}.
    {func_info, {atom, order}, {atom, toInt}, 1}.
  {label, 9}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, -1}, {x, 0}}.
    {jump, {f, 15}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 0}, {x, 0}}.
    {jump, {f, 15}}.
    {move, {integer, 1}, {x, 0}}.
    {jump, {f, 15}}.
  {label, 15}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, reverse, 1, 11}.
  {label, 10}.
    {line, [{location, "order.erl", 5}]}.
    {func_info, {atom, order}, {atom, reverse}, 1}.
  {label, 11}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {atom, 'Order'}, {x, 0}}.
    {test, is_map, {f, 17}, [{x, 0}]}.
    {get_map_elements, {f, 17}, {x, 0}, {list, [{atom, 'Gt'}, {x, 0}]}}.
  {label, 17}.
    {jump, {f, 16}}.
    {move, {x, 0}, {y, 1}}.
    {move, {atom, 'Order'}, {x, 0}}.
    {test, is_map, {f, 18}, [{x, 0}]}.
    {get_map_elements, {f, 18}, {x, 0}, {list, [{atom, 'Lt'}, {x, 0}]}}.
  {label, 18}.
    {jump, {f, 16}}.
    {move, {atom, 'Order'}, {x, 0}}.
    {test, is_map, {f, 19}, [{x, 0}]}.
    {get_map_elements, {f, 19}, {x, 0}, {list, [{atom, 'Eq'}, {x, 0}]}}.
  {label, 19}.
    {jump, {f, 16}}.
  {label, 16}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
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
{labels, 11}.

{function, describe, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, describe}, 1}.
  {label, 3}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"less">>}, {x, 0}}.
    {jump, {f, 10}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"greater">>}, {x, 0}}.
    {jump, {f, 10}}.
    {move, {literal, <<"equal">>}, {x, 0}}.
    {jump, {f, 10}}.
  {label, 10}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, main, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {move, {atom, order}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {atom, order}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    %% unresolved method call: lt/1
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    %% unresolved method call: toInt/2
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {atom, order}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {atom, order}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    %% unresolved method call: lt/1
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    %% unresolved method call: reverse/2
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
order
<<"less">>
```
