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
        "name": "collect",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [
          {
            "name": "T",
            "default": null
          }
        ],
        "params": [
          {
            "name": "first",
            "typeRef": {
              "generic": {
                "name": "Expr",
                "args": [
                  {
                    "optional": {
                      "generic": {
                        "name": "Expr",
                        "args": [
                          {
                            "named": "Element"
                          }
                        ],
                        "is_builtin": true
                      }
                    }
                  }
                ],
                "is_builtin": true
              }
            },
            "typeName": "",
            "modifier": "comptime",
            "destruct": null,
            "default": null,
            "arrival": "value"
          }
        ],
        "returnType": {
          "generic": {
            "name": "Expr",
            "args": [
              {
                "named": "T"
              }
            ],
            "is_builtin": true
          }
        },
        "typeGuardParam": null,
        "body": [
          {
            "expr": {
              "call": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "call": {
                    "receiver": null,
                    "callee": "todo",
                    "is_builtin": true,
                    "is_tagged": false,
                    "optional": false,
                    "args": [],
                    "trailing": []
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