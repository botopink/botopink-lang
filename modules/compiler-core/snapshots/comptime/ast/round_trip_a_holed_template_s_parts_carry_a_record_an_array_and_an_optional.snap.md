----- SOURCE CODE -- main.bp
```botopink
pub type Point(x: i32, y: i32)
pub fn holes<T>(comptime q: @Expr<string>) -> @Expr<T> {
    var codes: Array<string> = [];
    var texts = "";
    var spans = "";
    for (q.parts()) { p ->
        if (p.kind == "Interp") { codes.push(p.code); };
        if (p.kind == "Text") { texts = texts + p.text; };
        spans = spans + p.span.start.toString() + "-" + p.span.end.toString() + ";";
    };
    return q.build("#(" + codes.join(", ") + ", \"" + texts + "\", \"" + spans + "\")");
}
val origin = Point(x: 3, y: 4);
val xs = [1, 2, 3];
val maybe: ?i32 = null;
val got = holes """p=${origin} xs=${xs} m=${maybe}""";
```

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
pub type Point(x: i32, y: i32)

pub val origin = Point(x: 3, y: 4);

pub val xs = [1, 2, 3];

pub val maybe: ?i32 = null;

pub val got = #(
    origin,
    xs,
    maybe,
    "p= xs= m=",
    "0-2;2-15;15-19;19-32;32-35;35-48;",
);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "Point",
      "fields": {
        "x": "i32",
        "y": "i32"
      }
    },
    {
      "ast": "fn_def",
      "name": "holes",
      "is_pub": true,
      "generic_params": [
        "T"
      ],
      "params": [
        {
          "name": "q",
          "type": "Expr<string>",
          "is_comptime": true
        }
      ],
      "return_type": "Expr<'a>",
      "body": [
        {
          "source": "var codes: Array<string> = [];"
        },
        {
          "source": "var texts = \"\";"
        },
        {
          "source": "var spans = \"\";"
        },
        {
          "source": "for (q.parts()) { p ->"
        },
        {
          "source": "return q.build(\"#(\" + codes.join(\", \") + \", \\\"\" + texts + \"\\\", \\\"\" + spans + \"\\\")\");"
        }
      ]
    },
    {
      "ast": "val",
      "ident": "origin",
      "return_type": "Point",
      "expr": {
        "ast": "call",
        "params": [
          {
            "name": "x",
            "value": "i32"
          },
          {
            "name": "y",
            "value": "i32"
          }
        ],
        "return_type": "Point"
      }
    },
    {
      "ast": "val",
      "ident": "xs",
      "return_type": "i32[]"
    },
    {
      "ast": "val",
      "ident": "maybe",
      "return_type": "?i32"
    },
    {
      "ast": "val",
      "ident": "got",
      "return_type": "#(Point,i32[],?i32,string,string)"
    }
  ]
}
```

