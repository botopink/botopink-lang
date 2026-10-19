----- SOURCE CODE -- std/compiler.bp
```botopink
//// The compiler a body that runs at build talks to (decisions 575 (3), 576,
//// 579).
////
//// `compiler`, this module's default, is a value, not a keyword: importing
//// the module binds it — `import {compiler} from "std";` outside std,
//// `import {compiler};` in a std module, an alias (`import {compiler as c}
//// from "std";`) included. In a body that runs at build — a decorator, a
//// template, a function called at build, a `comptime { … }` block — it is the
//// `Compiler` of that point: the annotated declaration in a decorator, the
//// call site elsewhere. It is a `Build` resource (decision 376 (1)); a body
//// that runs only when the program runs is refused there
//// (`compiler-at-run-time`), and it is read only through its members — never
//// passed nor stored (`compiler-escapes`). A file that does not import it
//// has no `compiler`: the name is an ordinary one there.
////
//// `Compiler` has one implementor, the compiler itself: a unit test holds the
//// compiler's table of members (`parser/compiler_surface.zig` `members`) to
//// the behavior below, member for member, each parameter's arrival included
//// (decision 616): `syntax` receives the code as written — a declaration, an
//// argument, a lambda —, `comptime` a value known at build, the rest a plain
//// value.
////
//// - The point: `src()`, `module`, `package`, `isStd`.
//// - The outputs, a decorator's only (`compiler-output-outside-decorator`):
////   `setMeta`, `addMeta`, `addMember`, `addType`, `wrapWith`, `init`,
////   `implement`.
//// - The reads of a `syntax` (decision 576 (2)): `text`, `name`, `source`,
////   `context`, `lookup`, `bindings`, `fail`.
//// - A template's call site: `build`, `ast`, `buildType`, `note`, `tagDecl`,
////   `annotate`, `custom` (decisions 578 (3), 625 (2)).
//// - The typed AST `ast` builds code from (decision 625 (2)): `Node` and its
////   kinds `Name`, `Lit`, `Member`, `Call`, `Arg`, `List`, `Tuple`,
////   `Binary`, `Unary`, `If`, `Lambda` and `Syntax` (decision 638).
//// - A declaration handle's reads (decision 576 (3)): `name`, `kind`,
////   `moduleOf`, `meta`, `metaAll`, `attr`, `component`, `hooks`, `fields`,
////   `methods`, `params`, `returnType`, `owner`, `annotations`, `variants`.
//// - The program: `find`, `typeInfo`.
////
//// `setBuiltin`, `embed`, `fields` over a type,
//// `optional` and `required` join it with the steps that build them.

