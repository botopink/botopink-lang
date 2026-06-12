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
        "name": "f",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [],
        "returnType": null,
        "body": [
          {
            "expr": {
              "comptime_": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "assert": {
                    "condition": {
                      "identifier": {
                        "loc": {
                          "line": 2,
                          "col": 12
                        },
                        "kind": {
                          "ident": "false"
                        }
                      }
                    },
                    "message": {
                      "literal": {
                        "loc": {
                          "line": 2,
                          "col": 19
                        },
                        "kind": {
                          "stringLit": "should be true"
                        }
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