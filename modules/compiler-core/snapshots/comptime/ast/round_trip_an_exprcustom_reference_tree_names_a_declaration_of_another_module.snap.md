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
//// - The point: `src`, `module`, `package`, `isStd`.
//// - The outputs, a decorator's only (`compiler-output-outside-decorator`):
////   `setMeta`, `addMeta`, `addMember`, `addType`, `wrapWith`, `init`,
////   `implement`.
//// - The reads of a `syntax` (decision 576 (2)): `text`, `name`, `source`,
////   `context`, `lookup`, `bindings`, `fail`.
//// - A template's call site: `build`, `buildType`, `note`, `tagDecl`,
////   `annotate`, `custom` (decision 578 (3)).
//// - A declaration handle's reads (decision 576 (3)): `name`, `kind`,
////   `moduleOf`, `meta`, `metaAll`, `attr`, `component`, `hooks`, `fields`,
////   `methods`, `params`, `returnType`, `owner`, `annotations`, `variants`.
//// - The program: `find`, `typeInfo`.
////
//// `setBuiltin`, `embed`, `fields` over a type,
//// `optional` and `required` join it with the steps that build them.

pub behavior Compiler {
    // ── The point ─────────────────────────────────────────────────────────
    // Where the point is: the annotated declaration in a decorator, the call
    // site elsewhere.
    val src: SourceLocation;
    // The module and the package the point is written in; whether it is std.
    val module: string;
    val package: string;
    val isStd: bool;

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

// ── `Type` (decisions 307, 308, 624) ─────────────────────────────────────
// std's `Type`, declared here beside the behavior whose members it names
// (decision 624: `compiler.bp` incorporates what `types.bp` declared) — the
// derived types: a compile-time function answers a NEW record type, bound by
// a module-level `val` and named after it (`pub val RecipePatch =
// Type.partial(Recipe);`), nominal, usable in every type position, exported
// and imported like any type, and annotatable; the source fields' markers come
// with them. A program imports it by its path, `import {compiler.Type} from
// "std";`. Every function here runs only at compile time and takes every
// parameter `comptime x: T`; the bodies are the compiler's
// (`comptime/derived_types.zig`) until B-140 writes them in botopink.

pub type Type {
    // The field of `T` (decision 308): its name, its type as the source
    // spells it and its annotations. Its values are the fields of `T`'s
    // declaration; nobody constructs one (`.title` names it where a
    // `Type.Field<T>` is expected). A key is also a run-time value: stored,
    // passed, compared, matched by `case key { .title -> … }` exhaustively
    // over `T`'s fields. The reflection record `decl.fields` hands out is
    // still `builtins.d.bp`'s `Field` until `134` step 2 makes it
    // `Type.Field<unknown>`.
    pub type Field<T>(
        name: string,
        typeName: string,
        annotations: DeclAnnotation[],
    ) {
        // The key named `text`, or `null` when `T` declares no such field.
        pub declare fn of(text: string) -> ?Type.Field<T>;

        // Every key of `T`, in declaration order.
        pub declare fn all() -> Type.Field<T>[];
    }

    // The field key of `T`: `Type.Field<T>` itself, one value per field of
    // `T`'s declaration (`.title`), never a second enum nor a copy — bound by a
    // module-level `val`, the alias `K.of(text)` and `K.all()` are called
    // through.
    pub declare fn keys<T>(comptime source: type<T>) -> anytype;

    // Every field `F` of `T` made `?F`.
    pub declare fn partial<T>(comptime source: type<T>) -> anytype;

    // Every field `?F` of `T` made `F` — every `?` goes: `required` does not
    // know what was optional before a `partial`.
    pub declare fn required<T>(comptime source: type<T>) -> anytype;

    // The fields of `first`, then those of `second`; a field on both sides is
    // an error (`omit` it first: nothing overrides silently).
    pub declare fn merge<A, B>(
        comptime first: type<A>,
        comptime second: type<B>,
    ) -> anytype;

    // The fields of `T` named in `fields`, in the order `T` declares them.
    pub declare fn pick<T>(
        comptime source: type<T>,
        comptime ..fields: Type.Field<T>[],
    ) -> anytype;

    // The fields of `T` but those named in `fields`.
    pub declare fn omit<T>(
        comptime source: type<T>,
        comptime ..fields: Type.Field<T>[],
    ) -> anytype;
}

```

----- TYPED AST JSON -- std/compiler.json
```json
{
  "declarations": [
    {
      "ast": "interface_def",
      "name": "Compiler",
      "fields": {
        "src": "SourceLocation",
        "module": "string",
        "package": "string",
        "isStd": "bool"
      },
      "methods": [
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
      "ast": "record_def",
      "name": "Type",
      "fields": {},
      "methods": [
        {
          "name": "keys",
          "is_pub": true,
          "is_declare": true,
          "generic_params": [
            "T"
          ],
          "params": [
            {
              "name": "source",
              "type": "typeparam T",
              "is_comptime": true
            }
          ],
          "return_type": "typeparam"
        },
        {
          "name": "partial",
          "is_pub": true,
          "is_declare": true,
          "generic_params": [
            "T"
          ],
          "params": [
            {
              "name": "source",
              "type": "typeparam T",
              "is_comptime": true
            }
          ],
          "return_type": "typeparam"
        },
        {
          "name": "required",
          "is_pub": true,
          "is_declare": true,
          "generic_params": [
            "T"
          ],
          "params": [
            {
              "name": "source",
              "type": "typeparam T",
              "is_comptime": true
            }
          ],
          "return_type": "typeparam"
        },
        {
          "name": "merge",
          "is_pub": true,
          "is_declare": true,
          "generic_params": [
            "A",
            "B"
          ],
          "params": [
            {
              "name": "first",
              "type": "typeparam A",
              "is_comptime": true
            },
            {
              "name": "second",
              "type": "typeparam B",
              "is_comptime": true
            }
          ],
          "return_type": "typeparam"
        },
        {
          "name": "pick",
          "is_pub": true,
          "is_declare": true,
          "generic_params": [
            "T"
          ],
          "params": [
            {
              "name": "source",
              "type": "typeparam T",
              "is_comptime": true
            },
            {
              "name": "fields",
              "type": "Type__Field<T>[]",
              "is_comptime": true
            }
          ],
          "return_type": "typeparam"
        },
        {
          "name": "omit",
          "is_pub": true,
          "is_declare": true,
          "generic_params": [
            "T"
          ],
          "params": [
            {
              "name": "source",
              "type": "typeparam T",
              "is_comptime": true
            },
            {
              "name": "fields",
              "type": "Type__Field<T>[]",
              "is_comptime": true
            }
          ],
          "return_type": "typeparam"
        }
      ]
    },
    {
      "ast": "record_def",
      "name": "Type__Field",
      "generic": [
        "T"
      ],
      "fields": {
        "name": "string",
        "typeName": "string",
        "annotations": "__Decl__Annotation[]"
      },
      "methods": [
        {
          "name": "of",
          "is_pub": true,
          "is_declare": true,
          "params": [
            {
              "name": "text",
              "type": "string"
            }
          ],
          "return_type": "?Type__Field<T>"
        },
        {
          "name": "all",
          "is_pub": true,
          "is_declare": true,
          "params": [],
          "return_type": "Type__Field<T>[]"
        }
      ]
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

import {compiler, compiler.Span, compiler.CustomNode} from "std";
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