pub behavior Compiler {
    // ── The point ─────────────────────────────────────────────────────────
    // The module and the package the point is written in; whether it is std.
    val module: string;
    val package: string;
    val isStd: bool;

    // Where the point is: the annotated declaration in a decorator, the call
    // site elsewhere — always called, `comptime compiler.src()`; a run-time
    // function that needs its caller's place takes it as an argument the
    // caller writes (decision 718).
    fn src(self: Self) -> SourceLocation;

    // ── Reporting ─────────────────────────────────────────────────────────
    // An error at the argument or the declaration `at` holds (at `span`
    // inside it when given), else at `src`; the body goes on.
    fn fail(self: Self, message: string, syntax at: ?unknown = null, span: ?Span = null);
    // A note at the template's call site (decision 426 (4)).
    fn note(self: Self, message: string);

    // ── The outputs (a decorator's only) ──────────────────────────────────
    // A typed meta value, one per type per declaration (decision 298).
    fn setMeta<M>(self: Self, syntax value: M);
    // A typed meta value that repeats (decision 298).
    fn addMeta<M>(self: Self, syntax value: M);
    // A member of the annotated type, a function written at the call
    // (decision 370 (2)).
    fn addMember<F>(self: Self, name: string, syntax member: F);
    // An associated type of the annotated type (decision 216 (3)).
    fn addType(self: Self, name: string, comptime source: string);
    // A wrapper of the annotated function, a lambda written at the call
    // (decision 316).
    fn wrapWith<F>(self: Self, syntax wrapper: F);
    // Run-time code compiled beside the annotated declaration, run once
    // before `main` in the program's init list: modules in dependency order,
    // declarations in source order, calls in order (decisions 575 (3), 615).
    fn init(self: Self, syntax executor: fn());
    // A host source of the annotated `declare fn` (decision 575 (6)): one per
    // target (`implementation-twice`), never on a declaration with a body
    // (`implement-with-body`).
    fn implement(self: Self, comptime source: Implementation);

    // ── The reads of a `syntax` (decision 576 (2)) ─────────────────────────
    // The expression as written.
    fn text(self: Self, syntax e: unknown) -> string;
    // The name the expression is written as, or the declaration's name; an
    // expression that has none — a lambda, a literal, a call, `a + b` — is
    // `syntax-has-no-name` at it (decision 612).
    fn name(self: Self, syntax e: unknown) -> string;
    // A template text's source and the context it stands in.
    fn source(self: Self, syntax e: unknown) -> Source;
    fn context(self: Self, syntax e: unknown) -> ExprContext;
    // A name resolved where the call stands, and every name in scope there.
    fn lookup(self: Self, syntax e: unknown, name: string) -> unknown;
    fn bindings(self: Self, syntax e: unknown) -> unknown[];

    // ── A template's call site ────────────────────────────────────────────
    // Code built from source text, typed at the call (decisions 426 (1),
    // 578 (3)).
    fn build(self: Self, comptime source: string) -> anyvalue;
    // Code built from a tree of `Node`s, typed at the call (decision 625
    // (2)); a tree that is no code — an `Arg` outside a `Call`, a `Name`
    // nothing binds — is refused here, naming the node.
    fn ast(self: Self, comptime node: Node) -> anyvalue;
    // A type built from source text — the one way a type is built
    // (decision 578 (3)).
    fn buildType(self: Self, comptime source: string) -> anytype;
    // A tag's declaration handle (decision 302), and a handle's annotation.
    fn tagDecl(self: Self, kind: DeclKind, name: string, syntax attrs: unknown) -> unknown;
    fn annotate(self: Self, syntax d: unknown, at: Span) -> unknown;
    // The reference tree the language server reads, by call location.
    fn custom(self: Self, ast: CustomNode);

    // ── A declaration handle's reads (decision 576 (3)) ───────────────────
    fn kind(self: Self, syntax d: unknown) -> DeclKind;
    fn moduleOf(self: Self, syntax d: unknown) -> string;
    fn meta<M>(self: Self, syntax d: unknown) -> ?M;
    fn metaAll<M>(self: Self, syntax d: unknown) -> M[];
    fn attr(self: Self, syntax d: unknown, name: string) -> ?string;
    fn component(self: Self, syntax d: unknown) -> unknown;
    fn hooks(self: Self, syntax d: unknown) -> HookNode[];
    fn fields(self: Self, syntax d: unknown) -> Field[];
    fn methods(self: Self, syntax d: unknown) -> Method[];
    fn params(self: Self, syntax d: unknown) -> Param[];
    fn returnType(self: Self, syntax d: unknown) -> string;
    fn owner(self: Self, syntax d: unknown) -> unknown;
    fn annotations(self: Self, syntax d: unknown) -> DeclAnnotation[];
    fn variants(self: Self, syntax d: unknown) -> string[];

    // ── The program ───────────────────────────────────────────────────────
    // The declarations marked with a decorator (decisions 253, 581 (3)),
    // read at build.
    fn find(self: Self, with: unknown, member: ?string = null) -> unknown[];
    // A type's reflection (decision 253).
    fn typeInfo<T>(self: Self, comptime t: type<T>) -> TypeInfo<T>;
}

// The value the module's import binds (decision 579): its value is given by
// the compiler at each point, so it has no body.
#[builtin]
pub default declare val compiler: Compiler;

