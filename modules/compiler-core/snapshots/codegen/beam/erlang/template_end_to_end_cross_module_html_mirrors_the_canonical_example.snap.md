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

----- COMPTIME BEAM ASSEMBLY -- template html
```erlang
{module, template_module}.
{exports, [{html, 1}, {main, 1}]}.
{attributes, []}.
{labels, 35}.

{function, '-html/1-fun-0-', 2, 10}.
  {label, 9}.
    {func_info, {atom, template_module}, {atom, '-html/1-fun-0-'}, 2}.
  {label, 10}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {x, 1}, {y, 5}}.
    {move, {atom, kind}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, maps, get, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {literal, <<"Text">>}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 14}, [{x, 0}, {atom, true}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {literal, <<" + \"">>}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {atom, text}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, maps, get, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {literal, <<"\"">>}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 0}}.
    {jump, {f, 16}}.
  {label, 16}.
    {move, {y, 0}, {y, 7}}.
    {jump, {f, 13}}.
  {label, 14}.
    {move, {y, 5}, {y, 7}}.
    {jump, {f, 13}}.
  {label, 13}.
    {move, {y, 7}, {y, 1}}.
    {jump, {f, 19}}.
  {label, 19}.
    {move, {atom, kind}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, maps, get, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {literal, <<"Interp">>}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 21}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {literal, <<" + ">>}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {atom, code}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, maps, get, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 2}}.
    {jump, {f, 23}}.
  {label, 23}.
    {move, {y, 2}, {y, 7}}.
    {jump, {f, 20}}.
  {label, 21}.
    {move, {y, 1}, {y, 7}}.
    {jump, {f, 20}}.
  {label, 20}.
    {move, {y, 7}, {y, 3}}.
    {jump, {f, 26}}.
  {label, 26}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 10}.
    return.

{function, html, 1, 2}.
  {label, 1}.
    {func_info, {atom, template_module}, {atom, html}, 1}.
  {label, 2}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"\"\"">>}, {y, 0}}.
    {jump, {f, 8}}.
  {label, 8}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 10}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_template, parts, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {move, {y, 4}, {x, 2}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 28}}.
  {label, 28}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, bp_comptime_template, build, 2}, 5}.

{function, main, 1, 4}.
  {label, 3}.
    {func_info, {atom, template_module}, {atom, main}, 1}.
  {label, 4}.
    {allocate, 19, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 30}, [{x, 0}]}.
    {test, test_arity, {f, 30}, [{x, 0}, 1]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {move, {y, 7}, {y, 0}}.
    {'try', {y, 18}, {f, 31}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_template, '__bp_reply', 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, json, encode, 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 8}}.
    {try_end, {y, 18}}.
    {jump, {f, 32}}.
  {label, 31}.
    {try_case, {y, 18}}.
    {move, {x, 0}, {y, 9}}.
    {move, {x, 1}, {y, 10}}.
    {move, {x, 2}, {y, 11}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 34}, [{x, 0}, {atom, throw}]}.
    {move, {y, 10}, {x, 0}}.
    {test, is_tuple, {f, 34}, [{x, 0}]}.
    {test, test_arity, {f, 34}, [{x, 0}, 4]}.
    {get_tuple_element, {x, 0}, 0, {y, 12}}.
    {get_tuple_element, {x, 0}, 1, {y, 13}}.
    {get_tuple_element, {x, 0}, 2, {y, 14}}.
    {get_tuple_element, {x, 0}, 3, {y, 15}}.
    {move, {y, 12}, {x, 0}}.
    {test, is_eq_exact, {f, 34}, [{x, 0}, {atom, '__bp_template_fail'}]}.
    {move, {y, 13}, {y, 1}}.
    {move, {y, 14}, {y, 2}}.
    {move, {y, 15}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_template, '__bp_text', 1}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_template, '__bp_json', 1}}.
    {move, {x, 0}, {y, 17}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, kind}, {literal, <<"fail">>}, {atom, message}, {y, 16}, {atom, param}, {y, 2}, {atom, span}, {y, 17}]}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {x, 0}}.
    {call_ext, 1, {extfunc, json, encode, 1}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {y, 8}}.
    {jump, {f, 33}}.
  {label, 34}.
    {move, {y, 9}, {y, 4}}.
    {move, {y, 10}, {y, 5}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_template, '__bp_text', 1}}.
    {move, {x, 0}, {y, 12}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, kind}, {literal, <<"error">>}, {atom, message}, {y, 12}]}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {call_ext, 1, {extfunc, json, encode, 1}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {y, 8}}.
    {jump, {f, 33}}.
  {label, 33}.
  {label, 32}.
    {move, {y, 8}, {x, 0}}.
    {deallocate, 19}.
    return.
  {label, 30}.
    {move, {y, 6}, {x, 0}}.
    {deallocate, 19}.
    {jump, {f, 3}}.

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
%%         #{
%%             name => <<"html">>,
%%             kind => 'Fn',
%%             identity => <<"view@@html">>,
%%             local => <<"html">>
%%         },
%%         #{
%%             name => <<"name">>,
%%             kind => 'Val',
%%             identity => <<"main@@name">>,
%%             local => <<"name">>
%%         },
%%         #{
%%             name => <<"page">>,
%%             kind => 'Val',
%%             identity => <<"main@@page">>,
%%             local => <<"page">>
%%         },
%%         #{
%%             name => <<"main">>,
%%             kind => 'Fn',
%%             identity => <<"main@@main">>,
%%             local => <<"main">>
%%         }
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
'__bp_show'(undefined, _) -> "null";
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
