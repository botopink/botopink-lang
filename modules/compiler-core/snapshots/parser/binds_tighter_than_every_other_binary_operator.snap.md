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
            "name": "b",
            "typeRef": {
              "optional": {
                "named": "bool"
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
                        "op": "eq",
                        "lhs": {
                          "branch": {
                            "loc": {
                              "line": 2,
                              "col": 15
                            },
                            "kind": {
                              "if_": {
                                "cond": {
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
                                "binding": "__bp_nullish",
                                "then_": [
                                  {
                                    "expr": {
                                      "identifier": {
                                        "loc": {
                                          "line": 2,
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
                                          "line": 2,
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
                        "rhs": {
                          "literal": {
                            "loc": {
                              "line": 2,
                              "col": 23
                            },
                            "kind": {
                              "numberLit": "1"
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
                      "binaryOp": {
                        "loc": {
                          "line": 3,
                          "col": 20
                        },
                        "op": "add",
                        "lhs": {
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
                                      "ident": "a"
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
                        "rhs": {
                          "literal": {
                            "loc": {
                              "line": 3,
                              "col": 22
                            },
                            "kind": {
                              "numberLit": "1"
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
                    "name": "z",
                    "value": {
                      "binaryOp": {
                        "loc": {
                          "line": 4,
                          "col": 24
                        },
                        "op": "and",
                        "lhs": {
                          "branch": {
                            "loc": {
                              "line": 4,
                              "col": 15
                            },
                            "kind": {
                              "if_": {
                                "cond": {
                                  "identifier": {
                                    "loc": {
                                      "line": 4,
                                      "col": 13
                                    },
                                    "kind": {
                                      "ident": "b"
                                    }
                                  }
                                },
                                "binding": "__bp_nullish",
                                "then_": [
                                  {
                                    "expr": {
                                      "identifier": {
                                        "loc": {
                                          "line": 4,
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
                                      "identifier": {
                                        "loc": {
                                          "line": 4,
                                          "col": 18
                                        },
                                        "kind": {
                                          "ident": "false"
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
                        "rhs": {
                          "identifier": {
                            "loc": {
                              "line": 4,
                              "col": 27
                            },
                            "kind": {
                              "ident": "true"
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