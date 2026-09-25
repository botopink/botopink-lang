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
        "annotations": [
          {
            "name": "mark",
            "args": [
              "-20"
            ],
            "is_builtin": false
          }
        ],
        "genericParams": [],
        "params": [],
        "returnType": {
          "named": "i32"
        },
        "typeGuardParam": null,
        "body": [
          {
            "expr": {
              "jump": {
                "loc": {
                  "line": 2,
                  "col": 17
                },
                "kind": {
                  "return": {
                    "literal": {
                      "loc": {
                        "line": 2,
                        "col": 24
                      },
                      "kind": {
                        "numberLit": "1"
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
    },
    {
      "fn": {
        "isPub": false,
        "effect": null,
        "isDeclare": false,
        "isDefault": false,
        "label": null,
        "name": "g",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [
          {
            "name": "order",
            "args": [
              "-100"
            ],
            "is_builtin": false
          },
          {
            "name": "tag",
            "args": [
              "\"x\"",
              "-1"
            ],
            "is_builtin": false
          }
        ],
        "genericParams": [],
        "params": [],
        "returnType": {
          "named": "i32"
        },
        "typeGuardParam": null,
        "body": [
          {
            "expr": {
              "jump": {
                "loc": {
                  "line": 4,
                  "col": 17
                },
                "kind": {
                  "return": {
                    "literal": {
                      "loc": {
                        "line": 4,
                        "col": 24
                      },
                      "kind": {
                        "numberLit": "2"
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