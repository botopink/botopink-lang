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
                      "lt": {
                        "lhs": {
                          "binaryOp": {
                            "loc": {
                              "line": 3,
                              "col": 11
                            },
                            "kind": {
                              "add": {
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
                                  "literal": {
                                    "loc": {
                                      "line": 3,
                                      "col": 13
                                    },
                                    "kind": {
                                      "numberLit": "1"
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
                              "col": 19
                            },
                            "kind": {
                              "add": {
                                "lhs": {
                                  "identifier": {
                                    "loc": {
                                      "line": 3,
                                      "col": 17
                                    },
                                    "kind": {
                                      "ident": "b"
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
                                      "numberLit": "2"
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