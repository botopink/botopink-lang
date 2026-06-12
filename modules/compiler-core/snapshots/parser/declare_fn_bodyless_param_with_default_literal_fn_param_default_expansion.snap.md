```json
{
  "decls": [
    {
      "delegate": {
        "name": "slice",
        "isPub": true,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "params": [
          {
            "name": "s",
            "typeRef": {
              "named": "string"
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": null
          },
          {
            "name": "start",
            "typeRef": {
              "named": "i32"
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": null
          },
          {
            "name": "end",
            "typeRef": {
              "named": "i32"
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": {
              "unaryOp": {
                "loc": {
                  "line": 1,
                  "col": 56
                },
                "op": "neg",
                "expr": {
                  "literal": {
                    "loc": {
                      "line": 1,
                      "col": 57
                    },
                    "kind": {
                      "numberLit": "1"
                    }
                  }
                }
              }
            }
          }
        ],
        "returnType": "string"
      }
    }
  ]
}
```