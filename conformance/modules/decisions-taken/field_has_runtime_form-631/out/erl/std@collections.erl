-module(std@collections).
-export([lt/0, eq/0, gt/0, toInt/1, reverse/1, shown/1, '__bp_priv__array_range'/2, '__bp_priv__array_repeat'/2]).

%% behavior array

array_range(Start, Stop) ->
    case ((Stop - Start) =< 0) of
        true ->
            [];
        false ->
            case ((Stop - Start) =:= 1) of
                true ->
                    [Start];
                false ->
                    Count = (Stop - Start),
                    Low = array_range(Start, (Start + (Count div 2))),
                    High = array_range((Start + (Count div 2)), Stop),
                    '__bp_prim_append'(Low, High)
            end
    end.

array_repeat(Value, Times) ->
    case (Times =< 0) of
        true ->
            [];
        false ->
            Half = array_repeat(Value, (Times div 2)),
            case ((Times rem 2) =:= 0) of
                true ->
                    '__bp_prim_append'(Half, Half);
                false ->
                    '__bp_prim_append'('__bp_prim_append'(Half, Half), [Value])
            end
    end.

%%% std/collections — the four collection types, one namespace each (decision

%%% 106): `Dict<K, V>`, `Set<T>`, `Queue<T>` and `Order`. Was the four modules

%%% `dict`, `sets`, `queue` and `order`; the type is the namespace now, so a

%%% constructor is called on the type it builds (decision 111) —

%%% `Dict.empty()` / `Dict.ofEntries(entries)`, `Set.empty()` /

%%% `Set.fromList(xs)`, `Queue.empty()` / `Queue.fromList(xs)` — and every

%%% other function keeps its name.

% ── Dict<K, V> ──────────────────────────────────────────────────────────────

% `Dict` (was `dict`) — Gleam-inspired — a `type Dict<K, V>` wrapping an

% association list `pairs: array<#(K, V)>` for full backend portability

% (no host-backing). O(n) read; camelCase convention.

% 

% Instance operations are `self`-methods on the record; `empty` is a

% type-scoped constructor, `Dict.empty()` (records hold state and are

% constructed — unlike interfaces, which are pure behaviour contracts).

% 

% `==` / `!=` on generic K uses structural equality (string/numeric keys —

% the common case). API naming note: `new`/`get` are keyword tokens — use

% `empty`/`at`.

% 

% `Dict<K, V>` answers the ambient `Index<K, V>` of `primitives.bp`

% (decision 63, amended), which is what makes `d["k"]` legal: the index

% expression has no typing rule of its own and rewrites to `d.at("k")`. The

% reader was spelled `lookup` until that amendment gave every indexable type

% one method name.

%% type Dict: pairs

% One key or value of `Dict.display`: a string quoted, anything else as it

% interpolates.

shown(X) ->
    case erlang:is_binary(X) of
        true ->
            <<"\"", ('__bp_text'(X))/binary, "\"">>;
        _ ->
            <<('__bp_text'(X))/binary>>
    end.

















% ── `??` over `at`'s `?V` (decision 330: `?T` has no methods) ──


% ── empty-collection boundary (B1) ──


% ── Set<T> ──────────────────────────────────────────────────────────────────

% `Set` (was `sets`) — Gleam-inspired — a `type Set<T>` wrapping a deduplicated

% `array<T>` (`items`). Pure botopink — no host backing. O(n) contains;

