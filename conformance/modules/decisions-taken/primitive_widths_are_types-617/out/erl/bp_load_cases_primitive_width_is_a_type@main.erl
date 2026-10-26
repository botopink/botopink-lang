-module(bp_load_cases_primitive_width_is_a_type@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__sizeOf'/2, '__bp_priv__number_clamp'/3]).

%% behavior Number

%% behavior Float

%% behavior Integer

%%% Decision 617 (1) — the primitive widths are types: `pub type i32 implement Signed { … }` and its siblings in std's prelude. A width's methods are found through its `implement` clause and the contracts' `extends`.

% Widths in type positions: a parameter, an array's element, a return.

sizeOf(Xs, Extra) ->
    erlang:length(Xs).

main() ->
    N = (-5),
    Ratio = 2.5,
    Bound = 1.0,
    % `abs` is `Signed`'s, which `i32` implements.
    '__bp_print'([(fun(__V) when __V =/= -2147483648 -> erlang:abs(__V); (_) -> erlang:error({integer_overflow, <<"integer overflow: abs on i32">>}) end)(N)]),
    % `isEven`, `isOdd` and `toString` are `Integer`'s, which `i32` reaches
    % through `Signed extends Integer`.
    '__bp_print'([i32IsEvenBody(N), i32IsOddBody(N), erlang:integer_to_binary(N)]),
    % `floor` is `Float`'s, which `f64` implements; `min` and `clamp` are
    % `Number`'s, which every width reaches.
    '__bp_print'([math:floor(Ratio), erlang:min(N, 3), erlang:min(Ratio, Bound), number_clamp(N, (-2), 2)]),
    '__bp_print'([sizeOf([3, 9, 4], 1)]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/primitive_width_is_a_type|*">>.

i32IsEvenBody(Value) ->
    ((Value rem 2) =:= 0).

i32IsOddBody(Value) ->
    ((Value rem 2) =/= 0).

number_clamp(Self, Lo, Hi) ->
    erlang:min(erlang:max(Self, Lo), Hi).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

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

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__sizeOf'(A0, A1) -> sizeOf(A0, A1).

'__bp_priv__number_clamp'(A0, A1, A2) -> number_clamp(A0, A1, A2).
