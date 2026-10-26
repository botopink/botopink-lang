-module(bp_load_cases_template_answer_component@shown).
-export([mk/0]).

%% import bpScopePush__, bpScopeFind__, bpScopeRendered__, bpScopeValue__, bpScopeRoot__

%% type Styled: text

mk() ->
    fun(BpScope__) ->
        std@context:rendered({bp_load_cases_template_answer_component@shown@@Styled, <<"styled">>}, BpScope__)
    end.
