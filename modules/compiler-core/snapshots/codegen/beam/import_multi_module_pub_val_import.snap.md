----- SOURCE CODE -- config.bp
```botopink
pub val PORT = 8080;
pub val HOST = "localhost";
```

----- BEAM ASSEMBLY -- config.S
```erlang
{module, test@config}.
{exports, [{'PORT', 0}, {'HOST', 0}]}.
{attributes, []}.
{labels, 6}.

{function, 'PORT', 0, 3}.
  {label, 2}.
    {line, [{location, "test@config.erl", 1}]}.
    {func_info, {atom, test@config}, {atom, 'PORT'}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {integer, 8080}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, 'HOST', 0, 5}.
  {label, 4}.
    {line, [{location, "test@config.erl", 2}]}.
    {func_info, {atom, test@config}, {atom, 'HOST'}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {move, {literal, <<"localhost">>}, {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {config.PORT, config.HOST};
val addr = HOST;
val port = PORT;
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'__bp_priv__addr', 0}, {'__bp_priv__port', 0}]}.
{attributes, []}.
{labels, 10}.

{function, addr, 0, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, addr}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {call_ext, 0, {extfunc, test@config, 'HOST', 0}}.
    {deallocate, 0}.
    return.

{function, port, 0, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, port}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {call_ext, 0, {extfunc, test@config, 'PORT', 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_priv__addr', 0, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__addr'}, 0}.
  {label, 7}.
    {call_only, 0, {f, 3}}.

{function, '__bp_priv__port', 0, 9}.
  {label, 8}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__port'}, 0}.
  {label, 9}.
    {call_only, 0, {f, 5}}.
```

----- RUN LOG -----
```logs
```
