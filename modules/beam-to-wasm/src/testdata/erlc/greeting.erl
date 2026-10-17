%% A module compiled by `erlc` outside botopink: beam-to-wasm's fixture for a
%% `.beam` botopink did not generate (144 B-00b, decision 438).
-module(greeting).
-export([hello/1, shout_all/1, count/1]).

hello(Name) when is_binary(Name) ->
    <<"Hello, ", (greeting_text:title(Name))/binary, "!">>.

shout_all(Names) -> lists:reverse(shout_all(Names, [])).

shout_all([], Acc) -> Acc;
shout_all([N | Rest], Acc) -> shout_all(Rest, [string:uppercase(N) | Acc]).

count(Names) -> count(Names, 0).

count([], N) -> N;
count([_ | Rest], N) -> count(Rest, N + 1).
