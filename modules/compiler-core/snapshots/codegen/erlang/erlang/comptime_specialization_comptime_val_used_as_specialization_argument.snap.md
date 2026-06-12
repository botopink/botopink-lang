----- SOURCE CODE -- main.bp
```botopink
val base = comptime 10 + 5;

fn scale(comptime factor: i32, value: i32) -> i32 {
    return value * factor;
}

fn main() {
    val doubled = scale(2, base);
    val tripled = scale(3, base);
    val doubledAgain = scale(2, 100);
}
```

----- COMPTIME ERLANG -- main.erl
```erlang
(module
  (import "wasi_snapshot_preview1" "fd_write"
    (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (data (i32.const 8) "[{\"id\":\"ct_0\",\"value\":15}]")
  (func $main (export "_start")
    (i32.store (i32.const 0) (i32.const 8))
    (i32.store (i32.const 4) (i32.const 26))
    (drop (call $fd_write (i32.const 1) (i32.const 0) (i32.const 1) (i32.const 200))))
)
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).


main() ->
    Doubled = 'scale_$0'(Base),
    Tripled = 'scale_$1'(Base),
    DoubledAgain = 'scale_$0'(100).

'scale_$0'(Value) ->
    Factor = 2,
    (Value * Factor).

'scale_$1'(Value) ->
    Factor = 3,
    (Value * Factor).

'_botopink_main'() ->
    Base = 15,
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```
