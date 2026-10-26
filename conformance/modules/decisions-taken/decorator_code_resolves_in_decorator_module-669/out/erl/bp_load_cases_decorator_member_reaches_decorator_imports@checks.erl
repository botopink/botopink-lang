-module(bp_load_cases_decorator_member_reaches_decorator_imports@checks).

%%% The decorator lives in a module of its own and imports `panic` and

%%% `print`. The member it writes as text names both; each resolves here,

%%% where the member was written (decision 669).
