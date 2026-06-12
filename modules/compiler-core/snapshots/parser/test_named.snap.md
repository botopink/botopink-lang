```json
{
  "decls": [
    {
      "test": {
        "name": "addition works",
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
              "binding": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "r",
                    "value": {
                      "binaryOp": {
                        "loc": {
                          "line": 2,
                          "col": 15
                        },
                        "op": "add",
                        "lhs": {
                          "literal": {
                            "loc": {
                              "line": 2,
                              "col": 13
                            },
                            "kind": {
                              "numberLit": "2"
                            }
                          }
                        },
                        "rhs": {
                          "literal": {
                            "loc": {
                              "line": 2,
                              "col": 17
                            },
                            "kind": {
                              "numberLit": "3"
                            }
                          }
                        }
                      }
                    },
                    "mutable": false,
                    "typeAnnotation": null
                  }
                }
              }
            },
            "emptyLinesBefore": 0
          },
          {
            "expr": {
              "comptime_": {
                "loc": {
                  "line": 3,
                  "col": 5
                },
                "kind": {
                  "assert": {
                    "condition": {
                      "binaryOp": {
                        "loc": {
                          "line": 3,
                          "col": 14
                        },
                        "op": "eq",
                        "lhs": {
                          "identifier": {
                            "loc": {
                              "line": 3,
                              "col": 12
                            },
                            "kind": {
                              "ident": "r"
                            }
                          }
                        },
                        "rhs": {
                          "literal": {
                            "loc": {
                              "line": 3,
                              "col": 17
                            },
                            "kind": {
                              "numberLit": "5"
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