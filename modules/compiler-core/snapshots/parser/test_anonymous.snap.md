```json
{
  "decls": [
    {
      "test": {
        "name": null,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "loc": {
          "line": 1,
          "col": 1
        },
        "body": [
          {
            "expr": {
              "comptime_": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "assert": {
                    "condition": {
                      "binaryOp": {
                        "loc": {
                          "line": 2,
                          "col": 18
                        },
                        "op": "eq",
                        "lhs": {
                          "binaryOp": {
                            "loc": {
                              "line": 2,
                              "col": 14
                            },
                            "op": "add",
                            "lhs": {
                              "literal": {
                                "loc": {
                                  "line": 2,
                                  "col": 12
                                },
                                "kind": {
                                  "numberLit": "1"
                                }
                              }
                            },
                            "rhs": {
                              "literal": {
                                "loc": {
                                  "line": 2,
                                  "col": 16
                                },
                                "kind": {
                                  "numberLit": "1"
                                }
                              }
                            }
                          }
                        },
                        "rhs": {
                          "literal": {
                            "loc": {
                              "line": 2,
                              "col": 21
                            },
                            "kind": {
                              "numberLit": "2"
                            }
                          }
                        }
                      }
                    },
                    "message": null
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