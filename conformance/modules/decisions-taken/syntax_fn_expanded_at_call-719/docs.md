# Decision 719 — A function whose parameter is `syntax` is expanded at its call: `syntax q: string` takes a template text `` @`…` `` (578), a `syntax` parameter of any other type takes an expression written between the parentheses of an ordinary call — `snap.matches(render(page))` with `pub fn matches(syntax value: unknown) -> anyvalue` — and the body is a build body that reads the expression through `compiler.*` and returns the code that stands at the call.

[cases/syntax_fn_expanded_at_call/src/main.bp](cases/syntax_fn_expanded_at_call/src/main.bp)
[cases/syntax_fn_expression_param_given_template_text/src/main.bp](cases/syntax_fn_expression_param_given_template_text/src/main.bp)
[cases/syntax_fn_string_param_needs_template_text/src/main.bp](cases/syntax_fn_string_param_needs_template_text/src/main.bp)
[cases/syntax_fn_text_of_expression/src/main.bp](cases/syntax_fn_text_of_expression/src/main.bp)
[cases/syntax_fn_called_through_module/src/main.bp](cases/syntax_fn_called_through_module/src/main.bp)
[cases/syntax_fn_run_time_return/src/main.bp](cases/syntax_fn_run_time_return/src/main.bp)
