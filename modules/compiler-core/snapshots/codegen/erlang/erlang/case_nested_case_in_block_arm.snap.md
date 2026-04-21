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
