----- SOURCE CODE -- main.bp
```botopink
fn column(comptime decl: @Decl, name: string) { }
fn describe(comptime decl: @Decl, label: string) {
    var out = decl.name + "[" + label + "]";
    for (decl.annotations) { a -> out = out + " @" + a.name + "(" + a.args.join(",") + ")"; };
    for (decl.fields) { f ->
        out = out + " field " + f.name + ":" + f.typeName;
        for (f.annotations) { a -> out = out + " @" + a.name + "(" + a.args.join(",") + ")"; };
    };
    for (decl.variants) { v -> out = out + " variant " + v; };
    for (decl.methods) { m ->
        var ps = "";
        for (m.params) { p -> ps = ps + p.name + ":" + p.typeName + ";"; };
        out = out + " method " + m.name + "(" + ps + ")->" + m.returnType;
    };
    @emit("pub fn describe" + decl.name + "() -> string { return \"\"\"" + out + "\"\"\"; }");
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
          "type": "Decl",
          "is_comptime": true
        },
        {
          "name": "name",
          "type": "string"
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
          "type": "Decl",
          "is_comptime": true
        },
        {
          "name": "label",
          "type": "string"
        }
      ],
      "return_type": "void",
      "body": [
        {
          "source": "var out = decl.name + \"[\" + label + \"]\";"
        },
        {
          "source": "for (decl.annotations) { a -> out = out + \" @\" + a.name + \"(\" + a.args.join(\",\") + \")\"; };"
        },
        {
          "source": "for (decl.fields) { f ->"
        },
        {
          "source": "for (decl.variants) { v -> out = out + \" variant \" + v; };"
        },
        {
          "source": "for (decl.methods) { m ->"
        },
        {
          "source": "@emit(\"pub fn describe\" + decl.name + \"() -> string { return \\\"\\\"\\\"\" + out + \"\\\"\\\"\\\"; }\");"
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
          "source": "val m = describeMode();"
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
          "source": "val m = describeMode();"
        }
      ]
    }
  ]
}
```

