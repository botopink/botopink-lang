{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "name": "f",
        "annotations": [],
        "genericParams": [],
        "params": [],
        "returnType": null,
        "body": [
          {
            "expr": {
              "loc": {
                "line": 2,
                "col": 5
              },
              "kind": {
                "localBind": {
                  "name": "total",
                  "value": {
                    "loc": {
                      "line": 2,
                      "col": 17
                    },
                    "kind": {
                      "numberLit": "0"
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
                "assign": {
                  "name": "total",
                  "value": {
                    "loc": {
                      "line": 3,
                      "col": 19
                    },
                    "kind": {
                      "add": {
                        "lhs": {
                          "loc": {
                            "line": 3,
                            "col": 13
                          },
                          "kind": {
                            "ident": "total"
                          }
                        },
                        "rhs": {
                          "loc": {
                            "line": 3,
                            "col": 21
                          },
                          "kind": {
                            "numberLit": "1"
                          }
                        }
                      }
                    }
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