% membership by `==` over `any` (decision 210: records by value on every

% target; `indexOf` is the host's identity on commonJS and wasm).

% 

% Instance operations are `self`-methods on the record; `empty`/`fromList`

% are type-scoped constructors (`Set.empty()`, `Set.fromList(xs)`). API

% naming note: `new`/`set` are keyword tokens — the constructor is `empty`.

%% type Set: items










% ── empty-collection boundary (B1) ──


% ── Queue<T> ────────────────────────────────────────────────────────────────

% `Queue` (was `queue`) — Gleam-inspired — a `type Queue<T>` wrapping an `array<T>`

% (front at index 0). Pure botopink — no host backing. O(n) enqueue (copy),

% O(1) peek.

% 

% Instance operations are `self`-methods on the record; `empty`/`fromList`

% are type-scoped constructors (`Queue.empty()`, `Queue.fromList(xs)`).

% `dequeue` returns `#(Queue<T>, ?T)` (the updated queue + the removed front

% item). API naming note: `new` is a keyword token —

% the constructor is `empty`.

%% type Queue: items








% ── empty-collection boundary (B1) ──


% ── Order ───────────────────────────────────────────────────────────────────

% `Order` (was `order`) — Gleam-style, inspired by `gleam/order`. A sum type — the

% `type Order` (type-exported to importers) plus companion functions.

% Construct via the module fns (`collections.lt()`); `toInt`/`reverse` operate on

% an `Order`. Enums are concrete types, not interfaces.

%% type Order
%%   Lt
%%   Eq
%%   Gt

lt() ->
    std@collections@@Order__v__lt.

eq() ->
    std@collections@@Order__v__eq.

gt() ->
    std@collections@@Order__v__gt.

toInt(O) ->
    N = case O of
        std@collections@@Order__v__lt ->
            (-1);
        std@collections@@Order__v__eq ->
            0;
        _ ->
            1
    end,
    N.

reverse(O) ->
    R = case O of
        std@collections@@Order__v__lt ->
            std@collections@@Order__v__gt;
        std@collections@@Order__v__gt ->
            std@collections@@Order__v__lt;
        _ ->
            std@collections@@Order__v__eq
    end,
    R.




'__bp_prim_append'(Recv, Arg0) when erlang:is_list(Recv) ->
    (Recv ++ Arg0);
'__bp_prim_append'(Recv, _) ->
    erlang:error({bp_unsupported_method, <<"append">>, 1, Recv}).

'__bp_text'(Value) when erlang:is_binary(Value) -> Value;
'__bp_text'(Value) -> unicode:characters_to_binary('__bp_show'(Value, true)).

'__bp_show'(V, true) when erlang:is_binary(V) -> V;
'__bp_show'(V, _) when erlang:is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when erlang:is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'({ok, P}, _) -> ["Ok(", '__bp_show'(P, false), $)];
'__bp_show'({error, P}, _) -> ["Error(", '__bp_show'(P, false), $)];
'__bp_show'(V, _) when erlang:is_tuple(V), erlang:tuple_size(V) > 0, erlang:is_atom(erlang:element(1, V)), erlang:element(1, V) =/= true, erlang:element(1, V) =/= false, erlang:element(1, V) =/= undefined -> '__bp_tagged'(erlang:element(1, V), V);
'__bp_show'(V, _) when erlang:is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- erlang:tuple_to_list(V)]), $)];
'__bp_show'(undefined, _) -> "null";
'__bp_show'(V, _) when erlang:is_atom(V), V =/= true, V =/= false, V =/= undefined -> '__bp_tagged'(V, V);
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'__bp_tagged'(A, V) ->
    M = case string:split(erlang:atom_to_list(A), "__v__") of [P, _] -> erlang:list_to_atom(P); _ -> A end,
    case code:ensure_loaded(M) =:= {module, M} andalso erlang:function_exported(M, '__bp_format', 1) of true -> '__bp_render'(erlang:apply(M, '__bp_format', [V])); false -> io_lib:format("~p", [V]) end.

'__bp_render'({text, T}) -> T;
'__bp_render'({variant, N, []}) -> N;
'__bp_render'({_, N, Fs}) -> [N, $(, lists:join(", ", [[K, ": ", '__bp_show'(Val, false)] || {K, Val} <- Fs]), $)].

'__bp_priv__array_range'(A0, A1) -> array_range(A0, A1).

'__bp_priv__array_repeat'(A0, A1) -> array_repeat(A0, A1).
