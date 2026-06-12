```json
{
  "decls": [
    {
      "fn": {
        "isPub": true,
        "effect": "asyncGenerator",
        "isDeclare": false,
        "isDefault": false,
        "label": null,
        "name": "stream",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [],
        "returnType": {
          "generic": {
            "name": "AsyncIterator",
            "args": [
              {
                "named": "Int"
              },
              {
                "named": "Error"
              }
            ],
            "is_builtin": true
          }
        },
        "body": [
          {
            "expr": {
              "jump": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "yield": {
                    "label": null,
                    "value": {
                      "literal": {
                        "loc": {
                          "line": 2,
                          "col": 11
                        },
                        "kind": {
                          "numberLit": "1"
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