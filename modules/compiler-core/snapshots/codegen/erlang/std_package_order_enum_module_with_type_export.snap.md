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

----- ERLANG -- std/order.erl
```erlang
-module(std@order).
-export([lt/0, eq/0, gt/0, toInt/1, reverse/1]).

%%% Gleam-style `order` module, inspired by `gleam/order`. A sum type — the

%%% `type Order` (type-exported to importers) plus companion functions.

%%% Construct via the module fns (`order.lt()`); `toInt`/`reverse` operate on

%%% an `Order`. Enums are concrete types, not interfaces.

%% type Order
%%   Lt
%%   Eq
%%   Gt

lt() ->
    std@order__t__order__v__lt.

eq() ->
    std@order__t__order__v__eq.

gt() ->
    std@order__t__order__v__gt.

toInt(O) ->
    N = case O of
        std@order__t__order__v__lt ->
            (-1);
        std@order__t__order__v__eq ->
            0;
        _ ->
            1
    end,
    N.

reverse(O) ->
    R = case O of
        std@order__t__order__v__lt ->
            std@order__t__order__v__gt;
        std@order__t__order__v__gt ->
            std@order__t__order__v__lt;
        _ ->
            std@order__t__order__v__eq
    end,
    R.



```

----- ERLANG -- std@order__t__order.erl
```erlang
-module(std@order__t__order).
-export(['__bp_format'/1]).

'__bp_format'(std@order__t__order__v__lt) -> {variant, "Order.Lt", []};
'__bp_format'(std@order__t__order__v__eq) -> {variant, "Order.Eq", []};
'__bp_format'(std@order__t__order__v__gt) -> {variant, "Order.Gt", []}.
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
        std@order__t__order__v__lt ->
            <<"less">>;
        std@order__t__order__v__gt ->
            <<"greater">>;
        _ ->
            <<"equal">>
    end,
    S.

main() ->
    '__bp_print'([std@order:toInt(std@order:lt())]),
    '__bp_print'([describe(std@order:reverse(std@order:lt()))]).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when is_binary(V) -> V;
'__bp_show'(V, _) when is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when is_tuple(V), tuple_size(V) > 0, is_atom(element(1, V)), element(1, V) =/= true, element(1, V) =/= false, element(1, V) =/= undefined -> '__bp_tagged'(element(1, V), V);
'__bp_show'(V, _) when is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- tuple_to_list(V)]), $)];
'__bp_show'(V, _) when is_atom(V), V =/= true, V =/= false, V =/= undefined -> '__bp_tagged'(V, V);
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'__bp_tagged'(A, V) ->
    M = case string:split(atom_to_list(A), "__v__") of [P, _] -> list_to_atom(P); _ -> A end,
    case code:ensure_loaded(M) =:= {module, M} andalso erlang:function_exported(M, '__bp_format', 1) of true -> '__bp_render'(apply(M, '__bp_format', [V])); false -> io_lib:format("~p", [V]) end.

'__bp_render'({text, T}) -> T;
'__bp_render'({variant, N, []}) -> N;
'__bp_render'({_, N, Fs}) -> [N, $(, lists:join(", ", [[K, ": ", '__bp_show'(Val, false)] || {K, Val} <- Fs]), $)].

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
-1
greater
```
