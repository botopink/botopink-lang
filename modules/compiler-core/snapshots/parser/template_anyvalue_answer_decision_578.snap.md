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
        "name": "yaml",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [
          {
            "name": "__anyvalue",
            "default": null
          }
        ],
        "params": [
          {
            "name": "template",
            "typeRef": {
              "generic": {
                "name": "__Expr",
                "args": [
                  {
                    "named": "string"
                  }
                ],
                "is_builtin": true
              }
            },
            "typeName": "",
            "modifier": "comptime",
            "destruct": null,
            "default": null,
            "arrival": "expr"
          }
        ],
        "returnType": {
          "generic": {
            "name": "__Expr",
            "args": [
              {
                "named": "__anyvalue"
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