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
              "optional": {
                "array": {
                  "named": "i32"
                }
              }
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": null
          },
          {
            "name": "g",
            "typeRef": {
              "optional": {
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
              }
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": null
          },
          {
            "name": "s",
            "typeRef": {
              "optional": {
                "named": "string"
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
                    "name": "a",
                    "value": {
                      "branch": {
                        "loc": {
                          "line": 2,
                          "col": 21
                        },
                        "kind": {
                          "if_": {
                            "cond": {
                              "call": {
                                "loc": {
                                  "line": 2,
                                  "col": 15
                                },
                                "kind": {
                                  "call": {
                                    "receiver": null,
                                    "callee": "[]",
                                    "is_builtin": true,
                                    "is_tagged": false,
                                    "optional": true,
                                    "args": [
                                      {
                                        "label": null,
                                        "value": {
                                          "identifier": {
                                            "loc": {
                                              "line": 2,
                                              "col": 13
                                            },
                                            "kind": {
                                              "ident": "xs"
                                            }
                                          }
                                        },
                                        "comments": [],
                                        "is_default_inj": false
                                      },
                                      {
                                        "label": null,
                                        "value": {
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
                                        "comments": [],
                                        "is_default_inj": false
                                      }
                                    ],
                                    "trailing": []
                                  }
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
                                      "col": 21
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
                                      "col": 24
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
                  "line": 3,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "b",
                    "value": {
                      "branch": {
                        "loc": {
                          "line": 3,
                          "col": 20
                        },
                        "kind": {
                          "if_": {
                            "cond": {
                              "call": {
                                "loc": {
                                  "line": 3,
                                  "col": 14
                                },
                                "kind": {
                                  "call": {
                                    "receiver": null,
                                    "callee": "",
                                    "is_builtin": false,
                                    "is_tagged": false,
                                    "optional": true,
                                    "args": [
                                      {
                                        "label": null,
                                        "value": {
                                          "literal": {
                                            "loc": {
                                              "line": 3,
                                              "col": 17
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
                                    "trailing": [],
                                    "calleeExpr": {
                                      "identifier": {
                                        "loc": {
                                          "line": 3,
                                          "col": 13
                                        },
                                        "kind": {
                                          "ident": "g"
                                        }
                                      }
                                    }
                                  }
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
                                      "col": 20
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
                                      "col": 23
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
                    "name": "c",
                    "value": {
                      "call": {
                        "loc": {
                          "line": 4,
                          "col": 16
                        },
                        "kind": {
                          "call": {
                            "receiver": {
                              "call": {
                                "loc": {
                                  "line": 4,
                                  "col": 14
                                },
                                "kind": {
                                  "call": {
                                    "receiver": null,
                                    "callee": "!",
                                    "is_builtin": true,
                                    "is_tagged": false,
                                    "optional": false,
                                    "args": [
                                      {
                                        "label": null,
                                        "value": {
                                          "identifier": {
                                            "loc": {
                                              "line": 4,
                                              "col": 13
                                            },
                                            "kind": {
                                              "ident": "s"
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
                            "callee": "length",
                            "is_builtin": false,
                            "is_tagged": false,
                            "optional": false,
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
              "binding": {
                "loc": {
                  "line": 5,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "d",
                    "value": {
                      "unaryOp": {
                        "loc": {
                          "line": 5,
                          "col": 13
                        },
                        "op": "not",
                        "expr": {
                          "identifier": {
                            "loc": {
                              "line": 5,
                              "col": 14
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
                  "line": 6,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "binaryOp": {
                      "loc": {
                        "line": 6,
                        "col": 18
                      },
                      "op": "add",
                      "lhs": {
                        "binaryOp": {
                          "loc": {
                            "line": 6,
                            "col": 14
                          },
                          "op": "add",
                          "lhs": {
                            "identifier": {
                              "loc": {
                                "line": 6,
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
                                "line": 6,
                                "col": 16
                              },
                              "kind": {
                                "ident": "b"
                              }
                            }
                          }
                        }
                      },
                      "rhs": {
                        "identifier": {
                          "loc": {
                            "line": 6,
                            "col": 20
                          },
                          "kind": {
                            "ident": "c"
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