----- SOURCE CODE -- main.bp
```botopink
val greeting = "ola mundo";
pub fn refer(comptime q: @Expr<string>) -> @Expr<string> {
    val hit = q.lookup("greeting");
    if (hit) { b ->
        return b.ref();
    } else {
        return q.fail("greeting not found in caller scope");
    };
}
val s = refer "x";
fn main() {
    @print(s);
}
```

----- COMPTIME ERLANG -- template refer
```erlang
refer(Q) ->
    Hit = lookup(Q, <<"greeting">>),
    case Hit of
        undefined ->
            fail(Q, <<"greeting not found in caller scope">>);
        B ->
            ref(B)
    end.

main() ->
    try
        json:encode('__bp_reply'(refer(#{
            '__bp_capture' => <<"q">>,
            text => <<"x">>,
            parts => [
                #{
                    kind => <<"Text">>,
                    text => <<"x">>,
                    span => #{start => 0, 'end' => 1, line => 1}
                }
            ],
            source => #{file => <<"">>, line => 10, col => 15},
            context => #{
                source => #{file => <<"">>, line => 10, col => 15},
                text => <<"x">>,
                multiline => false
            },
            bindings => [
                #{name => <<"greeting">>, kind => 'Val'},
                #{name => <<"refer">>, kind => 'Fn'},
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

----- COMPTIME REPLY -- template refer
```json
{
  "source": "greeting",
  "kind": "code"
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 21}.

{function, greeting, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, greeting}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {literal, <<"ola mundo">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, s, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, s}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {call, 0, {f, 3}}.
    {deallocate, 0}.
    return.

{function, main, 0, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {call, 0, {f, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 13}}.
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

{function, '__bp_print', 1, 13}.
  {label, 12}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '__bp_print'}, 1}.
  {label, 13}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 1, {f, 15}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '__bp_print_fmt', 1, 15}.
  {label, 14}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '__bp_print_fmt'}, 1}.
  {label, 15}.
    {test, is_nonempty_list, {f, 18}, [{x, 0}]}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {get_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 1}, {y, 0}}.
    {call, 1, {f, 17}}.
    {test, is_binary, {f, 19}, [{y, 0}]}.
    {test_heap, 6, 1}.
    {put_list, {integer, 115}, {x, 0}, {x, 0}}.
    {put_list, {integer, 116}, {x, 0}, {x, 0}}.
    {put_list, {integer, 126}, {x, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 19}.
    {test_heap, 4, 1}.
    {put_list, {integer, 112}, {x, 0}, {x, 0}}.
    {put_list, {integer, 126}, {x, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 18}.
    {move, {literal, [126, 110]}, {x, 0}}.
    return.

{function, '__bp_print_sep', 1, 17}.
  {label, 16}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '__bp_print_sep'}, 1}.
  {label, 17}.
    {test, is_nonempty_list, {f, 20}, [{x, 0}]}.
    {allocate, 0, 1}.
    {call, 1, {f, 15}}.
    {test_heap, 2, 1}.
    {put_list, {integer, 32}, {x, 0}, {x, 0}}.
    {deallocate, 0}.
    return.
  {label, 20}.
    {move, {literal, [126, 110]}, {x, 0}}.
    return.
```

----- RUN LOG -----
```logs
ola mundo
```
