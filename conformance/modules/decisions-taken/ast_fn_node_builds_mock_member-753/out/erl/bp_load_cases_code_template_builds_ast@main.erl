-module(bp_load_cases_code_template_builds_ast@main).
-export(['_botopink_main'/0, main/1]).
-export([label/2, main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0]).

%%% Decisions 625 (4), 637 — `code`, std's template over the typed AST: a

%%% template answers the code it writes with `${…}` holes, read into

%%% `compiler.Node` records and built as `compiler.ast` builds them. Each

%%% hole is read by its arrival: a value known at build is spliced as its

%%% literal (`tagged`, `scaled`), a `syntax` value as it was written — the

%%% caller's holes, `compiler.holes(t)`, typed where they land (`element`).

%%% A typed function and its type nodes are written the same way (`shape`,

%%% decision 753).

%% import code

%% type Element: tag, kids

label(Tag, Size) ->
    <<Tag/binary, ":", ('__bp_text'(erlang:integer_to_binary(Size)))/binary>>.

main() ->
    '__bp_print'([string:uppercase(label(<<"box">>, 3))]),
    Name = <<"ana">>,
    E = {bp_load_cases_code_template_builds_ast@main@@Element, <<"div">>, [Name, <<Name/binary, "!">>]},
    '__bp_print'([<<('__bp_text'(erlang:element(2, E)))/binary, " ", ('__bp_text'(iolist_to_binary(lists:join(<<",">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, erlang:element(3, E))))))/binary>>]),
    Big = case (5 > 3) of
        true ->
            lists:map(fun(X) ->
                '__bp_int'((X * 5), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:49:32">>)
            end, [1, 2, 3]);
        false ->
            [(-5), (5 rem 2)]
    end,
    '__bp_print'([iolist_to_binary(lists:join(<<", ">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, lists:map(fun(X) ->
        erlang:integer_to_binary(X)
    end, Big))))]),
    Small = case (2 > 3) of
        true ->
            lists:map(fun(X) ->
                '__bp_int'((X * 2), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:51:34">>)
            end, [1, 2, 3]);
        false ->
            [(-2), (2 rem 2)]
    end,
    '__bp_print'([iolist_to_binary(lists:join(<<", ">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, lists:map(fun(X) ->
        erlang:integer_to_binary(X)
    end, Small))))]),
    {Word, Size} = {<<"four">>, '__bp_int'((erlang:length(unicode:characters_to_list(<<"four">>)) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:53:32">>)},
    '__bp_print'([<<('__bp_text'(Word))/binary, " ", ('__bp_text'(erlang:integer_to_binary(Size)))/binary>>]),
    Run = fun(Xs, Pick, F) ->
        {F(erlang:length(Xs)), 5}
    end,
    Out = Run([1, 2, 3], undefined, fun(X) ->
        '__bp_int'((X * 10), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:56:45">>)
    end),
    '__bp_print'([<<('__bp_text'(erlang:integer_to_binary(erlang:element(1, Out))))/binary, " ", ('__bp_text'(erlang:integer_to_binary(erlang:element(2, Out))))/binary>>]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/code_template_builds_ast|*">>.

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
