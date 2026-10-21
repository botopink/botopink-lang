%% The second module of the fixture: `greeting` calls it.
-module(greeting_text).
-export([title/1]).

title(<<>>) -> <<"nobody">>;
title(Name) -> string:titlecase(Name).