// ── The typed AST `compiler.ast` builds code from (decision 625 (2)) ──────
// One record per kind of expression a template answers, each with a field
// set of its own: a body that runs at build reads a record by its fields.
pub type Node = Name | Lit | Member | Call | Arg | List | Tuple | Binary | Unary | If | Lambda | Syntax;

// A name, resolved in the module that wrote the tree: `Name("double")`.
pub type Name(name: string)

// A value known at build, spliced as its literal: `Lit(3)`, `Lit("a")`,
// `Lit([1, 2])`.
pub type Lit(value: unknown)

// `target.member`.
pub type Member(target: Node, member: string)

// A call: `callee` a `Name`, a `Member` (a method call) or any node; each
// argument a node (positional) or an `Arg` (labelled).
pub type Call(callee: Node, args: Node[])

// A labelled argument, `name: value` — only an argument of a `Call`.
pub type Arg(name: string, value: Node)

// `[a, b]`.
pub type List(items: Node[])

// `#(a, b)`.
pub type Tuple(elems: Node[])

// `lhs op rhs`, `op` one of `+ - * / % == != < > <= >= && ||`.
pub type Binary(op: string, lhs: Node, rhs: Node)

// `op operand`, `op` one of `-` and `!`.
pub type Unary(op: string, operand: Node)

// `if (cond) then else otherwise`.
pub type If(cond: Node, then: Node, otherwise: Node)

// `{ a, b -> body }`.
pub type Lambda(params: string[], body: Node)

// The code a `syntax` value holds, spliced as it was written and typed where
// the splice stands (decision 638).
pub type Syntax(e: unknown)

// ── The types `compiler` answers (decision 576 (13)) ──────────────────────
// No prelude name: a file naming one imports it, `import {compiler.Span} from
// "std";`. Each is the compiler's own type, written here under its name.
pub type Span = __Span;

pub type Source = __Source;

pub type ExprContext = __ExprContext;

pub type CustomNode = __CustomNode;

pub type DeclKind = __DeclKind;

pub type DeclAnnotation = __Decl__Annotation;

pub type Param = __Decl__Param;

pub type Field = __Decl__Field;

pub type Method = __Decl__Method;

pub type HookNode = __HookNode;

