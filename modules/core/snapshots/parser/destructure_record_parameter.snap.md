{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "name": "greet",
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "",
            "typeName": "Person",
            "modifier": "none",
            "typeinfoConstraints": null,
            "fnType": null,
            "destruct": {
              "record_": [
                "name",
                "age"
              ]
            }
          }
        ],
        "returnType": {
          "named": "string"
        },
        "body": [
          {
            "expr": {
              "loc": {
                "line": 2,
                "col": 5
              },
              "kind": {
                "return": {
                  "loc": {
                    "line": 2,
                    "col": 12
                  },
                  "kind": {
                    "ident": "name"
                  }
                }
              }
            }
          }
        ]
      }
    }
  ]
}