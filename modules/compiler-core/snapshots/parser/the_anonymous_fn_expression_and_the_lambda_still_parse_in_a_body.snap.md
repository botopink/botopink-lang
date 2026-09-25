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
        "name": "main",
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
              "binding": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "inner",
                    "value": {
                      "function": {
                        "loc": {
                          "line": 2,
                          "col": 17
                        },
                        "kind": {
                          "syntax": "fnExpr",
                          "params": [
                            "x"
                          ],
                          "body": [
                            {
                              "expr": {
                                "jump": {
                                  "loc": {
                                    "line": 2,
                                    "col": 25
                                  },
                                  "kind": {
                                    "return": {
                                      "binaryOp": {
                                        "loc": {
                                          "line": 2,
                                          "col": 34
                                        },
                                        "op": "add",
                                        "lhs": {
                                          "identifier": {
                                            "loc": {
                                              "line": 2,
                                              "col": 32
                                            },
                                            "kind": {
                                              "ident": "x"
                                            }
                                          }
                                        },
                                        "rhs": {
                                          "literal": {
                                            "loc": {
                                              "line": 2,
                                              "col": 36
                                            },
                                            "kind": {
                                              "numberLit": "1"
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
              "binding": {
                "loc": {
                  "line": 3,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "twice",
                    "value": {
                      "function": {
                        "loc": {
                          "line": 3,
                          "col": 17
                        },
                        "kind": {
                          "syntax": "lambda",
                          "params": [
                            "x"
                          ],
                          "body": [
                            {
                              "expr": {
                                "binaryOp": {
                                  "loc": {
                                    "line": 3,
                                    "col": 26
                                  },
                                  "op": "mul",
                                  "lhs": {
                                    "identifier": {
                                      "loc": {
                                        "line": 3,
                                        "col": 24
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
                                        "col": 28
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
                  "line": 4,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "call": {
                      "loc": {
                        "line": 4,
                        "col": 12
                      },
                      "kind": {
                        "call": {
                          "receiver": null,
                          "callee": "inner",
                          "is_builtin": false,
                          "is_tagged": false,
                          "optional": false,
                          "args": [
                            {
                              "label": null,
                              "value": {
                                "call": {
                                  "loc": {
                                    "line": 4,
                                    "col": 18
                                  },
                                  "kind": {
                                    "call": {
                                      "receiver": null,
                                      "callee": "twice",
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
                                                "col": 24
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