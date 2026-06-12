```json
{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "effect": "iterator",
        "isDeclare": false,
        "isDefault": false,
        "label": "gen",
        "name": "gen",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [],
        "returnType": {
          "generic": {
            "name": "Iterator",
            "args": [
              {
                "named": "Int"
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
                    "label": "gen",
                    "value": {
                      "literal": {
                        "loc": {
                          "line": 2,
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