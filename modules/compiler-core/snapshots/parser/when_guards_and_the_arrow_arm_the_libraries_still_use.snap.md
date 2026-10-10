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
        "name": "sign",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "x",
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
                                  "ident": "x"
                                }
                              }
                            }
                          ],
                          "arms": [
                            {
                              "pattern": {
                                "ident": "i32"
                              },
                              "body": {
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
                                          "literal": {
                                            "loc": {
                                              "line": 3,
                                              "col": 28
                                            },
                                            "kind": {
                                              "stringLit": "positive"
                                            }
                                          }
                                        },
                                        "emptyLinesBefore": 0
                                      }
                                    ]
                                  }
                                }
                              },
                              "guard": {
                                "binaryOp": {
                                  "loc": {
                                    "line": 3,
                                    "col": 21
                                  },
                                  "op": "gt",
                                  "lhs": {
                                    "identifier": {
                                      "loc": {
                                        "line": 3,
                                        "col": 19
                                      },
                                      "kind": {
                                        "ident": "x"
                                      }
                                    }
                                  },
                                  "rhs": {
                                    "literal": {
                                      "loc": {
                                        "line": 3,
                                        "col": 23
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
                                "wildcard": {}
                              },
                              "body": {
                                "function": {
                                  "loc": {
                                    "line": 4,
                                    "col": 27
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
                                              "line": 4,
                                              "col": 32
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
                              "guard": {
                                "binaryOp": {
                                  "loc": {
                                    "line": 4,
                                    "col": 19
                                  },
                                  "op": "eq",
                                  "lhs": {
                                    "identifier": {
                                      "loc": {
                                        "line": 4,
                                        "col": 17
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
                                "wildcard": {}
                              },
                              "body": {
                                "function": {
                                  "loc": {
                                    "line": 5,
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
                                              "line": 5,
                                              "col": 13
                                            },
                                            "kind": {
                                              "stringLit": "negative"
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
    },
    {
      "fn": {
        "isPub": false,
        "effect": null,
        "isDeclare": false,
        "isDefault": false,
        "label": null,
        "name": "legacy",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "o",
            "typeRef": {
              "named": "Order"
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": null
          }
        ],
        "returnType": {
          "named": "i32"
        },
        "typeGuardParam": null,
        "body": [
          {
            "expr": {
              "jump": {
                "loc": {
                  "line": 9,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "collection": {
                      "loc": {
                        "line": 9,
                        "col": 12
                      },
                      "kind": {
                        "case": {
                          "subjects": [
                            {
                              "identifier": {
                                "loc": {
                                  "line": 9,
                                  "col": 17
                                },
                                "kind": {
                                  "ident": "o"
                                }
                              }
                            }
                          ],
                          "arms": [
                            {
                              "pattern": {
                                "ident": "Lt"
                              },
                              "body": {
                                "unaryOp": {
                                  "loc": {
                                    "line": 10,
                                    "col": 15
                                  },
                                  "op": "neg",
                                  "expr": {
                                    "literal": {
                                      "loc": {
                                        "line": 10,
                                        "col": 16
                                      },
                                      "kind": {
                                        "numberLit": "1"
                                      }
                                    }
                                  }
                                }
                              },
                              "guard": null,
                              "emptyLinesBefore": 0
                            },
                            {
                              "pattern": {
                                "ident": "x"
                              },
                              "body": {
                                "literal": {
                                  "loc": {
                                    "line": 11,
                                    "col": 23
                                  },
                                  "kind": {
                                    "numberLit": "1"
                                  }
                                }
                              },
                              "guard": {
                                "binaryOp": {
                                  "loc": {
                                    "line": 11,
                                    "col": 16
                                  },
                                  "op": "gt",
                                  "lhs": {
                                    "identifier": {
                                      "loc": {
                                        "line": 11,
                                        "col": 14
                                      },
                                      "kind": {
                                        "ident": "x"
                                      }
                                    }
                                  },
                                  "rhs": {
                                    "literal": {
                                      "loc": {
                                        "line": 11,
                                        "col": 18
                                      },
                                      "kind": {
                                        "numberLit": "3"
                                      }
                                    }
                                  }
                                }
                              },
                              "emptyLinesBefore": 0
                            },
                            {
                              "pattern": {
                                "wildcard": {}
                              },
                              "body": {
                                "literal": {
                                  "loc": {
                                    "line": 12,
                                    "col": 14
                                  },
                                  "kind": {
                                    "numberLit": "0"
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