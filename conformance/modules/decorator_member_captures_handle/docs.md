# decorator_member_captures_handle

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> The member is the program's code, a tree (decision 575 (4)): a member holds
> run-time code, its `syntax` parameters spliced as the annotation wrote them, its
> `comptime` parameters and the body's locals spliced as literals (a string, a
> number, a `bool`, `null` or an array of those). The type receives `pub fn
> validate(self: Self) -> Violation[] { … }` with each `syntax` argument spliced
> where the member uses it — evaluated at run time, each time that use is
> reached, so an argument not known at build (`t("…")`) is accepted. The
> decorator's type parameters take what the annotation bound them to (`T` is
> `Signup`, written `Self`). The handle `decl` is the annotated type as code in
> the member, as in an executor (decision 716 (3)): `decl.title()` in a member of
> `#[named]` over `syntax decl: Titled` is `Signup.title()`. A body local whose value
> is no literal, read in a member or an executor, is refused at the read, naming
> the local (`decorator-member-local-not-literal`, decision 759), while a
> `compiler.*` call inside a member
> is evaluated at build and spliced as its answer (decision 642; cell
> `member_reads_compiler_name`), `compiler.name(x)` over the member's own parameter
> `x` answering `"x"` (`member_names_its_parameter`), `compiler.text(x + 1)` its source as written
> (`member_texts_its_expression`).
