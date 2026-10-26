-module(std@io@http).
-export([fetch/1, fetchStatus/1, '__bp_priv__hostFailure'/1]).

%% behavior bytes

%%% std/io/http — minimal HTTP client primitives (cross-backend).

%%% 

%%% Reference:

%%%   Node.js  — https://nodejs.org/api/globals.html#fetch

%%%              (the global `fetch` since Node 18; `Response.text()`

%%%               reads the body as a UTF-8 string).

%%%   Erlang   — https://www.erlang.org/doc/man/httpc.html

%%%              (`httpc:request/4`; requires `inets:start()` and,

%%%               for https URLs, `ssl:start()`).

%%% 

%%% `fetch(req: Request) -> Async<Result<Response, HttpError>>` is the one

%%% surface (decision 623; `fetch(url)` is gone): `Request(method, url,

%%% headers = [], body = null)` — a short GET is

%%% `fetch(Request(method: .Get, url: u))` — and a failure is a variant of

%%% `HttpError` (`NotAllowedOnHost`, `Network(message)`, `Timeout`), matched

%%% by variant. Decision 432: the task that fails with the error — `await`

%%% answers the `Result`, so the caller writes `try await http.fetch(req)`

%%% to propagate it. It maps the host binding `fetchHost` (`result: true`,

%%% decisions 431, 490) to the `HttpError` of its `HostError` (decision 486):

%%% the node template's rejected `fetch` is `Error(HostError(…))` and a

%%% fulfilled one `Ok({ status, body })`; the erlang template ensures

%%% `inets`/`ssl` are started (`application:ensure_all_started/1`,

%%% idempotent) and lowers to a synchronous `httpc:request/4`, whose

%%% `{error, R}` becomes `Error(HostError(<R formatted>, …))`. A host text

%%% that names a timeout is `Timeout`, any other is `Network(message)`;

%%% `NotAllowedOnHost` is what a host that does not allow the request answers

%%% (the wasm `wasi:http` adapter, decisions 334, 393). Erlang is eager:

%%% `Async<T>` is `T` there, so the caller's `await` is identity on that

%%% backend. An HTTP error status (404, 500) is a RESPONSE, not a failure: it

%%% is `Ok` with its `status`.

%%% 

%%% Out of scope: streaming responses.

%%% 

%%% BEAM and wasm targets are out of scope here: `wat3` has no host fetch

%%% surface; BEAM follows the erlang template once an `httpc`-equivalent

%%% shim is ported. Either backend's caller will fail with a missing-

%%% external diagnostic at codegen time, matching the spec wave's

%%% scope.

%% import HostError

%% type Response: status, body

%% type Header: name, value

% The request method; `.Get` is the short GET.

%% type Method
%%   Get
%%   Post
%%   Put
%%   Delete
%%   Patch
%%   Head
%%   Options

% What `fetch` sends (decision 623). A `body` rides `Post`, `Put` and `Patch`.

%% type Request: method, url, headers, body

% Every way a `fetch` fails (decision 623).

%% type HttpError
%%   NotAllowedOnHost
%%   Network(message)
%%   Timeout

% The request as the host takes it, under `result: true` (decisions 431, 490):

% the response, or every way the host fails as `Error(HostError(…))`. The

% headers cross as two lists, names and values in the same order; `hasBody`

% says whether `body` is sent.

% 

% Node: `globalThis.fetch(url, { method, headers, body })` chained with

% `.text()` flattens the `Response → Promise<text>` shape into one

% `{ status, body }`; a rejection anywhere in the chain is

% `Error(HostError(<message>, …))` (`codegen/commonJS.zig` `wrapResult`).

% `fetch` takes no body on `GET` / `HEAD`.

% 

