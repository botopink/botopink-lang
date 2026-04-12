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
            "name": "person",
            "typeName": "Person",
            "modifier": "none",
            "typeinfoConstraints": null,
            "fnType": null,
            "destruct": null
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
                "localBindDestruct": {
                  "pattern": {
                    "record_": [
                      "name",
                      "age"
                    ]
                  },
                  "value": {
                    "loc": {
                      "line": 2,
                      "col": 25
                    },
                    "kind": {
                      "ident": "person"
                    }
                  },
                  "mutable": false
                }
              }
            }
          },
          {
            "expr": {
              "loc": {
                "line": 3,
                "col": 5
              },
              "kind": {
                "return": {
                  "loc": {
                    "line": 3,
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