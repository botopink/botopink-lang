----- SOURCE CODE -- main.bp
```botopink
val greeting = "ola mundo";
pub fn refer(comptime q: @Expr<string>) -> @Expr<string> {
    val hit = q.lookup("greeting");
    if (hit) { b ->
        return q.build(b.name);
    } else {
        return q.fail("greeting not found in caller scope");
    };
}
val s = refer "greeting";
fn main() {
    @print(s);
}
```

----- COMPTIME WAT -- template refer
```wat
(func $refer/1 (param $a0 i32) (result i32)
  (local $V_Q i32) (local $s1 i32) (local $s2 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Q
  local.get $V_Q
  global.get $__lit
  i32.const 288
  i32.add
  i32.const 8
  call $rt_bin
  call $bp_comptime_template:lookup/2
  call $rt_pending
  br_if $raise
  local.set $s1
  (block $L4
  (block $L3
  local.get $s1
  local.set $s2
  br $L4
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  local.get $s2
  local.set $s1
  (block $L5 (result i32)
  (block $L6
  local.get $s1
  global.get $__lit
  i32.const 112
  i32.add
  i32.const 9
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L6
  local.get $V_Q
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 34
  call $rt_bin
  call $bp_comptime_template:fail/2
  call $rt_pending
  br_if $raise
  br $L5
  )
  (block $L7
  local.get $s1
  local.set $s2
  local.get $V_Q
  global.get $__lit
  i32.const 336
  i32.add
  i32.const 4
  call $rt_atom
  local.get $s2
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $bp_comptime_template:build/2
  call $rt_pending
  br_if $raise
  br $L5
  )
  local.get $s1
  call $rt_case_clause
  drop
  br $raise
  )
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
;;     text => <<"greeting">>,
;;     parts => [
;;         #{
;;             kind => <<"Text">>,
;;             text => <<"greeting">>,
;;             span => #{start => 0, 'end' => 8, line => 1}
;;         }
;;     ],
;;     source => #{file => <<"">>, line => 10, col => 15},
;;     context => #{
;;         source => #{file => <<"">>, line => 10, col => 15},
;;         text => <<"greeting">>,
;;         multiline => false
;;     },
;;     bindings => [
;;         #{
;;             kind => 'Val',
;;             name => <<"greeting">>,
;;             fields => [],
;;             variants => [],
;;             methods => [],
;;             returnType => <<"">>,
;;             annotations => [],
;;             hooks => [],
;;             params => [],
;;             component => undefined,
;;             module => <<"">>,
;;             meta => [],
;;             identity => <<"main@@greeting">>,
;;             local => <<"greeting">>
;;         }
;;     ],
;;     words => [<<"greeting">>]
;; }
```

----- COMPTIME REPLY -- template refer
```json
{
  "kind": "code",
  "source": "greeting"
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, greeting/0, s/0]).

greeting() ->
    <<"ola mundo">>.

s() ->
    greeting().

main() ->
    '__bp_print'([s()]).

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
```

----- RUN LOG -----
```logs
ola mundo
```
