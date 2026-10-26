-module(conformance_lib@records@@Snap).
-export([isEmpty/1, '__bp_get'/2, '__bp_format'/1]).

isEmpty(Self) ->
    (((((erlang:length(erlang:element(2, Self)) =:= 0) andalso (erlang:length(erlang:element(3, Self)) =:= 0)) andalso (erlang:element(4, Self) =:= <<"">>)) andalso (not erlang:element(5, Self))) andalso (erlang:length(erlang:element(6, Self)) =:= 0)).

'__bp_get'(V, refusals) -> erlang:element(2, V);
'__bp_get'(V, build) -> erlang:element(3, V);
'__bp_get'(V, stdout) -> erlang:element(4, V);
'__bp_get'(V, abort) -> erlang:element(5, V);
'__bp_get'(V, stderr) -> erlang:element(6, V).

'__bp_format'(V) -> {record, "Snap", [{"refusals", erlang:element(2, V)}, {"build", erlang:element(3, V)}, {"stdout", erlang:element(4, V)}, {"abort", erlang:element(5, V)}, {"stderr", erlang:element(6, V)}]}.
