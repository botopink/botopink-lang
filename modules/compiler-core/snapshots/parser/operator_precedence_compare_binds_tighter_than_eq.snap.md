```json
{
  "decls": [
    {
      "interface": {
        "name": "Test",
        "id": 1,
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "extends": [],
        "fields": [],
        "trailingComma": false,
        "methods": [
          {
            "name": "run",
            "genericParams": [],
            "params": [],
            "returnType": null,
            "body": [
              {
                "expr": {
                  "binaryOp": {
                    "loc": {
                      "line": 3,
                      "col": 15
                    },
                    "kind": {
                      "eq": {
                        "lhs": {
                          "binaryOp": {
                            "loc": {
                              "line": 3,
                              "col": 11
                            },
                            "kind": {
                              "lt": {
                                "lhs": {
                                  "identifier": {
                                    "loc": {
                                      "line": 3,
                                      "col": 9
                                    },
                                    "kind": {
                                      "ident": "a"
                                    }
                                  }
                                },
                                "rhs": {
                                  "identifier": {
                                    "loc": {
                                      "line": 3,
                                      "col": 13
                                    },
                                    "kind": {
                                      "ident": "b"
                                    }
                                  }
                                }
                              }
                            }
                          }
                        },
                        "rhs": {
                          "binaryOp": {
                            "loc": {
                              "line": 3,
                              "col": 20
                            },
                            "kind": {
                              "gt": {
                                "lhs": {
                                  "identifier": {
                                    "loc": {
                                      "line": 3,
                                      "col": 18
                                    },
                                    "kind": {
                                      "ident": "c"
                                    }
                                  }
                                },
                                "rhs": {
                                  "identifier": {
                                    "loc": {
                                      "line": 3,
                                      "col": 22
                                    },
                                    "kind": {
                                      "ident": "d"
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
            ],
            "is_default": true,
            "is_declare": false,
            "isPub": false
          }
        ]
      }
    }
  ]
}
```