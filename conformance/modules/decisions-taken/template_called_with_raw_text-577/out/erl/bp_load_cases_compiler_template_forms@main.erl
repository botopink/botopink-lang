-module(bp_load_cases_compiler_template_forms@main).
-export(['_botopink_main'/0, main/1]).
-export([find/0, digits/1, main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__array_range'/2, '__bp_priv__array_repeat'/2, '__bp_priv__array_first'/1]).

%% behavior string

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

%%% Decisions 577 (2), (3), 578 (1) — a template is called with its text in

%%% three places: `` name @`…` ``, `` recv.name @`…` `` for a template method

%%% (its `syntax self: R` receiver first), and the annotation `` #[name @`…`] ``,

%%% whose second `syntax` parameter is the annotated declaration.

%% import code

%% type Query: sql

find() ->
    1.

%% type Num: n

% The number the text writes, read at build.

digits(Text) ->
    N = 0,
    I = 0,
    {N@3, I@3} = (fun __BpLoop({N@1, I@1}) ->
        case (I@1 < erlang:length(unicode:characters_to_list(Text))) of
            true ->
                N@2 = '__bp_int'(('__bp_int'(('__bp_int'((N@1 * 10), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:27:15">>) + (fun(__S, __I) -> case unicode:characters_to_list(__S, utf8) of __L when length(__L) > __I, __I >= 0 -> lists:nth(__I + 1, __L); _ -> -1 end end)(Text, I@1)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:27:20">>) - 48), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/main.bp:27:41">>),
                I@2 = '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:28:15">>),
                __BpLoop({N@2, I@2});
            _ -> {N@1, I@1}
        end
    end)({N, I}),
    N@3.

main() ->
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt0) -> erlang:element(2, _Opt0) end)(array_first([{bp_load_cases_compiler_template_forms@main@@Query, <<"select * from users">>}])) of
        undefined ->
            <<"none">>;
        __bp_nullish ->
            __bp_nullish
    end]),
    A = {bp_load_cases_compiler_template_forms@main@@Num, 1},
    B = {bp_load_cases_compiler_template_forms@main@@Num, '__bp_int'((erlang:element(2, A) + 41), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:41:14">>)},
    '__bp_print'([erlang:element(2, B)]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/compiler_template_forms|*">>.

array_first(Self) ->
    (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Self, 0).

'__bp_prim_append'(Recv, Arg0) when erlang:is_list(Recv) ->
    (Recv ++ Arg0);
'__bp_prim_append'(Recv, _) ->
    erlang:error({bp_unsupported_method, <<"append">>, 1, Recv}).

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

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

'__bp_priv__array_range'(A0, A1) -> array_range(A0, A1).

'__bp_priv__array_repeat'(A0, A1) -> array_repeat(A0, A1).

'__bp_priv__array_first'(A0) -> array_first(A0).
