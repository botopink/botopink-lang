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
              "binding": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "localBindDestruct": {
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
                      "useHook": {
                        "loc": {
                          "line": 2,
                          "col": 29
                        },
                        "kind": {
                          "inner": {
                            "call": {
                              "loc": {
                                "line": 2,
                                "col": 33
                              },
                              "kind": {
                                "call": {
                                  "receiver": null,
                                  "callee": "state",
                                  "is_builtin": false,
                                  "is_tagged": false,
                                  "optional": false,
                                  "args": [
                                    {
                                      "label": null,
                                      "value": {
                                        "literal": {
                                          "loc": {
                                            "line": 2,
                                            "col": 39
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
                    },
                    "mutable": false
                  }
                }
              }
            },
            "emptyLinesBefore": 0
          },
          {
            "expr": {
              "binding": {
                "loc": {
                  "line": 3,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "doubled",
                    "value": {
                      "useHook": {
                        "loc": {
                          "line": 3,
                          "col": 19
                        },
                        "kind": {
                          "inner": {
                            "call": {
                              "loc": {
                                "line": 3,
                                "col": 23
                              },
                              "kind": {
                                "call": {
                                  "receiver": null,
                                  "callee": "memo",
                                  "is_builtin": false,
                                  "is_tagged": false,
                                  "optional": false,
                                  "args": [
                                    {
                                      "label": null,
                                      "value": {
                                        "function": {
                                          "loc": {
                                            "line": 3,
                                            "col": 28
                                          },
                                          "kind": {
                                            "syntax": "lambda",
                                            "params": [],
                                            "body": [
                                              {
                                                "expr": {
                                                  "binaryOp": {
                                                    "loc": {
                                                      "line": 3,
                                                      "col": 39
                                                    },
                                                    "op": "mul",
                                                    "lhs": {
                                                      "identifier": {
                                                        "loc": {
                                                          "line": 3,
                                                          "col": 33
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
                                                          "col": 41
                                                        },
                                                        "kind": {
                                                          "numberLit": "2"
                                                        }
                                                      }
                                                    }
                                                  }
                                                },
                                                "emptyLinesBefore": 0
                                              }
                                            ],
                                            "isStarFn": false
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
              "useHook": {
                "loc": {
                  "line": 4,
                  "col": 5
                },
                "kind": {
                  "inner": {
                    "call": {
                      "loc": {
                        "line": 4,
                        "col": 9
                      },
                      "kind": {
                        "call": {
                          "receiver": null,
                          "callee": "effect",
                          "is_builtin": false,
                          "is_tagged": false,
                          "optional": false,
                          "args": [
                            {
                              "label": null,
                              "value": {
                                "function": {
                                  "loc": {
                                    "line": 4,
                                    "col": 16
                                  },
                                  "kind": {
                                    "syntax": "lambda",
                                    "params": [],
                                    "body": [
                                      {
                                        "expr": {
                                          "call": {
                                            "loc": {
                                              "line": 4,
                                              "col": 21
                                            },
                                            "kind": {
                                              "call": {
                                                "receiver": null,
                                                "callee": "cleanup",
                                                "is_builtin": false,
                                                "is_tagged": false,
                                                "optional": false,
                                                "args": [],
                                                "trailing": []
                                              }
                                            }
                                          }
                                        },
                                        "emptyLinesBefore": 0
                                      }
                                    ],
                                    "isStarFn": false
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
            },
            "emptyLinesBefore": 0
          }
        ]
      }
    }
  ]
}
```