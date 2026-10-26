-module(bp_load_cases_std_math_on_every_target@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0]).

%%% `std/math` on all four targets (decision 238, `01-compiler/05-wasm` step 5):

%%% wasm binds `abs`, `floor`, `trunc`, `sqrt`, `minF` and `maxF` to one

%%% instruction each (`op:`) and every other host cell to a private botopink

%%% body (`fn:`) — `round` too, because `f64.nearest` rounds a half to even.

%%% erlang and beam run the same bodies (decision 263) and every target runs

%%% std's port of glibc's `pow` (decision 259), so no answer depends on the

%%% platform libm. Each line compares with the value `Math.*` answers on Linux,

%%% so the one `.out` is every target's on every OS: the targets print a float

%%% differently (`3` / `3.0`), and a truth value the same way.

%% import math

main() ->
    '__bp_print'([(std@math:abs((0.0 - 5.5)) =:= 5.5)]),
    '__bp_print'([((std@math:floor(3.7) =:= 3.0) andalso (std@math:ceil(3.2) =:= 4.0))]),
    '__bp_print'([((std@math:trunc((0.0 - 2.9)) < (0.0 - 1.5)) andalso (std@math:trunc((0.0 - 2.9)) > (0.0 - 2.5)))]),
    '__bp_print'([((std@math:round(2.5) > 2.5) andalso (std@math:round(2.5) < 3.5))]),
    '__bp_print'([(std@math:round(0.49999999999999994) < 0.5)]),
    '__bp_print'([((std@math:minF(1.5, 2.5) =:= 1.5) andalso (std@math:maxF(1.5, 2.5) =:= 2.5))]),
    '__bp_print'([(std@math:sqrt(2.0) =:= 1.4142135623730951)]),
    '__bp_print'([(std@math:hypot(3.0, 4.0) =:= 5.0)]),
    '__bp_print'([(std@math:exp(1.0) =:= 2.718281828459045)]),
    '__bp_print'([(std@math:ln(10.0) =:= 2.302585092994046)]),
    '__bp_print'([((std@math:log2(8.0) =:= 3.0) andalso (std@math:log10(1000.0) =:= 3.0))]),
    '__bp_print'([((std@math:pow(2.0, 10.0) =:= 1024.0) andalso (std@math:pow(2.0, 0.5) =:= 1.4142135623730951))]),
    '__bp_print'([(std@math:pow(1.5, 7.3) =:= 19.295951155032366)]),
    '__bp_print'([(std@math:pow(158.42161580281933, 2.853827476501465) =:= 1896229.4525711867)]),
    '__bp_print'([((std@math:sin(1.0) =:= 0.8414709848078965) andalso (std@math:cos(1.0) =:= 0.5403023058681398))]),
    '__bp_print'([(std@math:tan(1.0) =:= 1.5574077246549023)]),
    '__bp_print'([((std@math:asin(0.5) =:= 0.5235987755982989) andalso (std@math:acos(0.5) =:= 1.0471975511965979))]),
    '__bp_print'([((std@math:atan(1.0) =:= 0.7853981633974483) andalso (std@math:atan2(1.0, (0.0 - 1.0)) =:= 2.356194490192345))]),
    '__bp_print'([((std@math:sinh(1.0) =:= 1.1752011936438014) andalso (std@math:cosh(1.0) =:= 1.5430806348152437))]),
    '__bp_print'([(std@math:tanh(0.5) =:= 0.46211715726000974)]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/std_math_on_every_target|*">>.

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
    '__bp_load_siblings'(),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_load_siblings'() ->
    case code:which(?MODULE) of
        Path when erlang:is_list(Path) ->
            lists:foreach(fun(Src) ->
                case code:ensure_loaded(erlang:list_to_atom(filename:basename(Src, ".erl"))) of
                    {module, _} -> ok;
                    _ ->
                        case compile:file(Src, [binary, return_errors]) of
                            {ok, Mod, Bin} -> code:load_binary(Mod, Src, Bin);
                            Bad ->
                                io:format(standard_error, "error: ~ts does not compile - refusing to run~n  ~p~n", [Src, Bad]),
                                erlang:halt(1)
                        end
                end
            end, filelib:wildcard(filename:join(filename:dirname(Path), "*.erl")));
        _ -> ok
    end.
