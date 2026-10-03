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
        "name": "g",
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
          "optional": {
            "named": "i32"
          }
        },
        "typeGuardParam": null,
        "body": [
          {
            "expr": {
              "jump": {
                "loc": {
                  "line": 1,
                  "col": 24
                },
                "kind": {
                  "return": {
                    "identifier": {
                      "loc": {
                        "line": 1,
                        "col": 31
                      },
                      "kind": {
                        "ident": "n"
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
            "name": "c",
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
                    "name": "x",
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
                    "name": "y",
                    "value": {
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
                                  "branch": {
                                    "loc": {
                                      "line": 4,
                                      "col": 20
                                    },
                                    "kind": {
                                      "if_": {
                                        "cond": {
                                          "identifier": {
                                            "loc": {
                                              "line": 4,
                                              "col": 18
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
                                                  "line": 4,
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
                  "line": 5,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "z",
                    "value": {
                      "branch": {
                        "loc": {
                          "line": 5,
                          "col": 18
                        },
                        "kind": {
                          "if_": {
                            "cond": {
                              "call": {
                                "loc": {
                                  "line": 5,
                                  "col": 13
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
                                              "line": 5,
                                              "col": 15
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
                            "binding": "__bp_nullish",
                            "then_": [
                              {
                                "expr": {
                                  "identifier": {
                                    "loc": {
                                      "line": 5,
                                      "col": 18
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
                                      "line": 5,
                                      "col": 21
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
              "branch": {
                "loc": {
                  "line": 6,
                  "col": 5
                },
                "kind": {
                  "if_": {
                    "cond": {
                      "branch": {
                        "loc": {
                          "line": 6,
                          "col": 11
                        },
                        "kind": {
                          "if_": {
                            "cond": {
                              "identifier": {
                                "loc": {
                                  "line": 6,
                                  "col": 9
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
                                      "line": 6,
                                      "col": 11
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
                                      "line": 6,
                                      "col": 14
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
                    "binding": null,
                    "then_": [
                      {
                        "expr": {
                          "call": {
                            "loc": {
                              "line": 6,
                              "col": 23
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
                                          "col": 31
                                        },
                                        "kind": {
                                          "stringLit": "y"
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
                    ],
                    "else_": null
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
                  "line": 7,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "binaryOp": {
                      "loc": {
                        "line": 7,
                        "col": 18
                      },
                      "op": "add",
                      "lhs": {
                        "binaryOp": {
                          "loc": {
                            "line": 7,
                            "col": 14
                          },
                          "op": "add",
                          "lhs": {
                            "identifier": {
                              "loc": {
                                "line": 7,
                                "col": 12
                              },
                              "kind": {
                                "ident": "x"
                              }
                            }
                          },
                          "rhs": {
                            "identifier": {
                              "loc": {
                                "line": 7,
                                "col": 16
                              },
                              "kind": {
                                "ident": "y"
                              }
                            }
                          }
                        }
                      },
                      "rhs": {
                        "identifier": {
                          "loc": {
                            "line": 7,
                            "col": 20
                          },
                          "kind": {
                            "ident": "z"
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