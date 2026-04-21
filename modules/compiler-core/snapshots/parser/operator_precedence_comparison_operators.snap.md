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
                "emptyLinesBefore": 0
              },
              {
                "expr": {
                  "binaryOp": {
                    "loc": {
                      "line": 4,
                      "col": 11
                    },
                    "kind": {
                      "gt": {
                        "lhs": {
                          "identifier": {
                            "loc": {
                              "line": 4,
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
                              "line": 4,
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
                "emptyLinesBefore": 0
              },
              {
                "expr": {
                  "binaryOp": {
                    "loc": {
                      "line": 5,
                      "col": 11
                    },
                    "kind": {
                      "lte": {
                        "lhs": {
                          "identifier": {
                            "loc": {
                              "line": 5,
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
                              "line": 5,
                              "col": 14
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
                "emptyLinesBefore": 0
              },
              {
                "expr": {
                  "binaryOp": {
                    "loc": {
                      "line": 6,
                      "col": 11
                    },
                    "kind": {
                      "gte": {
                        "lhs": {
                          "identifier": {
                            "loc": {
                              "line": 6,
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
                              "line": 6,
                              "col": 14
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