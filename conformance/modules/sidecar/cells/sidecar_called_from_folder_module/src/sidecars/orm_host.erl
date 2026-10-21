-module(orm_host).
-export([table/1]).

table(Name) -> <<"table ", Name/binary>>.
