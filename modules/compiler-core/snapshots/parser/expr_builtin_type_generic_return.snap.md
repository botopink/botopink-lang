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
            "name": "T"
          }
        ],
        "params": [
          {
            "name": "template",
            "typeRef": {
              "generic": {
                "name": "Expr",
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
            "fnType": null,
            "destruct": null,
            "defaultVal": null
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