```

----- TYPED AST JSON -- std/compiler.json
```json
{
  "declarations": [
    {
      "ast": "interface_def",
      "name": "Compiler",
      "fields": {
        "module": "string",
        "package": "string",
        "isStd": "bool"
      },
      "methods": [
        {
          "name": "src",
          "params": [
            {
              "name": "self",
              "type": "Self"
            }
          ],
          "return_type": "SourceLocation"
        },
        {
          "name": "fail",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "message",
              "type": "string"
            },
            {
              "name": "at",
              "type": "?unknown",
              "is_comptime": true
            },
            {
              "name": "span",
              "type": "?__Span"
            }
          ],
          "return_type": "void"
        },
        {
          "name": "note",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "message",
              "type": "string"
            }
          ],
          "return_type": "void"
        },
        {
          "name": "setMeta",
          "generic_params": [
            "M"
          ],
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "value",
              "type": "M",
              "is_comptime": true
            }
          ],
          "return_type": "void"
        },
        {
          "name": "addMeta",
          "generic_params": [
            "M"
          ],
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "value",
              "type": "M",
              "is_comptime": true
            }
          ],
          "return_type": "void"
        },
        {
          "name": "addMember",
          "generic_params": [
            "F"
          ],
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "name",
              "type": "string"
            },
            {
              "name": "member",
              "type": "F",
              "is_comptime": true
            }
          ],
          "return_type": "void"
        },
        {
          "name": "addType",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "name",
              "type": "string"
            },
            {
              "name": "source",
              "type": "string",
              "is_comptime": true
            }
          ],
          "return_type": "void"
        },
        {
          "name": "wrapWith",
          "generic_params": [
            "F"
          ],
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "wrapper",
              "type": "F",
              "is_comptime": true
            }
          ],
          "return_type": "void"
        },
        {
          "name": "init",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "executor",
              "type": "fn() -> void",
              "is_comptime": true
            }
          ],
          "return_type": "void"
        },
        {
          "name": "implement",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "source",
              "type": "Implementation",
              "is_comptime": true
            }
          ],
          "return_type": "void"
        },
        {
          "name": "text",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "e",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "string"
        },
        {
          "name": "name",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "e",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "string"
        },
        {
          "name": "source",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "e",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "__Source"
        },
        {
          "name": "context",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "e",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "__ExprContext"
        },
        {
          "name": "lookup",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "e",
              "type": "unknown",
              "is_comptime": true
            },
            {
              "name": "name",
              "type": "string"
            }
          ],
          "return_type": "unknown"
        },
        {
          "name": "bindings",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "e",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "unknown[]"
        },
        {
          "name": "build",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "source",
              "type": "string",
              "is_comptime": true
            }
          ],
          "return_type": "anyvalue"
        },
        {
          "name": "ast",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "node",
              "type": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax>",
              "is_comptime": true
            }
          ],
          "return_type": "anyvalue"
        },
        {
          "name": "buildType",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "source",
              "type": "string",
              "is_comptime": true
            }
          ],
          "return_type": "typeparam"
        },
        {
          "name": "tagDecl",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "kind",
              "type": "__DeclKind"
            },
            {
              "name": "name",
              "type": "string"
            },
            {
              "name": "attrs",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "unknown"
        },
        {
          "name": "annotate",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "d",
              "type": "unknown",
              "is_comptime": true
            },
            {
              "name": "at",
              "type": "__Span"
            }
          ],
          "return_type": "unknown"
        },
        {
          "name": "custom",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "ast",
              "type": "__CustomNode"
            }
          ],
          "return_type": "void"
        },
        {
          "name": "kind",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "d",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "__DeclKind"
        },
        {
          "name": "moduleOf",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "d",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "string"
        },
        {
          "name": "meta",
          "generic_params": [
            "M"
          ],
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "d",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "?M"
        },
        {
          "name": "metaAll",
          "generic_params": [
            "M"
          ],
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "d",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "M[]"
        },
        {
          "name": "attr",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "d",
              "type": "unknown",
              "is_comptime": true
            },
            {
              "name": "name",
              "type": "string"
            }
          ],
          "return_type": "?string"
        },
        {
          "name": "component",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "d",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "unknown"
        },
        {
          "name": "hooks",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "d",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "__HookNode[]"
        },
        {
          "name": "fields",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "d",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "__Decl__Field[]"
        },
        {
          "name": "methods",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "d",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "__Decl__Method[]"
        },
        {
          "name": "params",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "d",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "__Decl__Param[]"
        },
        {
          "name": "returnType",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "d",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "string"
        },
        {
          "name": "owner",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "d",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "unknown"
        },
        {
          "name": "annotations",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "d",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "__Decl__Annotation[]"
        },
        {
          "name": "variants",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "d",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "string[]"
        },
        {
          "name": "find",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "with",
              "type": "unknown"
            },
            {
              "name": "member",
              "type": "?string"
            }
          ],
          "return_type": "unknown[]"
        },
        {
          "name": "typeInfo",
          "generic_params": [
            "T"
          ],
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "t",
              "type": "typeparam T",
              "is_comptime": true
            }
          ],
          "return_type": "TypeInfo<T>"
        }
      ]
    },
    {
      "ast": "typeAlias"
    },
    {
      "ast": "record_def",
      "name": "Name",
      "fields": {
        "name": "string"
      }
    },
    {
      "ast": "record_def",
      "name": "Lit",
      "fields": {
        "value": "unknown"
      }
    },
    {
      "ast": "record_def",
      "name": "Member",
      "fields": {
        "target": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax>",
        "member": "string"
      }
    },
    {
      "ast": "record_def",
      "name": "Call",
      "fields": {
        "callee": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax>",
        "args": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax>[]"
      }
    },
    {
      "ast": "record_def",
      "name": "Arg",
      "fields": {
        "name": "string",
        "value": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax>"
      }
    },
    {
      "ast": "record_def",
      "name": "List",
      "fields": {
        "items": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax>[]"
      }
    },
    {
      "ast": "record_def",
      "name": "Tuple",
      "fields": {
        "elems": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax>[]"
      }
    },
    {
      "ast": "record_def",
      "name": "Binary",
      "fields": {
        "op": "string",
        "lhs": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax>",
        "rhs": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax>"
      }
    },
    {
      "ast": "record_def",
      "name": "Unary",
      "fields": {
        "op": "string",
        "operand": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax>"
      }
    },
    {
      "ast": "record_def",
      "name": "If",
      "fields": {
        "cond": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax>",
        "then": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax>",
        "otherwise": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax>"
      }
    },
    {
      "ast": "record_def",
      "name": "Lambda",
      "fields": {
        "params": "string[]",
        "body": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax>"
      }
    },
    {
      "ast": "record_def",
      "name": "Syntax",
      "fields": {
        "e": "unknown"
      }
    },
    {
      "ast": "typeAlias"
    },
    {
      "ast": "typeAlias"
    },
    {
      "ast": "typeAlias"
    },
    {
      "ast": "typeAlias"
    },
    {
      "ast": "typeAlias"
    },
    {
      "ast": "typeAlias"
    },
    {
      "ast": "typeAlias"
    },
    {
      "ast": "typeAlias"
    },
    {
      "ast": "typeAlias"
    },
    {
      "ast": "typeAlias"
    }
  ]
}
```


----- SOURCE CODE -- shapes.bp
```botopink
pub type Item(id: i32)
```

----- TYPED AST JSON -- shapes.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "Item",
      "fields": {
        "id": "i32"
      }
    }
  ]
}
```


