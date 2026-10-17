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
        "name": "render",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "tag",
            "typeRef": {
              "typeparam": [
                {
                  "named": "string"
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
            "name": "props",
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
          "named": "string"
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