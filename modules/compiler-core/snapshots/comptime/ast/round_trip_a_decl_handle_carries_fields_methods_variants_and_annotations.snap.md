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
//// the behavior below, member for member.
////
//// - The point: `src`, `module`, `package`, `isStd`.
//// - The outputs, a decorator's only (`compiler-output-outside-decorator`):
////   `setMeta`, `addMeta`, `addMember`, `addType`, `wrapWith`, `compile`.
//// - The reads of an `expr` (decision 576 (2)): `text`, `name`, `source`,
////   `context`, `lookup`, `bindings`, `fail`.
//// - A template's call site: `build`, `buildType`, `note`, `tagDecl`,
////   `annotate`, `custom` (decision 578 (3)).
//// - A declaration handle's reads (decision 576 (3)): `name`, `kind`,
////   `moduleOf`, `meta`, `metaAll`, `attr`, `component`, `hooks`, `fields`,
////   `methods`, `params`, `returnType`, `owner`, `annotations`, `variants`.
//// - The program: `catalogue`, `typeInfo`.
////
//// `implement`, `setBuiltin`, `embed`, `fields` over a type,
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
    fn fail(self: Self, message: string, at: unknown, span: ?Span);
    // A note at the template's call site (decision 426 (4)).
    fn note(self: Self, message: string);

    // ── The outputs (a decorator's only) ──────────────────────────────────
    // A typed meta value, one per type per declaration (decision 298).
    fn setMeta<M>(self: Self, value: M);
    // A typed meta value that repeats (decision 298).
    fn addMeta<M>(self: Self, value: M);
    // A member of the annotated type, a function written at the call
    // (decision 370 (2)).
    fn addMember<F>(self: Self, name: string, member: F);
    // An associated type of the annotated type (decision 216 (3)).
    fn addType(self: Self, name: string, source: string);
    // A wrapper of the annotated function, a lambda written at the call
    // (decision 316).
    fn wrapWith<F>(self: Self, wrapper: F);
    // Run-time code compiled beside the annotated declaration, run once
    // before `main` in the program's init list: modules in dependency order,
    // declarations in source order, calls in order (decision 575 (3)).
    fn compile(self: Self, executor: fn());

    // ── The reads of an `expr` (decision 576 (2)) ─────────────────────────
    // The expression as written.
    fn text(self: Self, e: unknown) -> string;
    // The name the expression is written as, or the declaration's name;
    // `null` for a lambda or `a + b`.
    fn name(self: Self, e: unknown) -> ?string;
    // A template text's source and the context it stands in.
    fn source(self: Self, e: unknown) -> Source;
    fn context(self: Self, e: unknown) -> ExprContext;
    // A name resolved where the call stands, and every name in scope there.
    fn lookup(self: Self, e: unknown, name: string) -> unknown;
    fn bindings(self: Self, e: unknown) -> unknown[];

    // ── A template's call site ────────────────────────────────────────────
    // Code built from source text, typed at the call (decisions 426 (1),
    // 578 (3)).
    fn build(self: Self, source: string) -> anyvalue;
    // A type built from source text — the one way a type is built
    // (decision 578 (3)).
    fn buildType(self: Self, source: string) -> anytype;
    // A tag's declaration handle (decision 302), and a handle's annotation.
    fn tagDecl(self: Self, kind: DeclKind, name: string, attrs: unknown) -> unknown;
    fn annotate(self: Self, d: unknown, at: Span) -> unknown;
    // The reference tree the language server reads, by call location.
    fn custom(self: Self, ast: CustomNode);

    // ── A declaration handle's reads (decision 576 (3)) ───────────────────
    fn kind(self: Self, d: unknown) -> DeclKind;
    fn moduleOf(self: Self, d: unknown) -> string;
    fn meta<M>(self: Self, d: unknown) -> ?M;
    fn metaAll<M>(self: Self, d: unknown) -> M[];
    fn attr(self: Self, d: unknown, name: string) -> ?string;
    fn component(self: Self, d: unknown) -> unknown;
    fn hooks(self: Self, d: unknown) -> HookNode[];
    fn fields(self: Self, d: unknown) -> Field[];
    fn methods(self: Self, d: unknown) -> Method[];
    fn params(self: Self, d: unknown) -> Param[];
    fn returnType(self: Self, d: unknown) -> string;
    fn owner(self: Self, d: unknown) -> unknown;
    fn annotations(self: Self, d: unknown) -> DeclAnnotation[];
    fn variants(self: Self, d: unknown) -> string[];

    // ── The program ───────────────────────────────────────────────────────
    // The declarations a decorator marks (decision 253), read at build.
    fn catalogue(self: Self, with: unknown, member: unknown) -> unknown[];
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
              "type": "unknown"
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
              "type": "M"
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
              "type": "M"
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
              "type": "F"
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
              "type": "string"
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
              "type": "F"
            }
          ],
          "return_type": "void"
        },
        {
          "name": "compile",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "executor",
              "type": "fn() -> void"
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
              "type": "unknown"
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
              "type": "unknown"
            }
          ],
          "return_type": "?string"
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
              "type": "unknown"
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
              "type": "unknown"
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
              "type": "unknown"
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
              "type": "unknown"
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
              "type": "string"
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
              "type": "string"
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
              "type": "unknown"
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
              "type": "unknown"
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
              "type": "unknown"
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
              "type": "unknown"
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
              "type": "unknown"
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
              "type": "unknown"
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
              "type": "unknown"
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
              "type": "unknown"
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
              "type": "unknown"
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
              "type": "unknown"
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
              "type": "unknown"
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
              "type": "unknown"
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
              "type": "unknown"
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
              "type": "unknown"
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
              "type": "unknown"
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
              "type": "unknown"
            }
          ],
          "return_type": "string[]"
        },
        {
          "name": "catalogue",
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
              "type": "unknown"
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
    }
  ]
}
```


----- SOURCE CODE -- main.bp
```botopink
fn column(expr decl: unknown, comptime name: string) { }
fn describe(expr decl: unknown, comptime label: string) {
    var out = compiler.name(decl)! + "[" + label + "]";
    for (compiler.annotations(decl)) { a -> out = out + " @" + a.name + "(" + a.args.join(",") + ")"; };
    for (compiler.fields(decl)) { f ->
        out = out + " field " + f.name + ":" + f.typeName;
        for (f.annotations) { a -> out = out + " @" + a.name + "(" + a.args.join(",") + ")"; };
    };
    for (compiler.variants(decl)) { v -> out = out + " variant " + v; };
    for (compiler.methods(decl)) { m ->
        var ps = "";
        for (m.params) { p -> ps = ps + p.name + ":" + p.typeName + ";"; };
        out = out + " method " + m.name + "(" + ps + ")->" + m.returnType;
    };
    @emit("pub fn describe" + compiler.name(decl)! + "() -> string { return \"\"\"" + out + "\"\"\"; }");
}
#[describe("record")]
type Point(#[column("px")] x: i32, y: ?i32) {
    fn scaled(self: Self, by: i32) -> Point {
        return Point(x: self.x * by, y: self.y);
    }
}
#[describe("enum")]
type Mode {
    Fast,
    Slow,
    fn label(self: Self) -> string {
        return "mode";
    }
}
val p = describePoint();
val m = describeMode();
import {compiler} from "std";
```

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
#[describe("record")]
type Point(#[column("px")] x: i32, y: ?i32) {
    fn scaled(self: Self, by: i32) -> Point {
        return Point(x: self.x * by, y: self.y);
    }
}

#[describe("enum")]
type Mode {
    Fast,
    Slow,

    fn label(self: Self) -> string {
        return "mode";
    }
}

val p = describePoint();

val m = describeMode();

import {compiler} from "std";

pub fn describePoint() -> string {
    return """Point[record] @describe("record") field x:i32 @column("px") field y:?i32 method scaled(self:Self;by:i32;)->Point""";
}

pub fn describeMode() -> string {
    return """Mode[enum] @describe("enum") variant Fast variant Slow method label(self:Self;)->string""";
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "column",
      "is_pub": false,
      "params": [
        {
          "name": "decl",
          "type": "__Decl",
          "is_comptime": true
        },
        {
          "name": "name",
          "type": "string",
          "is_comptime": true
        }
      ],
      "return_type": "void",
      "body": []
    },
    {
      "ast": "fn_def",
      "name": "describe",
      "is_pub": false,
      "params": [
        {
          "name": "decl",
          "type": "__Decl",
          "is_comptime": true
        },
        {
          "name": "label",
          "type": "string",
          "is_comptime": true
        }
      ],
      "return_type": "void",
      "body": [
        {
          "source": "var out = compiler.name(decl)! + \"[\" + label + \"]\";"
        },
        {
          "source": "for (compiler.annotations(decl)) { a -> out = out + \" @\" + a.name + \"(\" + a.args.join(\",\") + \")\"; };"
        },
        {
          "source": "for (compiler.fields(decl)) { f ->"
        },
        {
          "source": "for (compiler.variants(decl)) { v -> out = out + \" variant \" + v; };"
        },
        {
          "source": "for (compiler.methods(decl)) { m ->"
        },
        {
          "source": "@emit(\"pub fn describe\" + compiler.name(decl)! + \"() -> string { return \\\"\\\"\\\"\" + out + \"\\\"\\\"\\\"; }\");"
        }
      ]
    },
    {
      "ast": "record_def",
      "name": "Point",
      "fields": {
        "x": "i32",
        "y": "?i32"
      },
      "methods": [
        {
          "name": "scaled",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "by",
              "type": "i32"
            }
          ],
          "return_type": "Point"
        }
      ]
    },
    {
      "ast": "enum_def",
      "name": "Mode",
      "variants": [
        {
          "name": "Fast"
        },
        {
          "name": "Slow"
        }
      ],
      "methods": [
        {
          "name": "label",
          "params": [
            {
              "name": "self",
              "type": "Self"
            }
          ],
          "return_type": "string"
        }
      ]
    },
    {
      "ast": "val",
      "ident": "p",
      "return_type": "string",
      "expr": {
        "ast": "call",
        "params": [],
        "return_type": "string"
      }
    },
    {
      "ast": "val",
      "ident": "m",
      "return_type": "string",
      "expr": {
        "ast": "call",
        "params": [],
        "return_type": "string"
      }
    },
    {
      "ast": "fn_def",
      "name": "describePoint",
      "is_pub": true,
      "params": [],
      "return_type": "string",
      "body": [
        {
          "source": "import {compiler} from \"std\";"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "describeMode",
      "is_pub": true,
      "params": [],
      "return_type": "string",
      "body": [
        {
          "source": "import {compiler} from \"std\";"
        }
      ]
    }
  ]
}
```

