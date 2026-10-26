{module, std@io@http}.
{exports, [{fetch, 1}, {fetchStatus, 1}, {'__bp_priv__hostFailure', 1}]}.
{attributes, []}.
{labels, 94}.
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
% The request method; `.Get` is the short GET.
% What `fetch` sends (decision 623). A `body` rides `Post`, `Put` and `Patch`.
% Every way a `fetch` fails (decision 623).
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
% A host text that names a timeout is `Timeout`, any other `Network`.

{function, hostFailure, 1, 3}.
  {label, 2}.
    {line, [{location, "std@io@http.erl", 2}]}.
    {func_info, {atom, std@io@http}, {atom, hostFailure}, 1}.
  {label, 3}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 8}, [{x, 0}, 5, {atom, std@failure@@HostError}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 8}.
    {call_ext, 1, {extfunc, string, lowercase, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"timeout">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {test, is_eq, {f, 10}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 11}}.
  {label, 10}.
    {move, {atom, true}, {x, 0}}.
  {label, 11}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 12}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"timed out">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {test, is_eq, {f, 14}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 15}}.
  {label, 14}.
    {move, {atom, true}, {x, 0}}.
  {label, 15}.
    {jump, {f, 13}}.
  {label, 12}.
    {move, {atom, true}, {x, 0}}.
  {label, 13}.
    {test, is_eq, {f, 9}, [{x, 0}, {atom, true}]}.
    {move, {atom, std@io@http@@HttpError__v__timeout}, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 9}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 16}, [{x, 0}, 5, {atom, std@failure@@HostError}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 16}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@http@@HttpError__v__network}, {x, 0}]}}.
    {deallocate, 4}.
    return.
% Issue the request and resolve with the response, or fail with the
% `HttpError` (`await` answers `Error(httpError)`, decision 432):
% `fetchHost`'s `HostError` mapped to a variant (decision 486).

%% @Async — eager lowering
{function, fetch, 1, 5}.
  {label, 4}.
    {line, [{location, "std@io@http.erl", 3}]}.
    {func_info, {atom, std@io@http}, {atom, fetch}, 1}.
  {label, 5}.
    {allocate, 13, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 17}, [{x, 0}, 5, {atom, std@io@http@@Request}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 17}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 19}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 21}, [{x, 0}, 5, {atom, std@io@http@@Request}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 21}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 23}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 76}, [{x, 0}, 5, {atom, std@io@http@@Request}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 76}.
    {call_ext, 1, {extfunc, std@io@http@@Method, verb, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 77}, [{x, 0}, 5, {atom, std@io@http@@Request}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 77}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 78}, [{x, 0}, 5, {atom, std@io@http@@Request}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 78}.
    {test, is_ne_exact, {f, 79}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 80}}.
  {label, 79}.
    {move, {atom, false}, {x, 0}}.
  {label, 80}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 82}, [{x, 0}, 5, {atom, std@io@http@@Request}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 82}.
    {test, is_ne_exact, {f, 81}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {jump, {f, 83}}.
  {label, 81}.
    {move, {literal, <<"">>}, {x, 0}}.
    {call, 1, {f, 85}}.
  {label, 83}.
    {move, {y, 4}, {x, 1}}.
    {move, {x, 0}, {x, 5}}.
    {move, {y, 5}, {x, 4}}.
    {move, {y, 2}, {x, 3}}.
    {move, {y, 1}, {x, 2}}.
    {move, {y, 3}, {x, 0}}.
    {call, 6, {f, 26}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 87}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {jump, {f, 86}}.
  {label, 87}.
    {test, is_tagged_tuple, {f, 88}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call, 1, {f, 3}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 13}.
    return.
    {jump, {f, 86}}.
  {label, 88}.
    {case_end, {x, 0}}.
  {label, 86}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 13}.
    return.
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
{function, fetchStatus, 1, 7}.
  {label, 6}.
    {line, [{location, "std@io@http.erl", 4}]}.
    {func_info, {atom, std@io@http}, {atom, fetchStatus}, 1}.
  {label, 7}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {atom, std@io@http@@Method__v__get}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {test_heap, 6, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@http@@Request}, {x, 1}, {y, 0}, {x, 0}, {atom, undefined}]}}.
    {call, 1, {f, 5}}.
    {test, is_tagged_tuple, {f, 89}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 90}}.
  {label, 89}.
    {deallocate, 2}.
    return.
  {label, 90}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 91}, [{x, 0}, 3, {atom, std@io@http@@Response}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 91}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 2}.
    return.

{function, '__bp_priv__hostFailure', 1, 93}.
  {label, 92}.
    {line, [{location, "std@io@http.erl", 5}]}.
    {func_info, {atom, std@io@http}, {atom, '__bp_priv__hostFailure'}, 1}.
  {label, 93}.
    {call_only, 1, {f, 3}}.

{function, '-fetch/1-fun-0-', 1, 19}.
  {label, 18}.
    {line, [{location, "std@io@http.erl", 4}]}.
    {func_info, {atom, std@io@http}, {atom, '-fetch/1-fun-0-'}, 1}.
  {label, 19}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 20}, [{x, 0}, 3, {atom, std@io@http@@Header}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 20}.
    {deallocate, 1}.
    return.

