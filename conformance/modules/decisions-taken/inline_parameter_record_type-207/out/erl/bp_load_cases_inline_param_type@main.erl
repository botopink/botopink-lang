-module(bp_load_cases_inline_param_type@main).
-compile({no_auto_import,[link/1]}).
-export(['_botopink_main'/0, main/1]).
-export([link/1, main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__again'/1, '__bp_priv__scaled'/2]).

%%% Decision 207 — a parameter's type written inline: `props: type(href:

%%% string, label: string, external: bool = false)`, the field grammar of

%%% `type Name(…)` with no name. The call builds the value from its own

%%% labelled arguments, each naming a field of the inline type (in any order,

%%% a defaulted field left out); a value already of the type is passed as the

%%% parameter itself; another parameter of the function stays an ordinary one.

%% type BpInline__link__props: href, label, external

link(Props) ->
    Mark = case erlang:element(4, Props) of
        true ->
            <<" (external)">>;
        false ->
            <<"">>
    end,
    <<('__bp_text'(erlang:element(3, Props)))/binary, " <", ('__bp_text'(erlang:element(2, Props)))/binary, ">", ('__bp_text'(Mark))/binary>>.

%% type BpInline__again__props: href, label, external

again(Props) ->
    link({bp_load_cases_inline_param_type@main@@BpInline__link__props, erlang:element(2, Props), erlang:element(3, Props), false}).

%% type BpInline__scaled__props: n, unit

scaled(Props, Times) ->
    '__bp_add'(erlang:integer_to_binary(('__bp_int'((erlang:element(2, Props) * Times), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:24:21">>))), erlang:element(3, Props)).

main() ->
    '__bp_print'([link({bp_load_cases_inline_param_type@main@@BpInline__link__props, <<"/a">>, <<"A">>, false})]),
    '__bp_print'([link({bp_load_cases_inline_param_type@main@@BpInline__link__props, <<"/b">>, <<"B">>, true})]),
    '__bp_print'([again({bp_load_cases_inline_param_type@main@@BpInline__again__props, <<"/c">>, <<"C">>, true})]),
    '__bp_print'([scaled({bp_load_cases_inline_param_type@main@@BpInline__scaled__props, 4, <<"px">>}, 3)]),
    '__bp_print'([scaled({bp_load_cases_inline_param_type@main@@BpInline__scaled__props, 5, <<"em">>}, 2)]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/inline_param_type|*">>.

'__bp_add'(A, B) when erlang:is_binary(A), erlang:is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

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
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__again'(A0) -> again(A0).

'__bp_priv__scaled'(A0, A1) -> scaled(A0, A1).
