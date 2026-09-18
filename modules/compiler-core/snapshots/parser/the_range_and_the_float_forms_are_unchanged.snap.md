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
          "named": "f64"
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
                    "name": "s",
                    "value": {
                      "literal": {
                        "loc": {
                          "line": 2,
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
                  "line": 3,
                  "col": 5
                },
                "iter": {
                  "collection": {
                    "loc": {
                      "line": 3,
                      "col": 12
                    },
                    "kind": {
                      "range": {
                        "start": {
                          "literal": {
                            "loc": {
                              "line": 3,
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
                              "line": 3,
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
                  "line": 3,
                  "col": 19
                },
                "condition": false,
                "body": [
                  {
                    "expr": {
                      "binding": {
                        "loc": {
                          "line": 3,
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
                                  "line": 3,
                                  "col": 30
                                },
                                "op": "add",
                                "lhs": {
                                  "identifier": {
                                    "loc": {
                                      "line": 3,
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
                                      "line": 3,
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
              "binding": {
                "loc": {
                  "line": 4,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "a",
                    "value": {
                      "literal": {
                        "loc": {
                          "line": 4,
                          "col": 13
                        },
                        "kind": {
                          "numberLit": "1.5"
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
                    "name": "b",
                    "value": {
                      "literal": {
                        "loc": {
                          "line": 5,
                          "col": 13
                        },
                        "kind": {
                          "numberLit": "1_000"
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
                  "line": 6,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "c",
                    "value": {
                      "literal": {
                        "loc": {
                          "line": 6,
                          "col": 13
                        },
                        "kind": {
                          "numberLit": "1e10"
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
                    "name": "d",
                    "value": {
                      "literal": {
                        "loc": {
                          "line": 7,
                          "col": 13
                        },
                        "kind": {
                          "numberLit": "0xFF"
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
                  "line": 8,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "e",
                    "value": {
                      "literal": {
                        "loc": {
                          "line": 8,
                          "col": 13
                        },
                        "kind": {
                          "numberLit": "1_000.5"
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
                  "line": 9,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "identifier": {
                      "loc": {
                        "line": 9,
                        "col": 12
                      },
                      "kind": {
                        "ident": "a"
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