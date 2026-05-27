----- SOURCE CODE -- main.bp
```botopink
use { foo, bar } from "mylib";
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 2}.
```

----- RUN LOG -----
```logs
```
