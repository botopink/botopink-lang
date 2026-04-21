```json
{
  "decls": [
    {
      "fn": {
        "isPub": true,
        "name": "where",
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
            "name": "pred",
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
              "returnType": "bool"
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
                  "builtinCall": {
                    "name": "@todo",
                    "args": []
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