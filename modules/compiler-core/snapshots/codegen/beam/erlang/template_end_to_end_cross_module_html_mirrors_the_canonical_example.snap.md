----- SOURCE CODE -- view.bp
```botopink
pub fn html(comptime q: @Expr<string>) -> @Expr<string> {
    var acc = "\"\"";
    for (q.parts()) { p ->
        if (p.kind == "Text") {
            acc = acc + " + \"" + p.text + "\"";
        };
        if (p.kind == "Interp") {
            acc = acc + " + " + p.code;
        };
    };
    return q.build(acc);
}
```

----- ERLANG -- view.erl
```erlang
-module(test@view).
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {html} from "view";

val name = "world";

val page = html
    \\<div>
    \\  <p>${name}</p>
    \\  <Page1/>
    \\</div>
;
fn main() {
    @print(page);
}
```

----- COMPTIME ERLANG -- template html
```erlang
html(Q) ->
    Acc = <<"\"\"">>,
    Acc@6 = lists:foldl(fun(P, Acc@1) ->
        Acc@3 = case (maps:get(kind, P) =:= <<"Text">>) of
            true ->
                Acc@2 = '__bp_add'('__bp_add'('__bp_add'(Acc@1, <<" + \"">>), maps:get(text, P)), <<"\"">>),
                Acc@2;
            _ ->
                Acc@1
        end,
        Acc@5 = case (maps:get(kind, P) =:= <<"Interp">>) of
            true ->
                Acc@4 = '__bp_add'('__bp_add'(Acc@3, <<" + ">>), maps:get(code, P)),
                Acc@4;
            _ ->
                Acc@3
        end,
        Acc@5
    end, Acc, parts(Q)),
    build(Q, Acc@6).

main({Arg0}) ->
    try
        json:encode('__bp_reply'(html(Arg0)))
    catch
        throw:{'__bp_template_fail', Message, Param, Span} ->
            json:encode(#{kind => <<"fail">>, message => '__bp_text'(Message), param => Param, span => '__bp_json'(Span)});
        Class:Reason ->
            json:encode(#{kind => <<"error">>, message => '__bp_text'({Class, Reason})})
    end.

%% main/1 argument — an external term, not part of the module:
%% Arg0 = #{
%%     '__bp_capture' => <<"q">>,
%%     text => <<"<div>\n  <p>__bp_hole_q_0</p>\n  <Page1/>\n</div>">>,
%%     parts => [
%%         #{
%%             kind => <<"Text">>,
%%             text => <<"<div>\n  <p>">>,
%%             span => #{start => 0, 'end' => 11, line => 1}
%%         },
%%         #{
%%             kind => <<"Interp">>,
%%             code => <<"__bp_hole_q_0">>,
%%             span => #{start => 11, 'end' => 24, line => 2}
%%         },
%%         #{
%%             kind => <<"Text">>,
%%             text => <<"</p>\n  <Page1/>\n</div>">>,
%%             span => #{start => 24, 'end' => 46, line => 2}
%%         }
%%     ],
%%     source => #{file => <<"">>, line => 6, col => 5},
%%     context => #{
%%         source => #{file => <<"">>, line => 6, col => 5},
%%         text => <<"<div>\n  <p>__bp_hole_q_0</p>\n  <Page1/>\n</div>">>,
%%         multiline => true
%%     },
%%     bindings => [
%%         #{name => <<"html">>, kind => 'Fn'},
%%         #{name => <<"name">>, kind => 'Val'},
%%         #{name => <<"page">>, kind => 'Val'},
%%         #{name => <<"main">>, kind => 'Fn'}
%%     ]
%% }
```

----- COMPTIME REPLY -- template html
```json
{
  "kind": "code",
  "source": "\"\" + \"<div>\n  <p>\" + __bp_hole_q_0 + \"</p>\n  <Page1/>\n</div>\""
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).

%% import html

name() ->
    <<"world">>.

page() ->
    <<"<div>\n  <p>", (name())/binary, "</p>\n  <Page1/>\n</div>">>.

main() ->
    '__bp_print'([page()]).

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
<div>
  <p>world</p>
  <Page1/>
</div>
```
