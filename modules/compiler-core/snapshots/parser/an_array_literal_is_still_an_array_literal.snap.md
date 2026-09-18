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
              "jump": {
                "loc": {
                  "line": 1,
                  "col": 26
                },
                "kind": {
                  "return": {
                    "identifier": {
                      "loc": {
                        "line": 1,
                        "col": 36
                      },
                      "kind": {
                        "identAccess": {
                          "receiver": {
                            "identifier": {
                              "loc": {
                                "line": 1,
                                "col": 33
                              },
                              "kind": {
                                "ident": "xs"
                              }
                            }
                          },
                          "member": "length",
                          "optional": false
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
                    "name": "xs",
                    "value": {
                      "collection": {
                        "loc": {
                          "line": 3,
                          "col": 14
                        },
                        "kind": {
                          "arrayLit": {
                            "elems": [
                              {
                                "literal": {
                                  "loc": {
                                    "line": 3,
                                    "col": 15
                                  },
                                  "kind": {
                                    "numberLit": "1"
                                  }
                                }
                              },
                              {
                                "literal": {
                                  "loc": {
                                    "line": 3,
                                    "col": 18
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
                    "name": "n",
                    "value": {
                      "call": {
                        "loc": {
                          "line": 4,
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
                                  "collection": {
                                    "loc": {
                                      "line": 4,
                                      "col": 15
                                    },
                                    "kind": {
                                      "arrayLit": {
                                        "elems": [
                                          {
                                            "literal": {
                                              "loc": {
                                                "line": 4,
                                                "col": 16
                                              },
                                              "kind": {
                                                "numberLit": "1"
                                              }
                                            }
                                          },
                                          {
                                            "literal": {
                                              "loc": {
                                                "line": 4,
                                                "col": 19
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
                                "comments": [],
                                "is_default_inj": false
                              }
                            ],
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
                    "name": "s",
                    "value": {
                      "literal": {
                        "loc": {
                          "line": 5,
                          "col": 13
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
                  "line": 6,
                  "col": 5
                },
                "iter": {
                  "collection": {
                    "loc": {
                      "line": 6,
                      "col": 12
                    },
                    "kind": {
                      "range": {
                        "start": {
                          "literal": {
                            "loc": {
                              "line": 6,
                              "col": 11
                            },
                            "kind": {
                              "numberLit": "0"
                            }
                          }
                        },
                        "end": {
                          "literal": {
                            "loc": {
                              "line": 6,
                              "col": 14
                            },
                            "kind": {
                              "numberLit": "4"
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "indexRange": null,
                "params": [
                  "i"
                ],
                "paramsLoc": {
                  "line": 6,
                  "col": 19
                },
                "condition": false,
                "body": [
                  {
                    "expr": {
                      "binding": {
                        "loc": {
                          "line": 6,
                          "col": 24
                        },
                        "kind": {
                          "assign": {
                            "target": {
                              "name": "s"
                            },
                            "op": "assign",
                            "value": {
                              "binaryOp": {
                                "loc": {
                                  "line": 6,
                                  "col": 30
                                },
                                "op": "add",
                                "lhs": {
                                  "identifier": {
                                    "loc": {
                                      "line": 6,
                                      "col": 28
                                    },
                                    "kind": {
                                      "ident": "s"
                                    }
                                  }
                                },
                                "rhs": {
                                  "identifier": {
                                    "loc": {
                                      "line": 6,
                                      "col": 32
                                    },
                                    "kind": {
                                      "ident": "i"
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
                            "ident": "n"
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
                            "ident": "s"
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