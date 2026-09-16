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

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 16}.

{function, 'Array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, 'Array_range'}, 2}.
  {label, 3}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 12}, [{y, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 13}}.
  {label, 12}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
  {label, 13}.
    {deallocate, 4}.
    return.

{function, 'Array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, 'Array_repeat'}, 2}.
  {label, 5}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 14}, [{integer, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 15}}.
  {label, 14}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{y, 1}, {integer, 1}], {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
  {label, 15}.
    {deallocate, 4}.
    return.

{function, main, 0, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {move, {atom, s}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 9}.
  {label, 8}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '_botopink_main'}, 0}.
  {label, 9}.
    {call_only, 0, {f, 7}}.

{function, main, 1, 11}.
  {label, 10}.
    {line, [{location, "main.erl", 5}]}.
    {func_info, {atom, main}, {atom, main}, 1}.
  {label, 11}.
    {call_only, 0, {f, 9}}.
```

----- RUN LOG -----
```logs
s
```
