-module(bp_load_cases_decorator_member_reaches_decorator_imports@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0]).

%%% Decision 669 — names in code a decorator writes resolve in the module that

%%% wrote it, that module's imports included. `#[counted]`'s member calls

%%% `panic` and `print`, which `checks` imports from std; this module imports

%%% neither, and calls the member.


%% import counted

%% type Basket: size

main() ->
    bp_load_cases_decorator_member_reaches_decorator_imports@main@@Basket:report({bp_load_cases_decorator_member_reaches_decorator_imports@main@@Basket, 3}),
    bp_load_cases_decorator_member_reaches_decorator_imports@main@@Basket:report({bp_load_cases_decorator_member_reaches_decorator_imports@main@@Basket, 0}).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/decorator_member_reaches_decorator_imports|*">>.

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    main().

main(_Args) ->
    '_botopink_main'().
