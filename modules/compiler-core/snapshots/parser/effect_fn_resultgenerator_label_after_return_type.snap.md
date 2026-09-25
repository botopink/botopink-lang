```json
{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "effect": "resultGenerator",
        "isDeclare": false,
        "isDefault": false,
        "label": "gen",
        "name": "gen",
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
                    "label": "gen",
                    "value": {
                      "literal": {
                        "loc": {
                          "line": 3,
                          "col": 16
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