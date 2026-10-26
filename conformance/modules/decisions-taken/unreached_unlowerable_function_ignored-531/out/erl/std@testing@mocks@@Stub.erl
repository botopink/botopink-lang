-module(std@testing@mocks@@Stub).
-export([thenReturn/2, thenThrow/2, '__bp_get'/2, '__bp_format'/1]).

thenReturn(Self, V) ->
    _r = (fun(OzV__) -> case get('__bp_mocks_pending_stub') of undefined -> ok; {OzId__, OzM__, OzMs__} -> put('__bp_mocks_stubs', case get('__bp_mocks_stubs') of undefined -> []; OzL__ -> OzL__ end ++ [{OzId__, OzM__, OzMs__, return, OzV__}]) end, put('__bp_mocks_pending_stub', undefined), 0 end)(V),
    true.

thenThrow(Self, Message) ->
    _r = (fun(OzV__) -> case get('__bp_mocks_pending_stub') of undefined -> ok; {OzId__, OzM__, OzMs__} -> put('__bp_mocks_stubs', case get('__bp_mocks_stubs') of undefined -> []; OzL__ -> OzL__ end ++ [{OzId__, OzM__, OzMs__, throw, OzV__}]) end, put('__bp_mocks_pending_stub', undefined), 0 end)(Message),
    true.

'__bp_get'(V, tag) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Stub", [{"tag", erlang:element(2, V)}]}.
