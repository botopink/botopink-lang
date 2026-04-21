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
                      "sub": {
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
                              "col": 27
                            },
                            "kind": {
                              "mod": {
                                "lhs": {
                                  "binaryOp": {
                                    "loc": {
                                      "line": 3,
                                      "col": 23
                                    },
                                    "kind": {
                                      "div": {
                                        "lhs": {
                                          "binaryOp": {
                                            "loc": {
                                              "line": 3,
                                              "col": 19
                                            },
                                            "kind": {
                                              "mul": {
                                                "lhs": {
                                                  "identifier": {
                                                    "loc": {
                                                      "line": 3,
                                                      "col": 17
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
                                                      "col": 21
                                                    },
                                                    "kind": {
                                                      "ident": "d"
                                                    }
                                                  }
                                                }
                                              }
                                            }
                                          }
                                        },
                                        "rhs": {
                                          "identifier": {
                                            "loc": {
                                              "line": 3,
                                              "col": 25
                                            },
                                            "kind": {
                                              "ident": "e"
                                            }
                                          }
                                        }
                                      }
                                    }
                                  }
                                },
                                "rhs": {
                                  "identifier": {
                                    "loc": {
                                      "line": 3,
                                      "col": 29
                                    },
                                    "kind": {
                                      "ident": "f"
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