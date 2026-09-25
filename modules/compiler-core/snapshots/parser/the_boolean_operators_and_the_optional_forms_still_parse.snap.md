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
        "params": [
          {
            "name": "a",
            "typeRef": {
              "named": "bool"
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": null
          },
          {
            "name": "b",
            "typeRef": {
              "named": "bool"
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": null
          },
          {
            "name": "c",
            "typeRef": {
              "optional": {
                "named": "i32"
              }
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": null
          },
          {
            "name": "d",
            "typeRef": {
              "generic": {
                "name": "Box",
                "args": [
                  {
                    "generic": {
                      "name": "Box",
                      "args": [
                        {
                          "named": "i32"
                        }
                      ],
                      "is_builtin": false
                    }
                  }
                ],
                "is_builtin": false
              }
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": null
          }
        ],
        "returnType": {
          "named": "bool"
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
                    "name": "x",
                    "value": {
                      "binaryOp": {
                        "loc": {
                          "line": 2,
                          "col": 20
                        },
                        "op": "or",
                        "lhs": {
                          "binaryOp": {
                            "loc": {
                              "line": 2,
                              "col": 15
                            },
                            "op": "and",
                            "lhs": {
                              "identifier": {
                                "loc": {
                                  "line": 2,
                                  "col": 13
                                },
                                "kind": {
                                  "ident": "a"
                                }
                              }
                            },
                            "rhs": {
                              "identifier": {
                                "loc": {
                                  "line": 2,
                                  "col": 18
                                },
                                "kind": {
                                  "ident": "b"
                                }
                              }
                            }
                          }
                        },
                        "rhs": {
                          "unaryOp": {
                            "loc": {
                              "line": 2,
                              "col": 23
                            },
                            "op": "not",
                            "expr": {
                              "identifier": {
                                "loc": {
                                  "line": 2,
                                  "col": 24
                                },
                                "kind": {
                                  "ident": "a"
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
                  "line": 3,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "y",
                    "value": {
                      "branch": {
                        "loc": {
                          "line": 3,
                          "col": 15
                        },
                        "kind": {
                          "if_": {
                            "cond": {
                              "identifier": {
                                "loc": {
                                  "line": 3,
                                  "col": 13
                                },
                                "kind": {
                                  "ident": "c"
                                }
                              }
                            },
                            "binding": "__bp_nullish",
                            "then_": [
                              {
                                "expr": {
                                  "identifier": {
                                    "loc": {
                                      "line": 3,
                                      "col": 15
                                    },
                                    "kind": {
                                      "ident": "__bp_nullish"
                                    }
                                  }
                                },
                                "emptyLinesBefore": 0
                              }
                            ],
                            "else_": [
                              {
                                "expr": {
                                  "literal": {
                                    "loc": {
                                      "line": 3,
                                      "col": 18
                                    },
                                    "kind": {
                                      "numberLit": "0"
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
                    "name": "z",
                    "value": {
                      "call": {
                        "loc": {
                          "line": 4,
                          "col": 16
                        },
                        "kind": {
                          "call": {
                            "receiver": {
                              "identifier": {
                                "loc": {
                                  "line": 4,
                                  "col": 13
                                },
                                "kind": {
                                  "ident": "c"
                                }
                              }
                            },
                            "callee": "toString",
                            "is_builtin": false,
                            "is_tagged": false,
                            "optional": true,
                            "args": [],
                            "trailing": []
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
                    "identifier": {
                      "loc": {
                        "line": 5,
                        "col": 12
                      },
                      "kind": {
                        "ident": "x"
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