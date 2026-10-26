-module(std@context@@RenderScope).
-export([root/0, '__bp_get'/2, '__bp_format'/1]).

root() ->
    {std@context@@RenderScope, undefined}.

'__bp_get'(V, frames) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "RenderScope", [{"frames", erlang:element(2, V)}]}.
