/// rustc-style parse error renderer.
///
/// Example output:
///
///   error: There must be a 'val' or 'var' to bind a variable to a value
///    --> <test>:1:8
///     |
///   1 | wibble = 4
///     |        ^ There must be a 'val' or 'var' to bind a variable to a value
///     |
///     = hint: Use `val <n> = <value>` for bindings.
///
const std = @import("std");

const parserMod = @import("./parser.zig");
pub const ParseErrorInfo = parserMod.ParseErrorInfo;
pub const ParseErrorType = parserMod.ParseErrorType;

// ── Canonical messages ────────────────────────────────────────────────────────

pub const ErrorMessages = struct {
    message: []const u8,
    hint: []const u8,
    /// Optional error code rendered in brackets after `error` in the header:
    /// `error[<code>]: <message>` instead of plain `error: <message>`.
    code: ?[]const u8 = null,
    /// Optional alternate caption rendered after the `^^^` carets. When null,
    /// the carets caption duplicates `message`.
    caretCaption: ?[]const u8 = null,
    /// When set, the offending token's lexeme is appended to the caret caption
    /// in backticks. For the catch-all, which has no rule to name and so has
    /// only the token itself to say something about. Skipped when the lexeme
    /// is empty (end of file).
    lexemeInCaption: bool = false,
    /// Optional `= note: ...` line emitted before `= hint: ...`.
    note: ?[]const u8 = null,
};

