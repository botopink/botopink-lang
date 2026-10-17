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
        "name": "repeat",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "s",
            "typeRef": {
              "named": "string"
            },
            "typeName": "",
            "modifier": "comptime",
            "destruct": null,
            "default": null,
            "exprWrapped": true,
            "arrival": "value"
          },
          {
            "name": "n",
            "typeRef": {
              "named": "int"
            },
            "typeName": "",
            "modifier": "comptime",
            "destruct": null,
            "default": null,
            "exprWrapped": true,
            "arrival": "value"
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