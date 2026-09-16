----- SOURCE CODE -- main.bp
```botopink
pub fn shout(comptime q: @Expr<string>) -> @Expr<string> {
    val t = q.text().trim();
    val words = t.split(" ").map({ w -> w.toUpper() });
    val lead = t.slice(0, 5);
    val rest = t.slice(6, t.length);
    val all = words.append(["END"]).reverse();
    val at = if (words.at(1) == "BIG") { "at"; } else { "-"; };
    val big = if (t.contains("big")) { "contains"; } else { "-"; };
    val greet = if (lead.startsWith("hel")) { "startsWith"; } else { "-"; };
    val where = if (words.indexOf("WORLD") == 2) { "indexOf"; } else { "-"; };
    return q.build("\"" + all.join(",") + "|" + lead + "|" + rest + "|" + at + "|" + big + "|" + greet + "|" + where + "\"");
}

val s = shout " hello big world ";

fn main() {
    @print(s);
}
```

----- COMPTIME ERLANG -- template shout
```erlang
shout(Q) ->
    T = '__bp_prim_trim'(text(Q)),
    Words = '__bp_prim_map'('__bp_prim_split'(T, <<" ">>), fun(W) ->
        '__bp_prim_toUpper'(W)
    end),
    Lead = '__bp_prim_slice'(T, 0, 5),
    Rest = '__bp_prim_slice'(T, 6, '__bp_len'(T, length)),
    All = '__bp_prim_reverse'('__bp_prim_append'(Words, [<<"END">>])),
    At = case ('__bp_prim_at'(Words, 1) =:= <<"BIG">>) of
        true ->
            <<"at">>;
        false ->
            <<"-">>
    end,
    Big = case '__bp_prim_contains'(T, <<"big">>) of
        true ->
            <<"contains">>;
        false ->
            <<"-">>
    end,
    Greet = case '__bp_prim_startsWith'(Lead, <<"hel">>) of
        true ->
            <<"startsWith">>;
        false ->
            <<"-">>
    end,
    Where = case ('__bp_prim_indexOf'(Words, <<"WORLD">>) =:= 2) of
        true ->
            <<"indexOf">>;
        false ->
            <<"-">>
    end,
    build(Q, '__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'(<<"\"">>, '__bp_prim_join'(All, <<",">>)), <<"|">>), Lead), <<"|">>), Rest), <<"|">>), At), <<"|">>), Big), <<"|">>), Greet), <<"|">>), Where), <<"\"">>)).

main() ->
    try
        json:encode('__bp_reply'(shout(#{
            '__bp_capture' => <<"q">>,
            text => <<" hello big world ">>,
            parts => [
                #{
                    kind => <<"Text">>,
                    text => <<" hello big world ">>,
                    span => #{start => 0, 'end' => 17, line => 1}
                }
            ],
            source => #{file => <<"">>, line => 14, col => 15},
            context => #{
                source => #{file => <<"">>, line => 14, col => 15},
                text => <<" hello big world ">>,
                multiline => false
            },
            bindings => [
                #{name => <<"shout">>, kind => 'Fn'},
                #{name => <<"s">>, kind => 'Val'},
                #{name => <<"main">>, kind => 'Fn'}
            ]
        })))
    catch
        throw:{'__bp_template_fail', Message, Param, Span} ->
            json:encode(#{kind => <<"fail">>, message => '__bp_text'(Message), param => Param, span => '__bp_json'(Span)});
        Class:Reason ->
            json:encode(#{kind => <<"error">>, message => '__bp_text'({Class, Reason})})
    end.
```

----- COMPTIME REPLY -- template shout
```json
{
  "source": "\"END,WORLD,BIG,HELLO|hello|big world|at|contains|startsWith|indexOf\"",
  "kind": "code"
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% interface String

%% interface Array

array_range(Start, Stop) ->
    case (Start >= Stop) of
        true ->
            [];
        false ->
            Head = Start,
            [Head] ++ (array_range((Start + 1), Stop))
    end.

array_repeat(Value, Times) ->
    case (Times =< 0) of
        true ->
            [];
        false ->
            Head = Value,
            [Head] ++ (array_repeat(Value, (Times - 1)))
    end.

s() ->
    <<"END,WORLD,BIG,HELLO|hello|big world|at|contains|startsWith|indexOf">>.

main() ->
    io:format("~p~n", [s()]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
<<"END,WORLD,BIG,HELLO|hello|big world|at|contains|startsWith|indexOf">>
```
