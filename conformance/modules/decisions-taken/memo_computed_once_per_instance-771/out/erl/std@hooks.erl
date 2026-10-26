-module(std@hooks).
-export([memo/1, slot/0, read/2]).

%%% Hooks (decisions 755, 771, 774) — what a component's body keeps between

%%% its renders.

%%% 

%%% `use memo({ -> make })` answers the value `make` computed on the

%%% component instance's first render, kept for that instance and never

%%% recomputed — no dependency list:

%%% 

%%%     import {hooks.memo} from "std";

%%% 

%%%     component fn Page(dark: bool) -> Component<Element> {

%%%         val c = use memo({ -> createContext(Theme(dark: dark)) });

%%%         use provide(c);

%%%         …

%%%     }

%%% 

%%% A component instance is the value one `Page(…)` call makes (decision

%%% 388: the call makes the component's lambda, and runs nothing). When that

%%% value is made, the compiler allocates one slot per `use memo` position in

%%% the body; the first render fills the slot, a later render of the same

%%% value reads it (decision 771). Another `Page(…)` call is another

%%% instance, with slots of its own. The slot is a process-dictionary entry

%%% keyed by the instance's slot reference on erlang and beam, a closure cell

%%% on commonJS and a heap cell on wasm.

%%% 

%%% The work is the compiler's (`comptime/context_lower.zig`): `use memo(f)`

%%% is lowered where it is written — `val bpMemoSlot__<n> = slot();` beside

%%% the component's lambda, `read(bpMemoSlot__<n>, f)` in its body —, so

%%% `memo` itself is never called and its body panics.

% The value `make` computed on this component instance's first render, kept

% for the instance (decisions 755, 771).

memo(Make) ->
    erlang:error({panic, <<"`use memo` is lowered where it is written; this body never runs">>}).

% ── what the memo lowering calls (decision 771) ──────────────────────────────

% 

% A program never names these: the compiler imports them under names no

% source can spell. Each `use memo` position of a component's body is a slot

% made when the component's value is made (`slot`) and read on each render

% (`read`).

% A new, empty slot.

slot() ->
    erlang:make_ref().

% The slot's value, computed by `make` and kept when the slot is empty.

read(Cell, Make) ->
    case (erlang:get({bp_memo, Cell}) =/= undefined) of
        true ->
            element(1, erlang:get({bp_memo, Cell}));
        _ ->
            Value = Make(),
            (fun(__C, __V) -> erlang:put({bp_memo, __C}, {__V}), undefined end)(Cell, Value),
            Value
    end.

%% external fn cellNew -> erlang template

%% external fn cellFilled -> erlang template

%% external fn cellGet -> erlang template

%% external fn cellSet -> erlang template
