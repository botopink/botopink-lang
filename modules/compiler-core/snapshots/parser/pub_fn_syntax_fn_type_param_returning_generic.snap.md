```json
{
  "decls": [
    {
      "fn": {
        "isPub": true,
        "name": "select",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [
          {
            "name": "T"
          },
          {
            "name": "R"
          }
        ],
        "params": [
          {
            "name": "lamb",
            "typeRef": {
              "named": "fn"
            },
            "typeName": "fn",
            "modifier": "syntax",
            "typeinfoConstraints": null,
            "fnType": {
              "params": [
                {
                  "name": "item",
                  "typeName": "T"
                }
              ],
              "returnType": "R"
            },
            "destruct": null,
            "defaultVal": null
          }
        ],
        "returnType": null,
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
                    "callee": "@todo",
                    "is_builtin": true,
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