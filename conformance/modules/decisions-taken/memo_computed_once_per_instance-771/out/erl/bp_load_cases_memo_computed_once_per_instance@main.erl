-module(bp_load_cases_memo_computed_once_per_instance@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__Page'/1]).

%% import bpScopePush__, bpScopeFind__, bpScopeRendered__, bpScopeValue__, bpScopeRoot__, bpMemoNew__, bpMemoRead__

%%% Decisions 755, 771 — `use memo({ -> make })` is std's

%%% `hooks.memo<T>(make: fn() -> T) -> Component<T>`: one slot per `use memo`

%%% position, allocated when one `Page(…)` call makes the component value; its

%%% first render runs `make` and fills the slot, a later render of the same

%%% value reads it. `a` rendered twice makes its label and its count once;

%%% `b`, another value of the same component, makes its own.

%% import RenderScope, memo

%% type Element: text

'Page'(Name) ->
    BpMemoSlot__0 = std@hooks:slot(),
    BpMemoSlot__1 = std@hooks:slot(),
    fun(BpScope__) ->
        Label = std@hooks:read(BpMemoSlot__0, fun() ->
            '__bp_print'([<<"label ", Name/binary>>]),
            <<"page ", Name/binary>>
        end),
        Count = std@hooks:read(BpMemoSlot__1, fun() ->
            '__bp_print'([<<"count ", Name/binary>>]),
            '__bp_int'((erlang:length(unicode:characters_to_list(Name)) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:19:21">>)
        end),
        std@context:rendered({bp_load_cases_memo_computed_once_per_instance@main@@Element, <<('__bp_text'(Label))/binary, " ", ('__bp_text'(erlang:integer_to_binary(Count)))/binary>>}, BpScope__)
    end.

%% @Async — eager lowering
main() ->
    A = 'Page'(<<"a">>),
    B = 'Page'(<<"bb">>),
    First = '__bp_field'(((A)(std@context@@RenderScope:root())), value),
    '__bp_print'([erlang:element(2, First)]),
    Again = '__bp_field'(((A)(std@context@@RenderScope:root())), value),
    '__bp_print'([erlang:element(2, Again)]),
    Other = '__bp_field'(((B)(std@context@@RenderScope:root())), value),
    '__bp_print'([erlang:element(2, Other)]),
    Last = '__bp_field'(((A)(std@context@@RenderScope:root())), value),
    '__bp_print'([erlang:element(2, Last)]).

%% @Async — eager lowering
'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

%% @Async — eager lowering
'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/memo_computed_once_per_instance|*">>.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

'__bp_field'(V, F) when erlang:is_map(V) -> maps:get(F, V);
'__bp_field'(V, F) -> erlang:apply(erlang:element(1, V), '__bp_get', [V, F]).

'__bp_text'(Value) when erlang:is_binary(Value) -> Value;
'__bp_text'(Value) -> unicode:characters_to_binary('__bp_show'(Value, true)).

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

'__bp_priv__Page'(A0) -> 'Page'(A0).
