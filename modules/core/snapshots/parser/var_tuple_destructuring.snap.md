{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "name": "swap",
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "x",
            "typeName": "i32",
            "modifier": "none",
            "typeinfoConstraints": null,
            "fnType": null,
            "destruct": null
          },
          {
            "name": "y",
            "typeName": "i32",
            "modifier": "none",
            "typeinfoConstraints": null,
            "fnType": null,
            "destruct": null
          }
        ],
        "returnType": {
          "named": "i32"
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
                    "tuple_": [
                      "a",
                      "b"
                    ]
                  },
                  "value": {
                    "loc": {
                      "line": 2,
                      "col": 19
                    },
                    "kind": {
                      "tupleLit": [
                        {
                          "loc": {
                            "line": 2,
                            "col": 21
                          },
                          "kind": {
                            "ident": "x"
                          }
                        },
                        {
                          "loc": {
                            "line": 2,
                            "col": 24
                          },
                          "kind": {
                            "ident": "y"
                          }
                        }
                      ]
                    }
                  },
                  "mutable": true
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
                    "ident": "a"
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