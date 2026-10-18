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
            "name": "external",
            "args": [
              ".Erlang(\"erlang:error({todo, $0})\")",
              ".JavaScript(\"(() => { throw new Error($0) })()\")"
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
            "destruct": null,
            "default": {
              "literal": {
                "loc": {
                  "line": 2,
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
        "typeGuardParam": null,
        "body": [
          {
            "expr": {
              "jump": {
                "loc": {
                  "line": 3,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "identifier": {
                      "loc": {
                        "line": 3,
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