-module(bp_load_cases_decorator_member_fn_tail@main@@Account).
-compile({no_auto_import,[size/1]}).
-export([size/1, '__bp_get'/2, '__bp_format'/1]).

size(Self) ->
    '__bp_int'((erlang:length(unicode:characters_to_list(erlang:element(2, Self))) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:31:51">>).

'__bp_get'(V, name) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Account", [{"name", erlang:element(2, V)}]}.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).
