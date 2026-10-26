-module(bp_load_cases_type_empty_record@main@@MathOps).
-export([double/2, name/1, '__bp_format'/1]).

double(Self, X) ->
    '__bp_int'((X * 2), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:11:18">>).

name(Self) ->
    <<"ops">>.

'__bp_format'(_) -> {record, "MathOps", []}.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).
