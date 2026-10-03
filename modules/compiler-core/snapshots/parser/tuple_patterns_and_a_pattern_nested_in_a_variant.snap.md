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
            "name": "p",
            "typeRef": {
              "tuple_": [
                {
                  "named": "i32"
                },
                {
                  "named": "string"
                }
              ]
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": null
          }
        ],
        "returnType": {
          "named": "string"
        },
        "typeGuardParam": null,
        "body": [
          {
            "expr": {
              "jump": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "collection": {
                      "loc": {
                        "line": 2,
                        "col": 12
                      },
                      "kind": {
                        "case": {
                          "subjects": [
                            {
                              "identifier": {
                                "loc": {
                                  "line": 2,
                                  "col": 17
                                },
                                "kind": {
                                  "ident": "p"
                                }
                              }
                            }
                          ],
                          "arms": [
                            {
                              "pattern": {
                                "variant": {
                                  "name": "",
                                  "payload": {
                                    "literals": [
                                      {
                                        "numberLit": "0"
                                      },
                                      {
                                        "ident": "s"
                                      }
                                    ]
                                  },
                                  "shape": "tuple",
                                  "labels": [],
                                  "rest": false
                                }
                              },
                              "body": {
                                "function": {
                                  "loc": {
                                    "line": 3,
                                    "col": 19
                                  },
                                  "kind": {
                                    "syntax": "lambda",
                                    "params": [],
                                    "body": [
                                      {
                                        "expr": {
                                          "identifier": {
                                            "loc": {
                                              "line": 3,
                                              "col": 19
                                            },
                                            "kind": {
                                              "ident": "s"
                                            }
                                          }
                                        },
                                        "emptyLinesBefore": 0
                                      }
                                    ]
                                  }
                                }
                              },
                              "guard": null,
                              "emptyLinesBefore": 0
                            },
                            {
                              "pattern": {
                                "variant": {
                                  "name": "",
                                  "payload": {
                                    "literals": [
                                      {
                                        "ident": "n"
                                      },
                                      {
                                        "stringLit": "x"
                                      }
                                    ]
                                  },
                                  "shape": "tuple",
                                  "labels": [],
                                  "rest": false
                                }
                              },
                              "body": {
                                "function": {
                                  "loc": {
                                    "line": 4,
                                    "col": 21
                                  },
                                  "kind": {
                                    "syntax": "lambda",
                                    "params": [],
                                    "body": [
                                      {
                                        "expr": {
                                          "literal": {
                                            "loc": {
                                              "line": 4,
                                              "col": 21
                                            },
                                            "kind": {
                                              "stringLit": "x"
                                            }
                                          }
                                        },
                                        "emptyLinesBefore": 0
                                      }
                                    ]
                                  }
                                }
                              },
                              "guard": null,
                              "emptyLinesBefore": 0
                            },
                            {
                              "pattern": {
                                "variant": {
                                  "name": "",
                                  "payload": {
                                    "literals": [
                                      {
                                        "ident": "a"
                                      }
                                    ]
                                  },
                                  "shape": "tuple",
                                  "labels": [],
                                  "rest": true
                                }
                              },
                              "body": {
                                "function": {
                                  "loc": {
                                    "line": 5,
                                    "col": 20
                                  },
                                  "kind": {
                                    "syntax": "lambda",
                                    "params": [],
                                    "body": [
                                      {
                                        "expr": {
                                          "literal": {
                                            "loc": {
                                              "line": 5,
                                              "col": 20
                                            },
                                            "kind": {
                                              "stringLit": "rest"
                                            }
                                          }
                                        },
                                        "emptyLinesBefore": 0
                                      }
                                    ]
                                  }
                                }
                              },
                              "guard": null,
                              "emptyLinesBefore": 0
                            },
                            {
                              "pattern": {
                                "variant": {
                                  "name": ".Some",
                                  "payload": {
                                    "literals": [
                                      {
                                        "variant": {
                                          "name": "",
                                          "payload": {
                                            "literals": [
                                              {
                                                "ident": "a"
                                              },
                                              {
                                                "ident": "b"
                                              }
                                            ]
                                          },
                                          "shape": "tuple",
                                          "labels": [],
                                          "rest": false
                                        }
                                      }
                                    ]
                                  },
                                  "shape": "variant",
                                  "labels": [],
                                  "rest": false
                                }
                              },
                              "body": {
                                "function": {
                                  "loc": {
                                    "line": 6,
                                    "col": 26
                                  },
                                  "kind": {
                                    "syntax": "lambda",
                                    "params": [],
                                    "body": [
                                      {
                                        "expr": {
                                          "literal": {
                                            "loc": {
                                              "line": 6,
                                              "col": 26
                                            },
                                            "kind": {
                                              "stringLit": "pair"
                                            }
                                          }
                                        },
                                        "emptyLinesBefore": 0
                                      }
                                    ]
                                  }
                                }
                              },
                              "guard": null,
                              "emptyLinesBefore": 0
                            },
                            {
                              "pattern": {
                                "wildcard": {}
                              },
                              "body": {
                                "function": {
                                  "loc": {
                                    "line": 7,
                                    "col": 13
                                  },
                                  "kind": {
                                    "syntax": "lambda",
                                    "params": [],
                                    "body": [
                                      {
                                        "expr": {
                                          "literal": {
                                            "loc": {
                                              "line": 7,
                                              "col": 13
                                            },
                                            "kind": {
                                              "stringLit": "other"
                                            }
                                          }
                                        },
                                        "emptyLinesBefore": 0
                                      }
                                    ]
                                  }
                                }
                              },
                              "guard": null,
                              "emptyLinesBefore": 0
                            }
                          ],
                          "trailingComments": []
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