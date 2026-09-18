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
        "name": "adder",
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
          "function": {
            "params": [
              {
                "named": "i32"
              }
            ],
            "returnType": {
              "named": "i32"
            }
          }
        },
        "typeGuardParam": null,
        "body": [
          {
            "expr": {
              "jump": {
                "loc": {
                  "line": 1,
                  "col": 41
                },
                "kind": {
                  "return": {
                    "function": {
                      "loc": {
                        "line": 1,
                        "col": 48
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
                                  "line": 1,
                                  "col": 57
                                },
                                "op": "add",
                                "lhs": {
                                  "identifier": {
                                    "loc": {
                                      "line": 1,
                                      "col": 55
                                    },
                                    "kind": {
                                      "ident": "x"
                                    }
                                  }
                                },
                                "rhs": {
                                  "identifier": {
                                    "loc": {
                                      "line": 1,
                                      "col": 59
                                    },
                                    "kind": {
                                      "ident": "n"
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
              "binding": {
                "loc": {
                  "line": 3,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "a",
                    "value": {
                      "call": {
                        "loc": {
                          "line": 3,
                          "col": 21
                        },
                        "kind": {
                          "call": {
                            "receiver": null,
                            "callee": "",
                            "is_builtin": false,
                            "is_tagged": false,
                            "optional": false,
                            "args": [
                              {
                                "label": null,
                                "value": {
                                  "literal": {
                                    "loc": {
                                      "line": 3,
                                      "col": 22
                                    },
                                    "kind": {
                                      "numberLit": "4"
                                    }
                                  }
                                },
                                "comments": [],
                                "is_default_inj": false
                              }
                            ],
                            "trailing": [],
                            "calleeExpr": {
                              "call": {
                                "loc": {
                                  "line": 3,
                                  "col": 13
                                },
                                "kind": {
                                  "call": {
                                    "receiver": null,
                                    "callee": "adder",
                                    "is_builtin": false,
                                    "is_tagged": false,
                                    "optional": false,
                                    "args": [
                                      {
                                        "label": null,
                                        "value": {
                                          "literal": {
                                            "loc": {
                                              "line": 3,
                                              "col": 19
                                            },
                                            "kind": {
                                              "numberLit": "3"
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
                  "line": 4,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "b",
                    "value": {
                      "call": {
                        "loc": {
                          "line": 4,
                          "col": 24
                        },
                        "kind": {
                          "call": {
                            "receiver": null,
                            "callee": "",
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
                                      "col": 25
                                    },
                                    "kind": {
                                      "numberLit": "5"
                                    }
                                  }
                                },
                                "comments": [],
                                "is_default_inj": false
                              }
                            ],
                            "trailing": [],
                            "calleeExpr": {
                              "call": {
                                "loc": {
                                  "line": 4,
                                  "col": 21
                                },
                                "kind": {
                                  "call": {
                                    "receiver": null,
                                    "callee": "",
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
                                              "col": 22
                                            },
                                            "kind": {
                                              "numberLit": "4"
                                            }
                                          }
                                        },
                                        "comments": [],
                                        "is_default_inj": false
                                      }
                                    ],
                                    "trailing": [],
                                    "calleeExpr": {
                                      "call": {
                                        "loc": {
                                          "line": 4,
                                          "col": 13
                                        },
                                        "kind": {
                                          "call": {
                                            "receiver": null,
                                            "callee": "adder",
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
                                                      "col": 19
                                                    },
                                                    "kind": {
                                                      "numberLit": "3"
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
              "jump": {
                "loc": {
                  "line": 5,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "binaryOp": {
                      "loc": {
                        "line": 5,
                        "col": 14
                      },
                      "op": "add",
                      "lhs": {
                        "identifier": {
                          "loc": {
                            "line": 5,
                            "col": 12
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
                            "col": 16
                          },
                          "kind": {
                            "ident": "b"
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