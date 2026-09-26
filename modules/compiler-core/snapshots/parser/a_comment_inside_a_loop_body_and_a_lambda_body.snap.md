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
        "name": "f",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [],
        "returnType": {
          "named": "i32"
        },
        "typeGuardParam": null,
        "body": [
          {
            "expr": {
              "loop": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "keyword": "for_",
                "generator": null,
                "iter": {
                  "collection": {
                    "loc": {
                      "line": 2,
                      "col": 10
                    },
                    "kind": {
                      "arrayLit": {
                        "elems": [
                          {
                            "literal": {
                              "loc": {
                                "line": 2,
                                "col": 11
                              },
                              "kind": {
                                "numberLit": "1"
                              }
                            }
                          },
                          {
                            "literal": {
                              "loc": {
                                "line": 2,
                                "col": 14
                              },
                              "kind": {
                                "numberLit": "2"
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
                "indexRange": null,
                "params": [
                  "x"
                ],
                "paramsLoc": {
                  "line": 2,
                  "col": 20
                },
                "condition": false,
                "body": [
                  {
                    "expr": {
                      "literal": {
                        "loc": {
                          "line": 3,
                          "col": 9
                        },
                        "kind": {
                          "comment": {
                            "kind": {
                              "normal": ""
                            },
                            "text": "a loop body is not a lambda body — it has its own block"
                          }
                        }
                      }
                    },
                    "emptyLinesBefore": 0
                  },
                  {
                    "expr": {
                      "call": {
                        "loc": {
                          "line": 4,
                          "col": 9
                        },
                        "kind": {
                          "call": {
                            "receiver": null,
                            "callee": "println",
                            "is_builtin": false,
                            "is_tagged": false,
                            "optional": false,
                            "args": [
                              {
                                "label": null,
                                "value": {
                                  "literal": {
                                    "loc": {
                                      "line": 4,
                                      "col": 17
                                    },
                                    "kind": {
                                      "stringLit": "a"
                                    }
                                  }
                                },
                                "comments": [],
                                "is_default_inj": false
                              }
                            ],
                            "trailing": []
                          }
                        }
                      }
                    },
                    "emptyLinesBefore": 0
                  },
                  {
                    "expr": {
                      "call": {
                        "loc": {
                          "line": 6,
                          "col": 9
                        },
                        "kind": {
                          "call": {
                            "receiver": null,
                            "callee": "println",
                            "is_builtin": false,
                            "is_tagged": false,
                            "optional": false,
                            "args": [
                              {
                                "label": null,
                                "value": {
                                  "literal": {
                                    "loc": {
                                      "line": 6,
                                      "col": 17
                                    },
                                    "kind": {
                                      "stringLit": "b"
                                    }
                                  }
                                },
                                "comments": [],
                                "is_default_inj": false
                              }
                            ],
                            "trailing": []
                          }
                        }
                      }
                    },
                    "emptyLinesBefore": 1
                  }
                ],
                "awaitLoop": false,
                "label": null
              }
            },
            "emptyLinesBefore": 0
          },
          {
            "expr": {
              "binding": {
                "loc": {
                  "line": 8,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "g",
                    "value": {
                      "function": {
                        "loc": {
                          "line": 8,
                          "col": 13
                        },
                        "kind": {
                          "syntax": "lambda",
                          "params": [
                            "x"
                          ],
                          "body": [
                            {
                              "expr": {
                                "literal": {
                                  "loc": {
                                    "line": 9,
                                    "col": 9
                                  },
                                  "kind": {
                                    "comment": {
                                      "kind": {
                                        "normal": ""
                                      },
                                      "text": "a standalone lambda"
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
                                    "line": 10,
                                    "col": 11
                                  },
                                  "op": "add",
                                  "lhs": {
                                    "identifier": {
                                      "loc": {
                                        "line": 10,
                                        "col": 9
                                      },
                                      "kind": {
                                        "ident": "x"
                                      }
                                    }
                                  },
                                  "rhs": {
                                    "literal": {
                                      "loc": {
                                        "line": 10,
                                        "col": 13
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
              "jump": {
                "loc": {
                  "line": 12,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "call": {
                      "loc": {
                        "line": 12,
                        "col": 12
                      },
                      "kind": {
                        "call": {
                          "receiver": null,
                          "callee": "g",
                          "is_builtin": false,
                          "is_tagged": false,
                          "optional": false,
                          "args": [
                            {
                              "label": null,
                              "value": {
                                "literal": {
                                  "loc": {
                                    "line": 12,
                                    "col": 14
                                  },
                                  "kind": {
                                    "numberLit": "1"
                                  }
                                }
                              },
                              "comments": [],
                              "is_default_inj": false
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