-module(text).
-export([shout/1]).

shout(S) -> string:uppercase(S).
