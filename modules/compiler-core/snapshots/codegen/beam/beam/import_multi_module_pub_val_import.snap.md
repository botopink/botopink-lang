----- SOURCE CODE -- config.bp
```botopink
pub val PORT = 8080;
pub val HOST = "localhost";
```

----- BEAM ASSEMBLY -- config.S
```erlang
{module, config}.
{exports, []}.
{attributes, []}.
{labels, 6}.

{function, PORT, 0, 3}.
  {label, 2}.
    {line, [{location, "config.erl", 1}]}.
    {func_info, {atom, config}, {atom, PORT}, 0}.
  {label, 3}.
    {move, {integer, 8080}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, HOST, 0, 5}.
  {label, 4}.
    {line, [{location, "config.erl", 2}]}.
    {func_info, {atom, config}, {atom, HOST}, 0}.
  {label, 5}.
    {move, {literal, <<"localhost">>}, {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {PORT, HOST} from "config";
val addr = HOST;
val port = PORT;
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 6}.

{function, addr, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, addr}, 0}.
  {label, 3}.
    {move, {atom, 'HOST'}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, port, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, port}, 0}.
  {label, 5}.
    {move, {atom, 'PORT'}, {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
