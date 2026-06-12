```json
{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "effect": null,
        "isDeclare": false,
        "isDefault": false,
        "label": null,
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
                          "col": 22
                        },
                        "op": "eq",
                        "lhs": {
                          "binaryOp": {
                            "loc": {
                              "line": 2,
                              "col": 16
                            },
                            "op": "add",
                            "lhs": {
                              "literal": {
                                "loc": {
                                  "line": 2,
                                  "col": 12
                                },
                                "kind": {
                                  "numberLit": "1.0"
                                }
                              }
                            },
                            "rhs": {
                              "literal": {
                                "loc": {
                                  "line": 2,
                                  "col": 18
                                },
                                "kind": {
                                  "numberLit": "2.0"
                                }
                              }
                            }
                          }
                        },
                        "rhs": {
                          "literal": {
                            "loc": {
                              "line": 2,
                              "col": 25
                            },
                            "kind": {
                              "numberLit": "3.0"
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