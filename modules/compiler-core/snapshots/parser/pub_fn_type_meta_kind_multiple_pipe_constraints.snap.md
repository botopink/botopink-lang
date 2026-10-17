```json
{
  "decls": [
    {
      "fn": {
        "isPub": true,
        "effect": null,
        "isDeclare": false,
        "isDefault": false,
        "label": null,
        "name": "coerce",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "v",
            "typeRef": {
              "typeparam": [
                {
                  "named": "string"
                },
                {
                  "named": "int"
                },
                {
                  "named": "bool"
                }
              ]
            },
            "typeName": "",
            "modifier": "comptime",
            "destruct": null,
            "default": null,
            "exprWrapped": true,
            "arrival": "value"
          },
          {
            "name": "x",
            "typeRef": {
              "named": "i32"
            },
            "typeName": "",
            "modifier": "none",
            "destruct": null,
            "default": null
          }
        ],
        "returnType": {
          "named": "i32"
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