{function, '-fetch/1-fun-1-', 1, 23}.
  {label, 22}.
    {line, [{location, "std@io@http.erl", 4}]}.
    {func_info, {atom, std@io@http}, {atom, '-fetch/1-fun-1-'}, 1}.
  {label, 23}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 24}, [{x, 0}, 3, {atom, std@io@http@@Header}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 24}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_0--t/6-fun-0--fun-1-', 2, 36}.
  {label, 35}.
    {func_info, {atom, std@io@http}, {atom, '__bp_tpl_0--t/6-fun-0--fun-1-'}, 2}.
  {label, 36}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_list, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_list, 1}}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_0-t/6-fun-0-', 6, 32}.
  {label, 31}.
    {func_info, {atom, std@io@http}, {atom, '__bp_tpl_0-t/6-fun-0-'}, 6}.
  {label, 32}.
    {allocate, 18, 6}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {x, 1}, {y, 5}}.
    {move, {x, 2}, {y, 6}}.
    {move, {x, 3}, {y, 7}}.
    {move, {x, 4}, {y, 8}}.
    {move, {x, 5}, {y, 9}}.
    {move, {atom, inets}, {x, 0}}.
    {call_ext, 1, {extfunc, application, ensure_all_started, 1}}.
    {move, {x, 0}, {y, 10}}.
    {move, {atom, ssl}, {x, 0}}.
    {call_ext, 1, {extfunc, application, ensure_all_started, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 36}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {y, 7}, {x, 2}}.
    {call_ext, 3, {extfunc, lists, zipwith, 3}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 0}}.
    {jump, {f, 40}}.
  {label, 40}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_list, 1}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, string, lowercase, 1}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 1}}.
    {jump, {f, 42}}.
  {label, 42}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 43}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {literal, [post, put, patch]}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, member, 2}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {y, 10}}.
    {jump, {f, 45}}.
  {label, 43}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 44}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 10}}.
    {jump, {f, 45}}.
  {label, 44}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 8}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 45}.
    {move, {y, 10}, {x, 0}}.
    {test, is_eq_exact, {f, 47}, [{x, 0}, {atom, true}]}.
    {move, nil, {y, 12}}.
    {move, {y, 0}, {y, 13}}.
  {label, 49}.
    {move, {y, 13}, {x, 0}}.
    {test, is_nonempty_list, {f, 50}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 14}, {y, 13}}.
    {move, {y, 14}, {x, 0}}.
    {test, is_tuple, {f, 49}, [{x, 0}]}.
    {test, test_arity, {f, 49}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 15}}.
    {get_tuple_element, {x, 0}, 1, {y, 16}}.
    {move, {y, 15}, {y, 2}}.
    {move, {y, 16}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, string, lowercase, 1}}.
    {move, {x, 0}, {y, 17}}.
    {move, {y, 17}, {x, 0}}.
    {move, {literal, [99, 111, 110, 116, 101, 110, 116, 45, 116, 121, 112, 101]}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 17}}.
    {move, {y, 17}, {x, 0}}.
    {test, is_eq_exact, {f, 52}, [{x, 0}, {atom, true}]}.
    {jump, {f, 54}}.
  {label, 52}.
    {move, {y, 17}, {x, 0}}.
    {test, is_eq_exact, {f, 53}, [{x, 0}, {atom, false}]}.
    {jump, {f, 49}}.
  {label, 53}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_filter}, {y, 17}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 54}.
    {test_heap, 2, 0}.
    {put_list, {y, 3}, {y, 12}, {x, 0}}.
    {move, {x, 0}, {y, 12}}.
    {jump, {f, 49}}.
  {label, 50}.
    {move, {y, 13}, {x, 0}}.
    {test, is_nil, {f, 51}, [{x, 0}]}.
    {jump, {f, 48}}.
  {label, 51}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 13}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 48}.
    {move, {y, 12}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {test, is_nonempty_list, {f, 56}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 15}, {y, 16}}.
    {move, {y, 15}, {y, 2}}.
    {move, {y, 2}, {y, 14}}.
    {jump, {f, 55}}.
  {label, 56}.
    {move, {y, 13}, {x, 0}}.
    {test, is_eq_exact, {f, 57}, [{x, 0}, nil]}.
    {move, {literal, [97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 111, 99, 116, 101, 116, 45, 115, 116, 114, 101, 97, 109]}, {y, 14}}.
    {jump, {f, 55}}.
  {label, 57}.
    {move, {y, 13}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 55}.
    {move, {y, 14}, {y, 2}}.
    {jump, {f, 59}}.
  {label, 59}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_list, 1}}.
    {move, {x, 0}, {y, 12}}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 12}, {y, 0}, {y, 2}, {y, 9}]}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {y, 11}}.
    {jump, {f, 46}}.
  {label, 47}.
    {move, {y, 10}, {x, 0}}.
    {test, is_eq_exact, {f, 60}, [{x, 0}, {atom, false}]}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_list, 1}}.
    {move, {x, 0}, {y, 12}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 12}, {y, 0}]}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {y, 11}}.
    {jump, {f, 46}}.
  {label, 60}.
    {move, {y, 10}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 46}.
    {move, {y, 11}, {y, 0}}.
    {jump, {f, 62}}.
  {label, 62}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {move, nil, {x, 2}}.
    {move, nil, {x, 3}}.
    {call_ext, 4, {extfunc, httpc, request, 4}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {test, is_tuple, {f, 64}, [{x, 0}]}.
    {test, test_arity, {f, 64}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 11}}.
    {get_tuple_element, {x, 0}, 1, {y, 12}}.
    {move, {y, 11}, {x, 0}}.
    {test, is_eq_exact, {f, 64}, [{x, 0}, {atom, ok}]}.
    {move, {y, 12}, {x, 0}}.
    {test, is_tuple, {f, 64}, [{x, 0}]}.
    {test, test_arity, {f, 64}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 13}}.
    {get_tuple_element, {x, 0}, 2, {y, 14}}.
    {move, {y, 13}, {x, 0}}.
    {test, is_tuple, {f, 64}, [{x, 0}]}.
    {test, test_arity, {f, 64}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 1, {y, 15}}.
    {move, {y, 15}, {y, 0}}.
    {move, {y, 14}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 16}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, status}, {y, 0}, {atom, body}, {y, 16}]}}.
    {move, {x, 0}, {y, 16}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 16}]}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {x, 0}}.
    {deallocate, 18}.
    return.
  {label, 64}.
    {move, {y, 10}, {x, 0}}.
    {test, is_tuple, {f, 65}, [{x, 0}]}.
    {test, test_arity, {f, 65}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 11}}.
    {get_tuple_element, {x, 0}, 1, {y, 12}}.
    {move, {y, 11}, {x, 0}}.
    {test, is_eq_exact, {f, 65}, [{x, 0}, {atom, error}]}.
    {move, {y, 12}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {deallocate, 18}.
    return.
  {label, 65}.
    {move, {y, 10}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_0', 6, 26}.
  {label, 25}.
    {func_info, {atom, std@io@http}, {atom, '__bp_tpl_0'}, 6}.
  {label, 26}.
    {allocate, 17, 6}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {x, 2}, {y, 5}}.
    {move, {x, 3}, {y, 6}}.
    {move, {x, 4}, {y, 7}}.
    {move, {x, 5}, {y, 8}}.
    {'try', {y, 16}, {f, 29}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 32}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {y, 5}, {x, 2}}.
    {move, {y, 6}, {x, 3}}.
    {move, {y, 7}, {x, 4}}.
    {move, {y, 8}, {x, 5}}.
    {move, {y, 10}, {x, 6}}.
    {call_fun, 6}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 11}}.
    {try_end, {y, 16}}.
    {move, {y, 11}, {x, 0}}.
    {test, is_tuple, {f, 67}, [{x, 0}]}.
    {test, test_arity, {f, 67}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 12}}.
    {get_tuple_element, {x, 0}, 1, {y, 13}}.
    {move, {y, 12}, {x, 0}}.
    {test, is_eq_exact, {f, 67}, [{x, 0}, {atom, ok}]}.
    {move, {y, 13}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {y, 9}}.
    {jump, {f, 66}}.
  {label, 67}.
    {move, {y, 11}, {x, 0}}.
    {test, is_tuple, {f, 68}, [{x, 0}]}.
    {test, test_arity, {f, 68}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 12}}.
    {get_tuple_element, {x, 0}, 1, {y, 13}}.
    {move, {y, 12}, {x, 0}}.
    {test, is_eq_exact, {f, 68}, [{x, 0}, {atom, error}]}.
    {move, {y, 13}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 14}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 14}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 14}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 14}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 14}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 14}]}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {y, 9}}.
    {jump, {f, 66}}.
  {label, 68}.
    {move, {y, 11}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {y, 9}}.
    {jump, {f, 66}}.
  {label, 66}.
    {jump, {f, 30}}.
  {label, 29}.
    {try_case, {y, 16}}.
    {move, {x, 0}, {y, 10}}.
    {move, {x, 1}, {y, 11}}.
    {move, {x, 2}, {y, 12}}.
    {move, {y, 10}, {y, 0}}.
    {move, {y, 11}, {y, 1}}.
    {move, {y, 12}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 13}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 73}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 14}}.
    {jump, {f, 72}}.
  {label, 73}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 74}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 14}}.
    {jump, {f, 72}}.
  {label, 74}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 75}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 14}}.
    {jump, {f, 72}}.
  {label, 75}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 72}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 15}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 15}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 15}}.
    {move, {y, 15}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 15}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 13}, {literal, <<"host">>}, {y, 14}, {y, 15}]}}.
    {move, {x, 0}, {y, 13}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 13}]}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {y, 9}}.
    {jump, {f, 70}}.
  {label, 70}.
  {label, 30}.
    {move, {y, 9}, {x, 0}}.
    {deallocate, 17}.
    return.

{function, '__bp_tpl_1', 1, 85}.
  {label, 84}.
    {func_info, {atom, std@io@http}, {atom, '__bp_tpl_1'}, 1}.
  {label, 85}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
