```json
{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "effect": "resultGenerator",
        "isDeclare": false,
        "isDefault": false,
        "label": null,
        "name": "fib",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [
          {
            "name": "resultGenerator",
            "args": [],
            "is_builtin": true
          }
        ],
        "genericParams": [],
        "params": [],
        "returnType": {
          "generic": {
            "name": "ResultGenerator",
            "args": [
              {
                "named": "Int"
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