/// Returns the (message, hint) pair for a given parse error.
pub fn errorMessages(info: ParseErrorInfo) ErrorMessages {
    return switch (info.kind) {
        .novalBinding => .{
            .message = "There must be a 'val' or 'var' to bind a variable to a value",
            .hint = "Use `val <n> = <value>` for bindings.",
        },
        .reservedWord => .{
            .message = "This is a reserved word and cannot be used as a name",
            .hint = "Choose a different identifier.",
        },
        // The catch-all — the only one of the 48 kinds with no rule to name.
        // Every form the language does not have reaches it, so its text is
        // what a reader gets when a spelling is missing, and "Check the syntax
        // around this position." told them nothing they could not see. It now
        // names the token it stopped on, names the two things that are usually
        // wrong, and says that a DELIBERATE refusal looks different — which is
        // the distinction whose absence let seven missing forms be routed
        // around instead of filed (front 15).
        .ternaryAbsent => .{
            .code = "ternary-absent",
            .message = "there is no `c ? a : b`",
            .caretCaption = "write `if (c) { a } else { b }`",
            .hint = "`if` is an expression: `val x = if (c) { a } else { b };` — and `a ?? b` is the default of an optional.",
        },
        .bitwiseOperatorAbsent => .{
            .code = "bitwise-operator-absent",
            .message = "the language has no bitwise operators",
            .caretCaption = "not an operator",
            .lexemeInCaption = true,
            .hint = "There is no `<<`, `>>`, `&`, `^` or replacement for them; `&&` and `||` are the boolean operators. A host function behind `#[@External.<Target>(…)]` is the way to a bit operation.",
        },
        .charLiteralAbsent => .{
            .code = "char-literal-absent",
            .message = "there is no character literal",
            .caretCaption = "write a one-character string, `\"a\"`",
            .hint = "A character is a string of length one: `\"a\"`, and `s[0]` reads one from a string.",
        },
        .nestedFnDecl => .{
            .code = "nested-fn-decl",
            .message = "a `fn` is declared at module level, not inside a body",
            .caretCaption = "bind a lambda instead",
            .hint = "Inside a body a function is a value: `val inner = { x -> x + 1 };` — or move the declaration to module level.",
        },
        .listSpreadDotDotDot => .{
            .code = "list-spread-dot-dot-dot",
            .message = "`...` is a pattern's inclusive range, not a spread",
            .caretCaption = "write `..`",
            .hint = "An array literal spreads with two dots, and the spread comes last: `[1, 2, ..rest]`.",
        },
        .implementClauseFor => .{
            .code = "implement-clause-for",
            .message = "`for` in a type's `implement` clause",
            .caretCaption = "the type is the receiver already",
            .note = "the `implement` after a bodyless `type P(…)` is the TYPE's clause, `type P(…) implement A { … }`",
            .hint = "Either write the clause, `type P(x: i32) implement A { … }`, or name a standalone block: `Impl implement A for P { … }`.",
        },
        .tupleLiteralLabel => .{
            .code = "tuple-literal-label",
            .message = "a tuple literal is positional",
            .caretCaption = "no label here",
            .note = "labels belong to the tuple TYPE, `#(x: i32, y: i32)`; the labeled construction `#(x: 1, y: 2)` is not parsed",
            .hint = "Write `#(1, 2)` and read `.0` / `.1`, or read the labeled type's members by their labels.",
        },
        .unexpectedToken => .{
            .message = "this token cannot appear here",
            .caretCaption = "unexpected",
            .lexemeInCaption = true,
            .hint = "The statement before it may be missing its `;`, or an earlier `(`, `[` or `{` may not be closed. A form the language deliberately refuses reports a NAMED error instead of this one, so if you believe this spelling should work, it is a gap worth filing rather than working around.",
        },
        .opNakedRight => .{
            .message = "This operator has no value on its right-hand side",
            .hint = "Remove the operator or place a value after it.",
        },
        .listSpreadWithoutTail => .{
            .message = "A spread here requires a tail list",
            .hint = "Provide a tail, e.g. [1, 2, ..rest]",
        },
        .listSpreadNotLast => .{
            .code = "list-spread-not-last",
            .message = "the spread of an array literal comes last",
            .caretCaption = "nothing after `..rest`",
            .hint = "`[1, 2, ..rest]` — write the fixed elements first and the spread last.",
        },
        .uselessSpread => .{
            .message = "This spread does nothing",
            .hint = "Try prepending elements: [1, 2, ..list]",
        },
        .removedErrorUnion => .{
            .message = "Error union syntax `T!E` has been removed",
            .hint = "Use `@Result<D, E>` instead, e.g. `fn fetch() -> @Result<i32, MyError>`",
        },
        .removedBuiltinType => .{
            .message = "Builtin type syntax `@Result(D, E)` has been removed",
            .hint = "Use `@Result<D, E>` instead",
        },
        .useAfterBranch => .{
            .message = "`use` must be in static prefix",
            .hint = "Move all `use` statements to the top of the function body, before any `if`, `case`, `loop`, or `return`",
        },
        .metaKindRequiresComptime => .{
            .message = "A `type`/`expr` parameter must be marked `comptime`",
            .hint = "Meta-kinds only exist at compile time, e.g. `fn f(comptime T: type)` or `fn html(comptime template: expr string)`",
        },
        .badInterpolation => .{
            .message = "Malformed `${…}` interpolation in string",
            .hint = "Each `${…}` must contain one complete expression, e.g. \"hi ${name}\"; escape a literal dollar with `\\${`",
        },
        .importGroupModifier => .{
            .code = "import-group-modifier",
            .message = "`*` and `as` belong to an import leaf, not to a group",
            .caretCaption = "this node opens braces",
            .hint = "write the modifier on the leaf: `io: {fs: {readText as read}}`, `collections: {ArraySets*}`",
        },
        .anonymousImplExtend => .{
            .message = "An `implement`/`extend` block must be named",
            .hint = "Give it a name, e.g. `Name implement Trait for Type { … }` or `Name extend Type { … }`",
        },
        .deprecatedStarFn => .{
            .code = "deprecated-star-fn",
            .message = "the `*fn` prefix was removed in v0.beta.19",
            .caretCaption = "write a plain `fn` whose return type is the effect wrapper",
            .note = "the `*fn` form was deprecated in v0.beta.12; since decision 118 there is no effect marker at all — the return type is the effect",
            .hint = "rewrite as `fn <name>(...) -> @<Wrapper><...> { ... }` — `@Result`, `@Task`, `@Component`, `@Iterator` or `@Stream`",
        },
        .effectAnnotationRemoved => .{
            .code = "effect-annotation-removed",
            .message = "effect annotations were removed — the return type is the effect (decision 118)",
            .caretCaption = "remove the annotation; write the wrapper in the return",
            .note = "`#[@result]` → `-> @Result<T, E>`; `#[@future]` → `-> @Task<T>` (or `-> @Task<@Result<T, E>>` when it can fail); `#[@use]` → `-> @Component<C, T>`; `#[@generator]` → `-> @Iterator<T>`; `#[@resultGenerator]` → `-> @Iterator<@Result<T, E>>`; `#[@futureGenerator]` → `-> @Stream<@Result<T, E>>`",
            .hint = "Delete the annotation: `fn f() -> @Task<User> { … }` — writing the wrapper in the return type is what activates `await` / `use` / `yield`, and a `@Result` in some layer of it is what activates `throw` / `try`.",
        },
        .effectAnnotationRemovedLoop => .{
            .code = "effect-annotation-removed",
            .message = "effect annotations were removed — a loop takes the `iter` / `stream` prefix (decision 125)",
            .caretCaption = "remove the annotation; write `iter loop` (or `stream loop`)",
            .note = "`#[@generator] loop` and `#[@resultGenerator] loop` are `iter loop`; `#[@futureGenerator] loop` is `stream loop`; `iter` / `stream` also prefix `while` and `for`",
            .hint = "`val xs = iter loop { … yield x; … };` is worth `@Iterator<T>`; the item becomes `@Result<T, E>` on its own when the body has `throw` / `try`.",
        },
        .effectTypeRemovedFuture => .{
            .code = "effect-type-removed",
            .message = "`@Future` was removed — the wrapper is `@Task<T>`, which never fails (decision 120)",
            .caretCaption = "write `@Task<@Result<T, E>>` (or `@Task<T>` when it cannot fail)",
            .hint = "`@Future<T, E>` is `@Task<@Result<T, E>>`: `await t` then answers the `@Result`, and `try await t` propagates its error. `@Future<T>` is `@Task<T>`.",
        },
        .effectTypeRemovedGenerator => .{
            .code = "effect-type-removed",
            .message = "`@Generator` was renamed `@Iterator` (decision 122)",
            .caretCaption = "write `@Iterator<T>`",
            .hint = "`fn g() -> @Iterator<T> { yield …; }` — a body that yields is an iterator; `for (g()) { x -> … }` iterates it in any function.",
        },
        .effectTypeRemovedResultGenerator => .{
            .code = "effect-type-removed",
            .message = "`@ResultGenerator` was removed — the item carries the failure (decision 122)",
            .caretCaption = "write `@Iterator<@Result<T, E>>`",
            .hint = "`@ResultGenerator<T, E>` is `@Iterator<@Result<T, E>>`; a `for` over it hands over each `@Result` — write `try r` to propagate, or `case` to carry on.",
        },
        .effectTypeRemovedFutureGenerator => .{
            .code = "effect-type-removed",
            .message = "`@FutureGenerator` was removed — the asynchronous sequence is `@Stream` (decision 122)",
            .caretCaption = "write `@Stream<@Result<T, E>>` (or `@Stream<T>`)",
            .hint = "`@FutureGenerator<T, E>` is `@Stream<@Result<T, E>>`; iterate it with `for await` where there is an await channel.",
        },
        .effectTypeRemovedUse => .{
            .code = "effect-type-removed",
            .message = "`@Use` was removed — one context wrapper, `@Component<C, T>` (decision 128)",
            .caretCaption = "write `@Component<C, T>`",
            .hint = "`@Use<C, T>` is `@Component<C, T>`: `C` is the base the body's `use`s anchor at, `T` what the function returns — a hook returns any `T`, a component the context owner.",
        },
        .effectTypeRemovedLegacy => .{
            .code = "effect-type-removed",
            .message = "this sequence type left the language (decisions 103, 122)",
            .caretCaption = "write `@Stream<T>`, `@Iterator<T>` or `YieldStep<T>`",
            .note = "`@AsyncIterator<T>` is `@Stream<T>`; `@IteratorStep` and `@Yield<T, R>` are `YieldStep<T>`; there is no `@Iterable` — a type exposes a method answering `@Iterator<T>`",
            .hint = "`fn iter(self: Self) -> @Iterator<T>` makes a type iterable: `for (g.iter()) { x -> … }`.",
        },
        .iteratorErrorParamRemoved => .{
            .code = "iterator-error-param-removed",
            .message = "`@Iterator` has no error parameter — the item carries the failure (decision 122)",
            .caretCaption = "write `@Iterator<@Result<T, E>>`",
            .hint = "`@Iterator<T, E>` is `@Iterator<@Result<T, E>>`: `yield v` emits `Ok(v)`, and `throw e` or a failing `try` emits `Error(e)` and ends.",
        },
        .genericDefaultBeforeRequired => .{
            .message = "generic-default-before-required: default-typed generic parameters must be the trailing parameters of the list.",
            .hint = "Either give the following parameter a default too, or remove the default from the earlier one.",
        },
        .yieldBreakRemoved => .{
            .message = "yield-break-removed: use `break <C>` to end an iterator with a completion value. The `yield break` form was removed in v0.beta.19.",
            .hint = "Inside an `@Iterator` / `@Stream` body or an `iter` / `stream` loop, write `break <v>` to emit a last item and end, or bare `break` for a clean end.",
        },
        .genericArgSkipForbidden => .{
            .message = "generic-arg-skip-forbidden: cannot skip a defaulted argument while providing a later one.",
            .hint = "Either pass the middle argument explicitly, or rely on defaults for the contiguous trailing range.",
        },
        .fnParamDefaultTrailingOnly => .{
            .message = "fn-param-default-trailing-only: a defaulted parameter must be followed only by other defaulted parameters.",
            .hint = "Move the defaulted parameter to the end of the list, or give the following parameter a default too.",
        },
        .retiredAnnotationBlock => .{
            .message = "the `@[…]` annotation block was retired",
            .caretCaption = "write `#[…]` instead",
            .hint = "An annotation block opens with `#[`; the `@` marks a builtin annotation INSIDE it, e.g. `#[@External.Node(\"./m.mjs\", \"f\")]`.",
        },
        .removedKeywordRecord => .{
            .code = "removed-keyword-record",
            .message = "`record` was replaced by `type` in 1.0.3",
            .caretCaption = "write `type Name(fields) { methods }`",
            .hint = "A record is `type Point(x: i32, y: i32) { fn … }`; a record with no fields is `type Name { methods }`.",
        },
        .removedKeywordEnum => .{
            .code = "removed-keyword-enum",
            .message = "`enum` was replaced by `type` in 1.0.3",
            .caretCaption = "write `type Name { variants }`",
            .hint = "An enum is `type Color { Red, Green, Rgb(r: i32, g: i32, b: i32) }`.",
        },
        .removedKeywordInterface => .{
            .code = "removed-keyword-interface",
            .message = "`interface` was renamed to `behavior` in 1.0.3",
            .caretCaption = "write `behavior`",
            .hint = "`behavior Printable { fn print(self: Self) -> string; }`; a delegate is `declare fn`.",
        },
        .removedRecordLiteral => .{
            .code = "removed-record-literal",
            .message = "anonymous records are tuples in 1.0.3",
            .caretCaption = "write a tuple `#(…)`",
            .hint = "Build `#(x, y)` from variables (their names become the labels), or `#(1, 2)` and give the destination a labeled type `#(x: i32, y: i32)`.",
        },
        .removedLoopParenthesised => .{
            .code = "removed-loop-parenthesised",
            .message = "`loop (…)` does not exist — `for` iterates, `while` repeats",
            .caretCaption = "write `for (xs) { x -> … }` or `while (cond) { … }`",
            .hint = "Decision 105: `for (xs) { x -> … }` iterates a collection, a range or a generator; `while (cond) { … }` repeats while the condition holds; `loop { … break; }` repeats until a break. `loop await (g)` is `for await (g) { x -> … }`.",
        },
        .loopBindsNothing => .{
            .code = "loop-binds-nothing",
            .message = "`while` and `loop` bind nothing — only `for` takes `{ x -> … }`",
            .caretCaption = "remove the binder",
            .hint = "`while (cond) { … }` repeats while the condition holds and `loop { … }` until a break; to bind each item write `for (xs) { x -> … }`.",
        },
        .forWithoutBinder => .{
            .code = "for-without-binder",
            .message = "a `for` binds the item it iterates: `for (xs) { x -> … }`",
            .caretCaption = "open the body with `x ->`",
            .hint = "To repeat without a value write `while (cond) { … }` or `loop { … break; }`.",
        },
        .forBindsOneName => .{
            .code = "for-binds-one-name",
            .message = "a `for` binds one name — there is no index binder",
            .caretCaption = "one name before `->`",
            .hint = "Iterate the positions to read an index: `for (0..xs.length) { i -> val x = xs[i]; … }`.",
        },
        .loopAnnotationNotGenerator => .{
            .code = "loop-annotation-not-generator",
            .message = "a loop takes no annotation — it takes the `iter` / `stream` prefix",
            .caretCaption = "not a loop annotation",
            .hint = "`iter loop { … }` is worth `@Iterator<T>` and `stream loop { … }` `@Stream<T>` (decision 125); `iter` / `stream` also prefix `while` and `for`: `iter for (xs) { x -> yield f(x); }`.",
        },
        .removedKeywordNew => .{
            .code = "removed-keyword-new",
            .message = "`new` is not a keyword — call the constructor by name",
            .caretCaption = "remove `new`",
            .hint = "A constructor is called by name: `Person(name: \"ann\")`. There is no builtin `Error`: `throw` carries the error channel's own value, `throw \"message\"`.",
        },
        .removedRecordType => .{
            .code = "removed-record-type",
            .message = "anonymous record types are tuples in 1.0.3",
            .caretCaption = "write a tuple type `#(…)`",
            .hint = "A labeled tuple type: `#(x: i32, y: i32)`.",
        },
        .unknownTakesNoArguments => .{
            .code = "unknown-takes-no-arguments",
            .message = "`unknown` takes no type arguments",
            .caretCaption = "write `unknown` alone",
            .hint = "`unknown` is one type — anything, checked before it is used (`x is i32`). A container of it is written `unknown[]` or `Box<unknown>`.",
        },
        .unionMemberMissing => .{
            .code = "union-member-missing",
            .message = "a union type needs another type after `|`",
            .caretCaption = "add the next member here",
            .hint = "A union is written `i32 | string`, each member a complete type; `(i32 | string)[]` is an array of the union, `i32 | string[]` an `i32` or an array of `string`.",
        },
        .isMissingType => .{
            .code = "is-missing-type",
            .message = "`is` needs a type to test the value against",
            .caretCaption = "add the type here",
            .hint = "`x is i32` answers whether the value is an `i32` right now; inside the block that it guards, `x` is that type.",
        },
        .isVariantBinding => .{
            .code = "is-variant-binding",
            .message = "`is` tests a type; it does not bind a variant's payload",
            .caretCaption = "remove the payload pattern",
            .hint = "Test the variant with `x is Shape` and read the payload in a `case` arm: `case x { Shape.Circle(radius: r) { … } }`. An optional is not a variant — a `?T` is read with `case x { null { … } v { … } }` (decision 54).",
        },
        .patternRangeExclusive => .{
            .code = "pattern-range-exclusive",
            .message = "`..` is iteration, not a pattern's range",
            .caretCaption = "write `...` — an inclusive range, both ends matched",
            .hint = "`1...9` matches every value from 1 to 9; `..` belongs to `for (0..n)` and slicing. An open end is a guard: `_ when (x < 0) { … }`.",
        },
        .patternRangeMissingEnd => .{
            .code = "pattern-range-missing-end",
            .message = "a range pattern needs its upper bound",
            .caretCaption = "add the end of the range",
            .hint = "`1...9` matches 1 to 9, both included. For an open end write a guard: `_ when (x > 9) { … }`.",
        },
        .patternRestNotLast => .{
            .code = "pattern-rest-not-last",
            .message = "`..` stands for what the pattern does not name, so it comes last",
            .caretCaption = "move `..` to the end",
            .hint = "Write `.Rect(width: w, ..)`: the fields you name first, then `..` once, at the end.",
        },
        .patternTupleLabel => .{
            .code = "pattern-tuple-label",
            .message = "a tuple pattern is positional — it takes no label",
            .caretCaption = "drop the label and match by position",
            .hint = "Labels are names for the compiler; a tuple is positional at run time. Write `#(n, ..)`, whatever the labels of its type.",
        },
        .caseBareNameArm => .{
            .code = "case-bare-name-arm",
            .message = "a name alone is not a pattern",
            .caretCaption = "use _ { n -> … } to bind the matched value",
            .hint = "An arm names a type (`i32`), a variant (`.Some(v)`), a literal (`0`), a range (`1...9`) or `_`. To give the matched value a name, bind it in the body: `_ { n -> … }`.",
        },
        .caseConstantPattern => .{
            .code = "case-constant-pattern",
            .message = "a constant is not a pattern",
            .caretCaption = "use _ when (x == MAX) { … } to compare with it",
            .hint = "A pattern matches a shape; comparing with a constant is a guard. Write `_ when (x == MAX) { … }`.",
        },
        .typeRecordWithVariants => .{
            .code = "type-record-with-variants",
            .message = "a `type` with a field list cannot also declare variants",
            .hint = "A record is `type Name(fields) { methods }`; an enum is `type Name { Variant, … }`. Split the declaration in two.",
        },
        .typeEmptyFieldList => .{
            .code = "type-empty-field-list",
            .message = "an empty field list `()`",
            .hint = "A record with no fields omits the parentheses: `type Name { methods }`.",
        },
        .typeAliasAnnotated => .{
            .code = "type-alias-annotated",
            .message = "a type alias takes no annotation",
            .hint = "An alias is only a name for a type (`type Parser<T> = @Result<T, ParseError>;`); put the annotation on a declaration that carries it.",
        },
        .typeAliasGenericDefault => .{
            .code = "type-alias-generic-default",
            .message = "a type alias parameter takes no default",
            .hint = "Write the alias with every argument at each use (`Name<i32>`), or declare a second alias for the defaulted form.",
        },
        .typeVariantAfterMethod => .{
            .code = "type-variant-after-method",
            .message = "a variant after a method",
            .hint = "Declare every variant (and section) before the first method.",
        },
        .typeFieldValPrefix => .{
            .code = "type-field-val-prefix",
            .message = "a field list takes no `val` prefix",
            .caretCaption = "remove `val`",
            .hint = "Fields are immutable already: `type Point(x: i32, y: i32)`.",
        },
        .fieldNeedsName => .{
            .code = "field-needs-name",
            .message = "a field with no name",
            .caretCaption = "write `name: Type` here",
            .hint = "Every field and every variant payload is named: `type Point(x: i32, y: i32)`, `Variant(field: T)`. A payload nobody can name is a payload no `case` arm can bind.",
        },
        .memberCommaSeparator => .{
            .code = "member-comma-separator",
            .message = "members end with `;`, not `,`",
            .caretCaption = "replace `,` with `;` (or nothing after a `}`)",
            .hint = "A bodyless member (`fn f(self: Self) -> i32;`, `val x: T;`) ends with `;`; a member with a body ends with `}`.",
        },
        .memberMissingSemicolon => .{
            .code = "member-missing-semicolon",
            .message = "a bodyless member must end with `;`",
            .caretCaption = "add `;`",
            .hint = "Write `fn name(self: Self) -> T;` or `val name: T;`.",
        },
        .templateSelfMarker => .{
            .code = "template-self-marker",
            .message = "`$self` is not a template marker",
            .caretCaption = "use `$0`",
            .hint = "Markers are positional over the declared parameters: on a method `$0` is `self`, `$1` the next parameter.",
        },
        .templateMarkerOutOfRange => .{
            .code = "template-marker-out-of-range",
            .message = "a template marker names a parameter the declaration does not have",
            .caretCaption = "past the last parameter",
            .hint = "`$0` is the first declared parameter; the highest marker is one less than the parameter count.",
        },
        .bodylessFnNeedsReturnType => .{
            .code = "bodyless-fn-needs-return-type",
            .message = "a declaration with no body must say what it answers",
            .caretCaption = "add `-> void`, or give the fn a body",
            .note = "`fn f(x: string) -> void`, `fn f(x: string) void` and `declare fn f(x: string);` are all declarations; `fn f(x: string)` alone says nothing about the result",
            .hint = "Write `-> void` when the fn answers nothing, `-> T` when it answers a `T`, or add a `{ … }` body.",
        },
        .fnParamPositionalAfterNamed => .{
            .message = "fn-param-positional-after-named: positional argument supplied after a named one.",
            .hint = "Convert the trailing positional arg to a named one (`name: value`), or move the named argument to the end of the call.",
        },
    };
}

