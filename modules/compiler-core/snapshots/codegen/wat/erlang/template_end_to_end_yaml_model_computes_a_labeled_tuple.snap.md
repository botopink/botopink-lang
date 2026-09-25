----- SOURCE CODE -- main.bp
```botopink
pub fn conf<T>(comptime q: @Expr<string>) -> @Expr<T> {
    val t = q.text();
    val port = 8000 + t.length;
    val debug = true;
    return @expr(#(port, debug));
}
val cfg = conf "yaml";
fn main() {
    @print(cfg.port + 1);
}
```

----- COMPTIME WAT -- template conf
```wat
(func $conf/1 (param $a0 i32) (result i32)
  (local $V_Q i32) (local $t1 i32) (local $V_T i32) (local $t2 i32) (local $V_Port i32) (local $t3 i32) (local $V_Debug i32) (local $t4 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Q
  local.get $V_Q
  call $bp_comptime_template:text/1
  call $rt_pending
  br_if $raise
  local.set $t1
  (block $L4
  (block $L3
  local.get $t1
  local.set $V_T
  br $L4
  )
  local.get $t1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t1
  drop
  i64.const 8000
  call $rt_int
  local.get $V_T
  global.get $__lit
  i32.const 224
  i32.add
  i32.const 6
  call $rt_atom
  call $bp_comptime_template:__bp_len/2
  call $rt_pending
  br_if $raise
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  local.set $t2
  (block $L6
  (block $L5
  local.get $t2
  local.set $V_Port
  br $L6
  )
  local.get $t2
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t2
  drop
  global.get $__lit
  i32.const 232
  i32.add
  i32.const 4
  call $rt_atom
  local.set $t3
  (block $L8
  (block $L7
  local.get $t3
  local.set $V_Debug
  br $L8
  )
  local.get $t3
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t3
  drop
  i32.const 2
  call $rt_tuple
  local.set $t4
  local.get $t4
  i32.const 0
  local.get $V_Port
  call $rt_tset
  drop
  local.get $t4
  i32.const 1
  local.get $V_Debug
  call $rt_tset
  drop
  local.get $t4
  call $bp_comptime_template:expr/1
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

;; main/1 argument — an external term, not part of the module:
;; Arg0 = #{
;;     '__bp_capture' => <<"q">>,
;;     text => <<"yaml">>,
;;     parts => [
;;         #{
;;             kind => <<"Text">>,
;;             text => <<"yaml">>,
;;             span => #{start => 0, 'end' => 4, line => 1}
;;         }
;;     ],
;;     source => #{file => <<"">>, line => 7, col => 16},
;;     context => #{
;;         source => #{file => <<"">>, line => 7, col => 16},
;;         text => <<"yaml">>,
;;         multiline => false
;;     },
;;     bindings => [
;;         #{name => <<"conf">>, kind => 'Fn'},
;;         #{name => <<"cfg">>, kind => 'Val'},
;;         #{name => <<"main">>, kind => 'Fn'}
;;     ]
;; }
```

----- COMPTIME REPLY -- template conf
```json
{
  "kind": "value",
  "value": {
    "$tuple": [
      8004,
      true
    ]
  }
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).

cfg() ->
    {8004, true}.

main() ->
    '__bp_print'([(element(1, cfg()) + 1)]).

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
8005
```
