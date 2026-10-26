{module, bp_load_cases_template_method_call@store}.
{exports, []}.
{attributes, []}.
{labels, 2}.
%%% A template method declared in another module over a generic behavior —
%%% the shape of decision 415's `query<E>(comptime self: @Expr<QueryContext<E>>,
%%% comptime q: @Expr<string>)`: the importer calls it on a value of a type
%%% that implements the behavior.
