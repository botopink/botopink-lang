```json
{
  "decls": [
    {
      "fn": {
        "isPub": true,
        "effect": "stream",
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
            "name": "Stream",
            "args": [
              {
                "generic": {
                  "name": "Result",
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