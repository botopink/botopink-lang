{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "name": "process",
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "prefix",
            "typeName": "string",
            "modifier": "none",
            "typeinfoConstraints": null,
            "fnType": null,
            "destruct": null
          },
          {
            "name": "",
            "typeName": "Person",
            "modifier": "none",
            "typeinfoConstraints": null,
            "fnType": null,
            "destruct": {
              "record_": [
                "name"
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
                    "ident": "prefix"
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