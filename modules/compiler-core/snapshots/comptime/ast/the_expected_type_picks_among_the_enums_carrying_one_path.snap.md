----- SOURCE CODE -- main.bp
```botopink
type Token {
    Color {
        Red { 100, 500 }
    }
}
type Border {
    Color {
        Red { 100, 500 }
    }
}
fn onToken(t: Token) -> i32 { return 1; }
fn onBorder(b: Border) -> i32 { return 2; }
fn pick() -> Border { return .Color.Red.500; }
val a: Token = .Color.Red.500;
val b: Border = .Color.Red.500;
val c: Array<Token> = [.Color.Red.100];
val d = onToken(.Color.Red.100);
val e = onBorder(.Color.Red.100);
type BoxT(w: i32 = 7, tone: Token)
type BoxB(w: i32 = 7, tone: Border)
val f = BoxT(tone: .Color.Red.100);
val g = BoxB(tone: .Color.Red.100);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "enum_def",
      "name": "Token",
      "sections": [
        {
          "name": "Color",
          "sections": [
            {
              "name": "Red",
              "variants": [
                {
                  "name": "100"
                },
                {
                  "name": "500"
                }
              ]
            }
          ]
        }
      ]
    },
    {
      "ast": "enum_def",
      "name": "Border",
      "sections": [
        {
          "name": "Color",
          "sections": [
            {
              "name": "Red",
              "variants": [
                {
                  "name": "100"
                },
                {
                  "name": "500"
                }
              ]
            }
          ]
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "onToken",
      "is_pub": false,
      "params": [
        {
          "name": "t",
          "type": "Token"
        }
      ],
      "return_type": "i32",
      "body": [
        {
          "source": "fn onToken(t: Token) -> i32 { return 1; }"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "onBorder",
      "is_pub": false,
      "params": [
        {
          "name": "b",
          "type": "Border"
        }
      ],
      "return_type": "i32",
      "body": [
        {
          "source": "fn onBorder(b: Border) -> i32 { return 2; }"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "pick",
      "is_pub": false,
      "params": [],
      "return_type": "Border",
      "body": [
        {
          "source": "fn pick() -> Border { return .Color.Red.500; }"
        }
      ]
    },
    {
      "ast": "val",
      "ident": "a",
      "return_type": "Token",
      "expr": {
        "ast": "call",
        "params": [
          {
            "name": "_inner",
            "value": "__Token__Color"
          }
        ],
        "return_type": "Token"
      }
    },
    {
      "ast": "val",
      "ident": "b",
      "return_type": "Border",
      "expr": {
        "ast": "call",
        "params": [
          {
            "name": "_inner",
            "value": "__Border__Color"
          }
        ],
        "return_type": "Border"
      }
    },
    {
      "ast": "val",
      "ident": "c",
      "return_type": "Token[]"
    },
    {
      "ast": "val",
      "ident": "d",
      "return_type": "i32",
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "Token"
          }
        ],
        "return_type": "i32"
      }
    },
    {
      "ast": "val",
      "ident": "e",
      "return_type": "i32",
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "Border"
          }
        ],
        "return_type": "i32"
      }
    },
    {
      "ast": "record_def",
      "name": "BoxT",
      "fields": {
        "w": "i32",
        "tone": "Token"
      }
    },
    {
      "ast": "record_def",
      "name": "BoxB",
      "fields": {
        "w": "i32",
        "tone": "Border"
      }
    },
    {
      "ast": "val",
      "ident": "f",
      "return_type": "BoxT",
      "expr": {
        "ast": "call",
        "params": [
          {
            "name": "tone",
            "value": "Token"
          }
        ],
        "return_type": "BoxT"
      }
    },
    {
      "ast": "val",
      "ident": "g",
      "return_type": "BoxB",
      "expr": {
        "ast": "call",
        "params": [
          {
            "name": "tone",
            "value": "Border"
          }
        ],
        "return_type": "BoxB"
      }
    }
  ]
}
```