// ── Main renderer ─────────────────────────────────────────────────────────────

/// Renders a parse error to any `writer` (stderr, ArrayList(u8), etc).
///
/// `source`    ---- original source text (used to extract the context line).
/// `filePath` ---- path shown in the header (e.g. "src/main.botopink" or "<test>").
///
/// Output format (gutter = line-number width + 1 space):
///
///   error: <message>
///    --> <file>:<line>:<col>
///   <gutter> |
///   <line>   | <source line>
///   <gutter> | <spaces><carets> <detail>
///   <gutter> |
///   <gutter> = hint: <hint>
///
pub fn render(
    writer: anytype,
    info: ParseErrorInfo,
    source: []const u8,
    filePath: []const u8,
) !void {
    const msgs = errorMessages(info);
    const loc = findLocation(source, info.start);

    // width of the line number, e.g. line 1 -> 1, line 42 -> 2
    const lineW = digitWidth(loc.line);
    // gutter: spaces needed to align "|" with the line number column
    // e.g. "1 | ..." -> gutter=2, so blank gutter lines get 2 spaces before "|"
    const gutter = lineW + 1;

    // "error: <message>" or, when a code is set, "error[<code>]: <message>"
    if (msgs.code) |code| {
        try writer.print("error[{s}]: {s}\n", .{ code, msgs.message });
    } else {
        try writer.print("error: {s}\n", .{msgs.message});
    }

    // " --> <file>:<line>:<col>"  (gutter-1 spaces before "-->")
    try writePad(writer, gutter - 1);
    try writer.print("--> {s}:{d}:{d}\n", .{ filePath, loc.line, loc.col });

    // "<gutter>|"  ---- blank line above source
    try writePad(writer, gutter);
    try writer.print("|\n", .{});

    // "<line> | <text>"
    try writer.print("{d} | {s}\n", .{ loc.line, loc.lineText });

    // "<gutter>| <spaces><carets> <caption>"
    // The caret caption defaults to `message`; a kind may override it to give
    // the rejected span a tighter directive (e.g. "use a `#[@<effect>]`…").
    const caption = msgs.caretCaption orelse msgs.message;
    try writePad(writer, gutter);
    try writer.print("| ", .{});
    const spanLen = if (info.end > info.start) info.end - info.start else 1;
    try writePadN(writer, loc.col - 1, ' ');
    try writePadN(writer, spanLen, '^');
    if (msgs.lexemeInCaption and info.lexeme.len > 0) {
        try writer.print(" {s} `{s}`\n", .{ caption, info.lexeme });
    } else {
        try writer.print(" {s}\n", .{caption});
    }

    // "<gutter>|"  ---- blank line below carets
    try writePad(writer, gutter);
    try writer.print("|\n", .{});

    // Optional "<gutter>= note: <note>" line — when set, it precedes the hint.
    if (msgs.note) |note| {
        try writePad(writer, gutter);
        try writer.print("= note: {s}\n", .{note});
    }

    // "<gutter>= hint: <hint>"
    try writePad(writer, gutter);
    try writer.print("= hint: {s}\n", .{msgs.hint});

    // trailing blank line
    try writer.print("\n", .{});
}