% Erlang: idempotently start `inets` + `ssl` (`application:ensure_all_started/1`,

% so a second `fetch` call doesn't bomb on `{already_started, _}`), then call

% `httpc:request/4`; a body rides `post` / `put` / `patch` with the request's

% `content-type` header (else `application/octet-stream`).

% The OK arm answers `{ok, #{status => Code, body => Body}}`; the error arm

% `{error, Reason}`, whose message is the reason formatted (decision 490).

%% external fn fetchHost -> erlang template

% A host text that names a timeout is `Timeout`, any other `Network`.

hostFailure(E) ->
    Text = string:lowercase(erlang:element(2, E)),
    case ((string:find(Text, <<"timeout">>) =/= nomatch) orelse (string:find(Text, <<"timed out">>) =/= nomatch)) of
        true ->
            std@io@http@@HttpError__v__timeout;
        false ->
            {std@io@http@@HttpError__v__network, erlang:element(2, E)}
    end.

% Issue the request and resolve with the response, or fail with the

% `HttpError` (`await` answers `Error(httpError)`, decision 432):

% `fetchHost`'s `HostError` mapped to a variant (decision 486).

%% @Async — eager lowering
fetch(Req) ->
    Names = lists:map(fun(H) ->
        erlang:element(2, H)
    end, erlang:element(4, Req)),
    Values = lists:map(fun(H) ->
        erlang:element(3, H)
    end, erlang:element(4, Req)),
    R = (fun(__BpA0, __BpA1, __BpA2, __BpA3, __BpA4, __BpA5) -> try ((fun(__M, __U, __Ns, __Vs, __Hb, __B) -> application:ensure_all_started(inets), application:ensure_all_started(ssl), __Hs = lists:zipwith(fun(__N, __V) -> {binary_to_list(__N), binary_to_list(__V)} end, __Ns, __Vs), __A = list_to_atom(string:lowercase(binary_to_list(__M))), __Rq = case __Hb andalso lists:member(__A, [post, put, patch]) of true -> __Ct = case [__C || {__K, __C} <- __Hs, string:lowercase(__K) =:= "content-type"] of [__C1 | _] -> __C1; [] -> "application/octet-stream" end, {binary_to_list(__U), __Hs, __Ct, __B}; false -> {binary_to_list(__U), __Hs} end, case httpc:request(__A, __Rq, [], []) of {ok, {{_, __Code, _}, _, __Rb}} -> {ok, #{status => __Code, body => iolist_to_binary(__Rb)}}; {error, __R} -> {error, __R} end end)(__BpA0, __BpA1, __BpA2, __BpA3, __BpA4, __BpA5)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(std@io@http@@Method:verb(erlang:element(2, Req)), erlang:element(3, Req), Names, Values, (erlang:element(5, Req) =/= undefined), case erlang:element(5, Req) of
        undefined ->
            <<"">>;
        __bp_nullish ->
            __bp_nullish
    end),
    case R of
        {ok, Resp} ->
            {ok, Resp};
        {error, E} ->
            {error, hostFailure(E)}
    end.

% ── tests ────────────────────────────────────────────────────────────────────

% No inline runtime tests: `fetch` needs network access, which the

% per-backend lib-test runners do not provide. The surface is exercised

% indirectly through the parser §A3 + infer §A3 acceptance gates

% (`modules/compiler-core/src/parser/tests/effect_rejections.zig`)

% which pin `declare fn` with `#[external(.<Target>(…))]` as accepted.

% 

% A compile-only smoke fixture lives below to ensure callers can

% `try await fetch(req)` from a `-> Async<Result<…>>` body without the type

% checker tripping on the eager `Response` payload. The body is not executed

% at test time (its `await` would issue a network call), but the fixture

% type-checks at compile time.

%% @Async — eager lowering
fetchStatus(Url) ->
    case fetch({std@io@http@@Request, std@io@http@@Method__v__get, Url, [], undefined}) of
        {ok, Resp} ->
            {ok, erlang:element(2, Resp)};
        {error, _TryE0} -> {error, _TryE0}
    end.

'__bp_priv__hostFailure'(A0) -> hostFailure(A0).
