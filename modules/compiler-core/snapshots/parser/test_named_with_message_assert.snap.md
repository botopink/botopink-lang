```json
{
  "decls": [
    {
      "test": {
        "name": "map doubles",
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
                          "col": 22
                        },
                        "op": "eq",
                        "lhs": {
                          "collection": {
                            "loc": {
                              "line": 2,
                              "col": 12
                            },
                            "kind": {
                              "arrayLit": {
                                "elems": [
                                  {
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
                                  {
                                    "literal": {
                                      "loc": {
                                        "line": 2,
                                        "col": 16
                                      },
                                      "kind": {
                                        "numberLit": "4"
                                      }
                                    }
                                  },
                                  {
                                    "literal": {
                                      "loc": {
                                        "line": 2,
                                        "col": 19
                                      },
                                      "kind": {
                                        "numberLit": "6"
                                      }
                                    }
                                  }
                                ],
                                "spread": null,
                                "spreadExpr": null,
                                "comments": [],
                                "commentsPerElem": [],
                                "trailingComma": false
                              }
                            }
                          }
                        },
                        "rhs": {
                          "collection": {
                            "loc": {
                              "line": 2,
                              "col": 25
                            },
                            "kind": {
                              "arrayLit": {
                                "elems": [
                                  {
                                    "literal": {
                                      "loc": {
                                        "line": 2,
                                        "col": 26
                                      },
                                      "kind": {
                                        "numberLit": "2"
                                      }
                                    }
                                  },
                                  {
                                    "literal": {
                                      "loc": {
                                        "line": 2,
                                        "col": 29
                                      },
                                      "kind": {
                                        "numberLit": "4"
                                      }
                                    }
                                  },
                                  {
                                    "literal": {
                                      "loc": {
                                        "line": 2,
                                        "col": 32
                                      },
                                      "kind": {
                                        "numberLit": "6"
                                      }
                                    }
                                  }
                                ],
                                "spread": null,
                                "spreadExpr": null,
                                "comments": [],
                                "commentsPerElem": [],
                                "trailingComma": false
                              }
                            }
                          }
                        }
                      }
                    },
                    "message": {
                      "literal": {
                        "loc": {
                          "line": 2,
                          "col": 36
                        },
                        "kind": {
                          "stringLit": "map should double each element"
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