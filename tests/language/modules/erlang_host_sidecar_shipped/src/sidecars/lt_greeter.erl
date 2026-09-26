-module(lt_greeter).
-export([hello/1]).

hello(Name) -> <<"hello, ", Name/binary>>.
