```json
{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "effect": null,
        "isDeclare": false,
        "isDefault": false,
        "label": null,
        "name": "todo",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [
          {
            "name": "External.Erlang",
            "args": [
              "\"erlang:error({todo, $0})\""
            ],
            "is_builtin": true
          },
          {
            "name": "External.Node",
            "args": [
              "\"(() => { throw new Error($0) })()\""
            ],
            "is_builtin": true
          }
        ],
        "genericParams": [],
        "params": [
          {
            "name": "message",
            "typeRef": {
              "named": "string"
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": {
              "literal": {
                "loc": {
                  "line": 3,
                  "col": 27
                },
                "kind": {
                  "stringLit": "not implemented"
                }
              }
            }
          }
        ],
        "returnType": {
          "named": "bool"
        },
        "body": [
          {
            "expr": {
              "jump": {
                "loc": {
                  "line": 4,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "identifier": {
                      "loc": {
                        "line": 4,
                        "col": 12
                      },
                      "kind": {
                        "ident": "true"
                      }
                    }
                  }
                }
              }
            },
            "emptyLinesBefore": 0
          }
        ]
      }
    }
  ]
}
```