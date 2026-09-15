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

----- ERLANG -- std/order.erl
```erlang
-module(order).
-export([lt/0, eq/0, gt/0, toInt/1, reverse/1]).

%%% Gleam-style `order` module, inspired by `gleam/order`. A sum type — the

%%% `enum Order` (type-exported to importers) plus companion functions.

%%% Construct via the module fns (`order.lt()`); `toInt`/`reverse` operate on

%%% an `Order`. Enums are concrete types, not interfaces.

%% enum Order
%%   Lt
%%   Eq
%%   Gt

lt() ->
    'Lt'.

eq() ->
    'Eq'.

gt() ->
    'Gt'.

toInt(O) ->
    N = case O of
        'Lt' ->
            (-1);
        'Eq' ->
            0;
        _ ->
            1
    end,
    N.

reverse(O) ->
    R = case O of
        'Lt' ->
            'Gt';
        'Gt' ->
            'Lt';
        _ ->
            'Eq'
    end,
    R.



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

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% import order

describe(O) ->
    S = case O of
        Lt ->
            <<"less">>;
        Gt ->
            <<"greater">>;
        _ ->
            <<"equal">>
    end,
    S.

main() ->
    io:format("~p~n", [order:toInt(order:lt())]),
    io:format("~p~n", [describe(order:reverse(order:lt()))]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
-1
<<"less">>
```