----- SOURCE CODE -- main.bp
```botopink
import {Item} from "shapes";
pub fn dsl(syntax e: string) -> anyvalue {
    val code = compiler.build("41");
    val leaf = CustomNode(kind: "field", span: Span(7, 9, 1), label: "property", ref: compiler.lookup(e, "Item"), children: []);
    val root = CustomNode(kind: "select", span: Span(0, 6, 1), label: "keyword", ref: null, children: [leaf]);
    compiler.custom(root);
    return code;
}
val rows = dsl @`select id from Item`;

import {compiler, compiler.Span, compiler.CustomNode} from "std";
```

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
import {Item} from "shapes";

pub val rows = 41;

import {compiler.Span, compiler.CustomNode} from "std";
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "dsl",
      "is_pub": true,
      "generic_params": [
        "__anyvalue"
      ],
      "params": [
        {
          "name": "e",
          "type": "__Expr<string>",
          "is_comptime": true
        }
      ],
      "return_type": "CustomExpr<'a>",
      "body": [
        {
          "source": "val code = compiler.build(\"41\");"
        },
        {
          "source": "val leaf = CustomNode(kind: \"field\", span: Span(7, 9, 1), label: \"property\", ref: compiler.lookup(e, \"Item\"), children: []);"
        },
        {
          "source": "val root = CustomNode(kind: \"select\", span: Span(0, 6, 1), label: \"keyword\", ref: null, children: [leaf]);"
        },
        {
          "source": "compiler.custom(root);"
        },
        {
          "source": "return code;"
        }
      ]
    },
    {
      "ast": "val",
      "ident": "rows",
      "return_type": "i32"
    },
    {
      "ast": "use",
      "declarations": [
        {
          "ast": "use-declaration",
          "ident": "Item",
          "return_type": "fn(i32) -> Item"
        },
        {
          "ast": "use-declaration",
          "ident": "Span",
          "return_type": "fn(i32, i32, i32) -> __Span"
        },
        {
          "ast": "use-declaration",
          "ident": "CustomNode",
          "return_type": "fn(string, __Span, string, ?__Decl, __CustomNode[]) -> __CustomNode"
        }
      ]
    }
  ]
}
```

