```json
{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "name": "Dashboard",
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
              "useHook": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "useBindDestruct": {
                    "pattern": {
                      "names": {
                        "fields": [
                          {
                            "field_name": "count",
                            "bind_name": "count"
                          },
                          {
                            "field_name": "setCount",
                            "bind_name": "setCount"
                          }
                        ],
                        "hasSpread": false
                      }
                    },
                    "value": {
                      "call": {
                        "loc": {
                          "line": 2,
                          "col": 29
                        },
                        "kind": {
                          "call": {
                            "receiver": null,
                            "callee": "state",
                            "is_builtin": false,
                            "args": [
                              {
                                "label": null,
                                "value": {
                                  "literal": {
                                    "loc": {
                                      "line": 2,
                                      "col": 35
                                    },
                                    "kind": {
                                      "numberLit": "0"
                                    }
                                  }
                                },
                                "comments": []
                              }
                            ],
                            "trailing": []
                          }
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
              "useHook": {
                "loc": {
                  "line": 3,
                  "col": 5
                },
                "kind": {
                  "useBind": {
                    "name": "doubled",
                    "value": {
                      "call": {
                        "loc": {
                          "line": 3,
                          "col": 19
                        },
                        "kind": {
                          "call": {
                            "receiver": null,
                            "callee": "memo",
                            "is_builtin": false,
                            "args": [
                              {
                                "label": null,
                                "value": {
                                  "function": {
                                    "loc": {
                                      "line": 3,
                                      "col": 24
                                    },
                                    "kind": {
                                      "lambda": {
                                        "params": [],
                                        "body": [
                                          {
                                            "expr": {
                                              "binaryOp": {
                                                "loc": {
                                                  "line": 3,
                                                  "col": 35
                                                },
                                                "kind": {
                                                  "op": "mul",
                                                  "lhs": {
                                                    "identifier": {
                                                      "loc": {
                                                        "line": 3,
                                                        "col": 29
                                                      },
                                                      "kind": {
                                                        "ident": "count"
                                                      }
                                                    }
                                                  },
                                                  "rhs": {
                                                    "literal": {
                                                      "loc": {
                                                        "line": 3,
                                                        "col": 37
                                                      },
                                                      "kind": {
                                                        "numberLit": "2"
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
                                  }
                                },
                                "comments": []
                              }
                            ],
                            "trailing": []
                          }
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
              "useHook": {
                "loc": {
                  "line": 4,
                  "col": 5
                },
                "kind": {
                  "useBind": {
                    "name": "_",
                    "value": {
                      "call": {
                        "loc": {
                          "line": 4,
                          "col": 13
                        },
                        "kind": {
                          "call": {
                            "receiver": null,
                            "callee": "effect",
                            "is_builtin": false,
                            "args": [
                              {
                                "label": null,
                                "value": {
                                  "function": {
                                    "loc": {
                                      "line": 4,
                                      "col": 20
                                    },
                                    "kind": {
                                      "lambda": {
                                        "params": [],
                                        "body": [
                                          {
                                            "expr": {
                                              "call": {
                                                "loc": {
                                                  "line": 4,
                                                  "col": 25
                                                },
                                                "kind": {
                                                  "call": {
                                                    "receiver": null,
                                                    "callee": "cleanup",
                                                    "is_builtin": false,
                                                    "args": [],
                                                    "trailing": []
                                                  }
                                                }
                                              }
                                            },
                                            "emptyLinesBefore": 0
                                          }
                                        ]
                                      }
                                    }
                                  }
                                },
                                "comments": []
                              }
                            ],
                            "trailing": []
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