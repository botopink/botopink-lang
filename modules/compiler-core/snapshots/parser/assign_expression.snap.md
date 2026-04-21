```json
{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "name": "f",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [],
        "returnType": null,
        "body": [
          {
            "expr": {
              "binding": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "total",
                    "value": {
                      "literal": {
                        "loc": {
                          "line": 2,
                          "col": 17
                        },
                        "kind": {
                          "numberLit": "0"
                        }
                      }
                    },
                    "mutable": true
                  }
                }
              }
            },
            "emptyLinesBefore": 0
          },
          {
            "expr": {
              "binding": {
                "loc": {
                  "line": 3,
                  "col": 5
                },
                "kind": {
                  "assign": {
                    "name": "total",
                    "value": {
                      "binaryOp": {
                        "loc": {
                          "line": 3,
                          "col": 19
                        },
                        "kind": {
                          "add": {
                            "lhs": {
                              "identifier": {
                                "loc": {
                                  "line": 3,
                                  "col": 13
                                },
                                "kind": {
                                  "ident": "total"
                                }
                              }
                            },
                            "rhs": {
                              "literal": {
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