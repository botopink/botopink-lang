----- SOURCE CODE -- main.bp
```botopink
val result = case 42 {
    0 -> {
      case 1 {
          0    -> 54;
          _ -> 1;
      };
   };
   _ -> 1;
};
```

----- ERLANG -- main.erl
```erlang
-module(main).

result() ->
    case 42 of
        0 ->
            case 1 of
                0 ->
                    54;
                _ ->
                    1
            end;
        _ ->
            1
    end.
```

----- RUN LOG -----
```logs
Error! main:main/0 is not exported.

Runtime terminating during boot ({undef,[{main,main,[],[]},{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```
