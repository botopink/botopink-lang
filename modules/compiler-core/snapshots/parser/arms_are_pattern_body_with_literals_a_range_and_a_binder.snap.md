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
        "name": "describe",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "n",
            "typeRef": {
              "named": "i32"
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": null
          }
        ],
        "returnType": {
          "named": "string"
        },
        "typeGuardParam": null,
        "body": [
          {
            "expr": {
              "jump": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "collection": {
                      "loc": {
                        "line": 2,
                        "col": 12
                      },
                      "kind": {
                        "case": {
                          "subjects": [
                            {
                              "identifier": {
                                "loc": {
                                  "line": 2,
                                  "col": 17
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
                                "numberLit": "0"
                              },
                              "body": {
                                "function": {
                                  "loc": {
                                    "line": 3,
                                    "col": 13
                                  },
                                  "kind": {
                                    "syntax": "lambda",
                                    "params": [],
                                    "body": [
                                      {
                                        "expr": {
                                          "literal": {
                                            "loc": {
                                              "line": 3,
                                              "col": 13
                                            },
                                            "kind": {
                                              "stringLit": "zero"
                                            }
                                          }
                                        },
                                        "emptyLinesBefore": 0
                                      }
                                    ]
                                  }
                                }
                              },
                              "guard": null,
                              "emptyLinesBefore": 0
                            },
                            {
                              "pattern": {
                                "variant": {
                                  "name": "",
                                  "payload": {
                                    "literals": [
                                      {
                                        "numberLit": "1"
                                      },
                                      {
                                        "numberLit": "9"
                                      }
                                    ]
                                  },
                                  "shape": "range",
                                  "labels": [],
                                  "rest": false
                                }
                              },
                              "body": {
                                "function": {
                                  "loc": {
                                    "line": 4,
                                    "col": 17
                                  },
                                  "kind": {
                                    "syntax": "lambda",
                                    "params": [],
                                    "body": [
                                      {
                                        "expr": {
                                          "literal": {
                                            "loc": {
                                              "line": 4,
                                              "col": 17
                                            },
                                            "kind": {
                                              "stringLit": "digit"
                                            }
                                          }
                                        },
                                        "emptyLinesBefore": 0
                                      }
                                    ]
                                  }
                                }
                              },
                              "guard": null,
                              "emptyLinesBefore": 0
                            },
                            {
                              "pattern": {
                                "ident": "i32"
                              },
                              "body": {
                                "function": {
                                  "loc": {
                                    "line": 5,
                                    "col": 15
                                  },
                                  "kind": {
                                    "syntax": "lambda",
                                    "params": [
                                      "m"
                                    ],
                                    "body": [
                                      {
                                        "expr": {
                                          "binding": {
                                            "loc": {
                                              "line": 6,
                                              "col": 13
                                            },
                                            "kind": {
                                              "localBind": {
                                                "name": "d",
                                                "value": {
                                                  "binaryOp": {
                                                    "loc": {
                                                      "line": 6,
                                                      "col": 23
                                                    },
                                                    "op": "mul",
                                                    "lhs": {
                                                      "identifier": {
                                                        "loc": {
                                                          "line": 6,
                                                          "col": 21
                                                        },
                                                        "kind": {
                                                          "ident": "m"
                                                        }
                                                      }
                                                    },
                                                    "rhs": {
                                                      "literal": {
                                                        "loc": {
                                                          "line": 6,
                                                          "col": 25
                                                        },
                                                        "kind": {
                                                          "numberLit": "2"
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
                                          "binaryOp": {
                                            "loc": {
                                              "line": 7,
                                              "col": 15
                                            },
                                            "op": "add",
                                            "lhs": {
                                              "identifier": {
                                                "loc": {
                                                  "line": 7,
                                                  "col": 13
                                                },
                                                "kind": {
                                                  "ident": "d"
                                                }
                                              }
                                            },
                                            "rhs": {
                                              "literal": {
                                                "loc": {
                                                  "line": 7,
                                                  "col": 17
                                                },
                                                "kind": {
                                                  "numberLit": "1"
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
                              },
                              "guard": null,
                              "emptyLinesBefore": 0
                            },
                            {
                              "pattern": {
                                "wildcard": {}
                              },
                              "body": {
                                "function": {
                                  "loc": {
                                    "line": 9,
                                    "col": 13
                                  },
                                  "kind": {
                                    "syntax": "lambda",
                                    "params": [
                                      "v"
                                    ],
                                    "body": [
                                      {
                                        "expr": {
                                          "literal": {
                                            "loc": {
                                              "line": 9,
                                              "col": 18
                                            },
                                            "kind": {
                                              "stringLit": "big"
                                            }
                                          }
                                        },
                                        "emptyLinesBefore": 0
                                      }
                                    ]
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