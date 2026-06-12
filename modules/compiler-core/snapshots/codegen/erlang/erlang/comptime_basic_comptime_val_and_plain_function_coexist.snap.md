----- SOURCE CODE -- main.bp
```botopink
val x = comptime 1 + 2;

fn double(n: i32) -> i32 {
    return n * 2;
}

fn main() {
    val r = double(21);
}
```

----- COMPTIME ERLANG -- main.erl
```erlang
(module
  (import "wasi_snapshot_preview1" "fd_write"
    (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (data (i32.const 8) "[{\"id\":\"ct_0\",\"value\":3}]")
  (func $main (export "_start")
    (i32.store (i32.const 0) (i32.const 8))
    (i32.store (i32.const 4) (i32.const 25))
    (drop (call $fd_write (i32.const 1) (i32.const 0) (i32.const 1) (i32.const 200))))
)
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).


double(N) ->
    (N * 2).

main() ->
    R = double(21).

'_botopink_main'() ->
    X = 3,
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```
