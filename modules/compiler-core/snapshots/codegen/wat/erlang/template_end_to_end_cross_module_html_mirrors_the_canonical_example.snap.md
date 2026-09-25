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

----- COMPTIME WAT -- template html
```wat
(func $html/1 (param $a0 i32) (result i32)
  (local $V_Q i32) (local $t1 i32) (local $V_Acc i32) (local $t2 i32) (local $t3 i32) (local $V_Acc@6 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Q
  global.get $__lit
  i32.const 224
  i32.add
  i32.const 2
  call $rt_bin
  local.set $t1
  (block $L4
  (block $L3
  local.get $t1
  local.set $V_Acc
  br $L4
  )
  local.get $t1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t1
  drop
  call $rt_nil
  local.set $t2
  global.get $__tbase
  i32.const 0
  i32.add
  i32.const 2
  local.get $t2
  call $rt_make_fun
  local.get $V_Acc
  local.get $V_Q
  call $bp_comptime_template:parts/1
  call $rt_pending
  br_if $raise
  call $rt_lists_foldl
  call $rt_pending
  br_if $raise
  local.set $t3
  (block $L6
  (block $L5
  local.get $t3
  local.set $V_Acc@6
  br $L6
  )
  local.get $t3
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t3
  drop
  local.get $V_Q
  local.get $V_Acc@6
  call $bp_comptime_template:build/2
  call $rt_pending
  br_if $raise
  br $L1
  )
  call $rt_function_clause
  drop
  br $raise
  )
  return
  )
  i32.const 0
)

(func $fun1:html/1 (param $self i32) (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_P i32) (local $V_Acc@1 i32) (local $t1 i32) (local $t2 i32) (local $V_Acc@2 i32) (local $t3 i32) (local $V_Acc@3 i32) (local $t4 i32) (local $t5 i32) (local $V_Acc@4 i32) (local $t6 i32) (local $V_Acc@5 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_P
  local.get $a1
  local.set $V_Acc@1
  global.get $__lit
  i32.const 32
  i32.add
  i32.const 4
  call $rt_atom
  local.get $V_P
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 232
  i32.add
  i32.const 4
  call $rt_bin
  call $rt_eqx
  call $rt_bool
  local.set $t1
  (block $L3 (result i32)
  (block $L4
  local.get $t1
  global.get $__lit
  i32.const 240
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L4
  local.get $V_Acc@1
  global.get $__lit
  i32.const 248
  i32.add
  i32.const 4
  call $rt_bin
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 256
  i32.add
  i32.const 4
  call $rt_atom
  local.get $V_P
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 264
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  local.set $t2
  (block $L6
  (block $L5
  local.get $t2
  local.set $V_Acc@2
  br $L6
  )
  local.get $t2
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t2
  drop
  local.get $V_Acc@2
  br $L3
  )
  (block $L7
  local.get $V_Acc@1
  br $L3
  )
  local.get $t1
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $t3
  (block $L9
  (block $L8
  local.get $t3
  local.set $V_Acc@3
  br $L9
  )
  local.get $t3
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t3
  drop
  global.get $__lit
  i32.const 32
  i32.add
  i32.const 4
  call $rt_atom
  local.get $V_P
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 272
  i32.add
  i32.const 6
  call $rt_bin
  call $rt_eqx
  call $rt_bool
  local.set $t4
  (block $L10 (result i32)
  (block $L11
  local.get $t4
  global.get $__lit
  i32.const 240
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L11
  local.get $V_Acc@3
  global.get $__lit
  i32.const 280
  i32.add
  i32.const 3
  call $rt_bin
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 96
  i32.add
  i32.const 4
  call $rt_atom
  local.get $V_P
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  local.set $t5
  (block $L13
  (block $L12
  local.get $t5
  local.set $V_Acc@4
  br $L13
  )
  local.get $t5
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t5
  drop
  local.get $V_Acc@4
  br $L10
  )
  (block $L14
  local.get $V_Acc@3
  br $L10
  )
  local.get $t4
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $t6
  (block $L16
  (block $L15
  local.get $t6
  local.set $V_Acc@5
  br $L16
  )
  local.get $t6
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t6
  drop
  local.get $V_Acc@5
  br $L1
  )
  call $rt_function_clause
  drop
  br $raise
  )
  return
  )
  i32.const 0
)

;; main/1 argument — an external term, not part of the module:
;; Arg0 = #{
;;     '__bp_capture' => <<"q">>,
;;     text => <<"<div>\n  <p>__bp_hole_q_0</p>\n  <Page1/>\n</div>">>,
;;     parts => [
;;         #{
;;             kind => <<"Text">>,
;;             text => <<"<div>\n  <p>">>,
;;             span => #{start => 0, 'end' => 11, line => 1}
;;         },
;;         #{
;;             kind => <<"Interp">>,
;;             code => <<"__bp_hole_q_0">>,
;;             span => #{start => 11, 'end' => 24, line => 2}
;;         },
;;         #{
;;             kind => <<"Text">>,
;;             text => <<"</p>\n  <Page1/>\n</div>">>,
;;             span => #{start => 24, 'end' => 46, line => 2}
;;         }
;;     ],
;;     source => #{file => <<"">>, line => 6, col => 5},
;;     context => #{
;;         source => #{file => <<"">>, line => 6, col => 5},
;;         text => <<"<div>\n  <p>__bp_hole_q_0</p>\n  <Page1/>\n</div>">>,
;;         multiline => true
;;     },
;;     bindings => [
;;         #{name => <<"html">>, kind => 'Fn'},
;;         #{name => <<"name">>, kind => 'Val'},
;;         #{name => <<"page">>, kind => 'Val'},
;;         #{name => <<"main">>, kind => 'Fn'}
;;     ]
;; }
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
