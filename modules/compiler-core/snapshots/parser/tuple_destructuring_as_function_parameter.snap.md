```json
{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "name": "process",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "",
            "typeRef": {
              "tuple_": [
                {
                  "named": "i32"
                },
                {
                  "named": "i32"
                }
              ]
            },
            "typeName": "",
            "modifier": "none",
            "typeinfoConstraints": null,
            "fnType": null,
            "destruct": {
              "tuple_": [
                "x",
                "y"
              ]
            },
            "defaultVal": null
          }
        ],
        "returnType": {
          "named": "i32"
        },
        "body": [
          {
            "expr": {
              "controlFlow": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "identifier": {
                      "loc": {
                        "line": 2,
                        "col": 12
                      },
                      "kind": {
                        "ident": "x"
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