```json
{
  "decls": [
    {
      "fn": {
        "isPub": true,
        "effect": "futureGenerator",
        "isDeclare": false,
        "isDefault": false,
        "label": null,
        "name": "stream",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [
          {
            "name": "futureGenerator",
            "args": [],
            "is_builtin": true
          }
        ],
        "genericParams": [],
        "params": [],
        "returnType": {
          "generic": {
            "name": "FutureGenerator",
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
                  "yield": {
                    "label": null,
                    "value": {
                      "literal": {
                        "loc": {
                          "line": 3,
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