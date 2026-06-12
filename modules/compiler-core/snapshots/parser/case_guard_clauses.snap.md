```json
{
  "decls": [
    {
      "implement": {
        "name": "X",
        "isPub": false,
        "shorthand": false,
        "genericParams": [],
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "interfaces": [
          {
            "named": "Foo"
          }
        ],
        "target": "Bar",
        "methods": [
          {
            "qualifier": null,
            "name": "run",
            "params": [
              {
                "name": "self",
                "typeRef": {
                  "named": "Self"
                },
                "typeName": "",
                "modifier": "none",
                "fnType": null,
                "destruct": null,
                "defaultVal": null
              }
            ],
            "body": [
              {
                "expr": {
                  "collection": {
                    "loc": {
                      "line": 3,
                      "col": 9
                    },
                    "kind": {
                      "case": {
                        "subjects": [
                          {
                            "identifier": {
                              "loc": {
                                "line": 3,
                                "col": 14
                              },
                              "kind": {
                                "ident": "n"
                              }
                            }
                          }
                        ],
                        "arms": [
                          {
                            "pattern": {
                              "ident": "x"
                            },
                            "body": {
                              "literal": {
                                "loc": {
                                  "line": 4,
                                  "col": 27
                                },
                                "kind": {
                                  "stringLit": "positive"
                                }
                              }
                            },
                            "guard": {
                              "binaryOp": {
                                "loc": {
                                  "line": 4,
                                  "col": 20
                                },
                                "op": "gt",
                                "lhs": {
                                  "identifier": {
                                    "loc": {
                                      "line": 4,
                                      "col": 18
                                    },
                                    "kind": {
                                      "ident": "x"
                                    }
                                  }
                                },
                                "rhs": {
                                  "literal": {
                                    "loc": {
                                      "line": 4,
                                      "col": 22
                                    },
                                    "kind": {
                                      "numberLit": "0"
                                    }
                                  }
                                }
                              }
                            },
                            "emptyLinesBefore": 0
                          },
                          {
                            "pattern": {
                              "numberLit": "0"
                            },
                            "body": {
                              "literal": {
                                "loc": {
                                  "line": 5,
                                  "col": 18
                                },
                                "kind": {
                                  "stringLit": "zero"
                                }
                              }
                            },
                            "guard": null,
                            "emptyLinesBefore": 0
                          },
                          {
                            "pattern": {
                              "wildcard": {}
                            },
                            "body": {
                              "literal": {
                                "loc": {
                                  "line": 6,
                                  "col": 18
                                },
                                "kind": {
                                  "stringLit": "negative"
                                }
                              }
                            },
                            "guard": null,
                            "emptyLinesBefore": 0
                          }
                        ],
                        "trailingComments": []
                      }
                    }
                  }
                },
                "emptyLinesBefore": 0
              }
            ]
          }
        ]
      }
    }
  ]
}
```