/// Allocating version ---- renders to a new string. Convenient for snapshot tests.
pub fn renderAlloc(
    allocator: std.mem.Allocator,
    info: ParseErrorInfo,
    source: []const u8,
    filePath: []const u8,
) ![]u8 {
    var aw: std.Io.Writer.Allocating = .init(allocator);
    defer aw.deinit();
    try render(&aw.writer, info, source, filePath);
    return aw.toOwnedSlice();
}

// ── Internal types and helpers ────────────────────────────────────────────────

const Location = struct {
    lineText: []const u8,
    line: usize, // 1-based
    col: usize, // 1-based
};

fn findLocation(source: []const u8, byteOffset: usize) Location {
    var line: usize = 1;
    var lineStart: usize = 0;
    const safeOffset = @min(byteOffset, source.len);

    var i: usize = 0;
    while (i < safeOffset) : (i += 1) {
        if (source[i] == '\n') {
            line += 1;
            lineStart = i + 1;
        }
    }

    var lineEnd = lineStart;
    while (lineEnd < source.len and source[lineEnd] != '\n') : (lineEnd += 1) {}

    const col = safeOffset - lineStart + 1;
    return .{
        .lineText = source[lineStart..lineEnd],
        .line = line,
        .col = col,
    };
}

fn digitWidth(n: usize) usize {
    if (n == 0) return 1;
    var w: usize = 0;
    var v = n;
    while (v > 0) : (v /= 10) w += 1;
    return w;
}

fn writePad(writer: anytype, n: usize) !void {
    for (0..n) |_| try writer.writeByte(' ');
}

fn writePadN(writer: anytype, n: usize, ch: u8) !void {
    for (0..n) |_| try writer.writeByte(ch);
}
