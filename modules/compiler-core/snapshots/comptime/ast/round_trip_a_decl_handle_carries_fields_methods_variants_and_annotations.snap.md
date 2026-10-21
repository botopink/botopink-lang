----- SOURCE CODE -- main.bp
```botopink
fn column(syntax decl: unknown, comptime name: string) -> void { }
fn describe(syntax decl: unknown, comptime label: string) -> void {
    var out = compiler.name(decl)! + "[" + label + "]";
    for a in compiler.annotations(decl) { out = out + " @" + a.name + "(" + a.args.join(",") + ")"; };
    for f in compiler.fields(decl) {
        out = out + " field " + f.name + ":" + f.typeName;
        for a in f.annotations { out = out + " @" + a.name + "(" + a.args.join(",") + ")"; };
    };
    for v in compiler.variants(decl) { out = out + " variant " + v.name; };
    for m in compiler.methods(decl) {
        var ps = "";
        for p in m.params { ps = ps + p.name + ":" + p.typeName + ";"; };
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
          "source": "for a in compiler.annotations(decl) { out = out + \" @\" + a.name + \"(\" + a.args.join(\",\") + \")\"; };"
        },
        {
          "source": "for f in compiler.fields(decl) {"
        },
        {
          "source": "for v in compiler.variants(decl) { out = out + \" variant \" + v.name; };"
        },
        {
          "source": "for m in compiler.methods(decl) {"
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

