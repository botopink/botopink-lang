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
            "name": "xs",
            "typeRef": {
              "array": {
                "named": "i32"
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
                    "name": "ys",
                    "value": {
                      "call": {
                        "loc": {
                          "line": 2,
                          "col": 17
                        },
                        "kind": {
                          "call": {
                            "receiver": {
                              "identifier": {
                                "loc": {
                                  "line": 2,
                                  "col": 14
                                },
                                "kind": {
                                  "ident": "xs"
                                }
                              }
                            },
                            "callee": "map",
                            "is_builtin": false,
                            "is_tagged": false,
                            "optional": false,
                            "args": [],
                            "trailing": [
                              {
                                "label": null,
                                "params": [
                                  "x"
                                ],
                                "body": [
                                  {
                                    "expr": {
                                      "binaryOp": {
                                        "loc": {
                                          "line": 2,
                                          "col": 30
                                        },
                                        "op": "add",
                                        "lhs": {
                                          "identifier": {
                                            "loc": {
                                              "line": 2,
                                              "col": 28
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
                                              "col": 32
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
                  "line": 3,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "acc",
                    "value": {
                      "literal": {
                        "loc": {
                          "line": 3,
                          "col": 15
                        },
                        "kind": {
                          "numberLit": "0"
                        }
                      }
                    },
                    "mutable": true,
                    "typeAnnotation": null
                  }
                }
              }
            },
            "emptyLinesBefore": 0
          },
          {
            "expr": {
              "loop": {
                "loc": {
                  "line": 4,
                  "col": 5
                },
                "keyword": "for_",
                "generator": null,
                "iter": {
                  "identifier": {
                    "loc": {
                      "line": 4,
                      "col": 10
                    },
                    "kind": {
                      "ident": "xs"
                    }
                  }
                },
                "indexRange": null,
                "params": [
                  "x"
                ],
                "paramsLoc": {
                  "line": 4,
                  "col": 16
                },
                "condition": false,
                "body": [
                  {
                    "expr": {
                      "binding": {
                        "loc": {
                          "line": 4,
                          "col": 21
                        },
                        "kind": {
                          "assign": {
                            "target": {
                              "name": "acc"
                            },
                            "op": "assign",
                            "value": {
                              "binaryOp": {
                                "loc": {
                                  "line": 4,
                                  "col": 31
                                },
                                "op": "add",
                                "lhs": {
                                  "identifier": {
                                    "loc": {
                                      "line": 4,
                                      "col": 27
                                    },
                                    "kind": {
                                      "ident": "acc"
                                    }
                                  }
                                },
                                "rhs": {
                                  "identifier": {
                                    "loc": {
                                      "line": 4,
                                      "col": 33
                                    },
                                    "kind": {
                                      "ident": "x"
                                    }
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
                ],
                "awaitLoop": false,
                "label": null
              }
            },
            "emptyLinesBefore": 0
          },
          {
            "expr": {
              "call": {
                "loc": {
                  "line": 5,
                  "col": 8
                },
                "kind": {
                  "call": {
                    "receiver": {
                      "identifier": {
                        "loc": {
                          "line": 5,
                          "col": 5
                        },
                        "kind": {
                          "ident": "xs"
                        }
                      }
                    },
                    "callee": "forEach",
                    "is_builtin": false,
                    "is_tagged": false,
                    "optional": false,
                    "args": [],
                    "trailing": [
                      {
                        "label": null,
                        "params": [
                          "x"
                        ],
                        "body": [
                          {
                            "expr": {
                              "call": {
                                "loc": {
                                  "line": 5,
                                  "col": 23
                                },
                                "kind": {
                                  "call": {
                                    "receiver": null,
                                    "callee": "print",
                                    "is_builtin": true,
                                    "is_tagged": false,
                                    "optional": false,
                                    "args": [
                                      {
                                        "label": null,
                                        "value": {
                                          "call": {
                                            "loc": {
                                              "line": 5,
                                              "col": 32
                                            },
                                            "kind": {
                                              "call": {
                                                "receiver": {
                                                  "identifier": {
                                                    "loc": {
                                                      "line": 5,
                                                      "col": 30
                                                    },
                                                    "kind": {
                                                      "ident": "x"
                                                    }
                                                  }
                                                },
                                                "callee": "toString",
                                                "is_builtin": false,
                                                "is_tagged": false,
                                                "optional": false,
                                                "args": [],
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
                            },
                            "emptyLinesBefore": 0
                          }
                        ]
                      }
                    ]
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
                  "line": 6,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "z",
                    "value": {
                      "call": {
                        "loc": {
                          "line": 6,
                          "col": 13
                        },
                        "kind": {
                          "call": {
                            "receiver": null,
                            "callee": "calcular",
                            "is_builtin": false,
                            "is_tagged": false,
                            "optional": false,
                            "args": [
                              {
                                "label": "fator",
                                "value": {
                                  "literal": {
                                    "loc": {
                                      "line": 6,
                                      "col": 29
                                    },
                                    "kind": {
                                      "numberLit": "2"
                                    }
                                  }
                                },
                                "comments": [],
                                "is_default_inj": false
                              }
                            ],
                            "trailing": [
                              {
                                "label": null,
                                "params": [
                                  "a",
                                  "b"
                                ],
                                "body": [
                                  {
                                    "expr": {
                                      "binaryOp": {
                                        "loc": {
                                          "line": 6,
                                          "col": 44
                                        },
                                        "op": "add",
                                        "lhs": {
                                          "identifier": {
                                            "loc": {
                                              "line": 6,
                                              "col": 42
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
                                              "col": 46
                                            },
                                            "kind": {
                                              "ident": "b"
                                            }
                                          }
                                        }
                                      }
                                    },
                                    "emptyLinesBefore": 0
                                  }
                                ]
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
                  "line": 7,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "w",
                    "value": {
                      "call": {
                        "loc": {
                          "line": 7,
                          "col": 13
                        },
                        "kind": {
                          "call": {
                            "receiver": null,
                            "callee": "memo",
                            "is_builtin": false,
                            "is_tagged": false,
                            "optional": false,
                            "args": [],
                            "trailing": [
                              {
                                "label": null,
                                "params": [],
                                "body": [
                                  {
                                    "expr": {
                                      "literal": {
                                        "loc": {
                                          "line": 7,
                                          "col": 23
                                        },
                                        "kind": {
                                          "numberLit": "42"
                                        }
                                      }
                                    },
                                    "emptyLinesBefore": 0
                                  }
                                ]
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
              "jump": {
                "loc": {
                  "line": 8,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "identifier": {
                      "loc": {
                        "line": 8,
                        "col": 12
                      },
                      "kind": {
                        "ident": "acc"
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