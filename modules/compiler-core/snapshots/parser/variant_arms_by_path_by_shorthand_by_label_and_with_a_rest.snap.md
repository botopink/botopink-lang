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
        "name": "area",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "s",
            "typeRef": {
              "named": "Shape"
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
                                  "ident": "s"
                                }
                              }
                            }
                          ],
                          "arms": [
                            {
                              "pattern": {
                                "variant": {
                                  "name": "Shape.Circle",
                                  "payload": {
                                    "fields": [
                                      "r"
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
                                    "line": 3,
                                    "col": 27
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
                                              "col": 27
                                            },
                                            "kind": {
                                              "ident": "r"
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
                                  "name": ".Rect",
                                  "payload": {
                                    "fields": [
                                      "w",
                                      "h"
                                    ]
                                  },
                                  "shape": "variant",
                                  "labels": [
                                    "width",
                                    "height"
                                  ],
                                  "rest": false
                                }
                              },
                              "body": {
                                "function": {
                                  "loc": {
                                    "line": 4,
                                    "col": 38
                                  },
                                  "kind": {
                                    "syntax": "lambda",
                                    "params": [],
                                    "body": [
                                      {
                                        "expr": {
                                          "identifier": {
                                            "loc": {
                                              "line": 4,
                                              "col": 38
                                            },
                                            "kind": {
                                              "ident": "w"
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
                                  "name": ".Rect",
                                  "payload": {
                                    "fields": [
                                      "w"
                                    ]
                                  },
                                  "shape": "variant",
                                  "labels": [
                                    "width"
                                  ],
                                  "rest": true
                                }
                              },
                              "body": {
                                "function": {
                                  "loc": {
                                    "line": 5,
                                    "col": 31
                                  },
                                  "kind": {
                                    "syntax": "lambda",
                                    "params": [],
                                    "body": [
                                      {
                                        "expr": {
                                          "identifier": {
                                            "loc": {
                                              "line": 5,
                                              "col": 31
                                            },
                                            "kind": {
                                              "ident": "w"
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
                                  "name": ".Square",
                                  "payload": {
                                    "fields": []
                                  },
                                  "shape": "variant",
                                  "labels": [],
                                  "rest": true
                                }
                              },
                              "body": {
                                "function": {
                                  "loc": {
                                    "line": 6,
                                    "col": 23
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
                              },
                              "guard": null,
                              "emptyLinesBefore": 0
                            },
                            {
                              "pattern": {
                                "ident": ".None"
                              },
                              "body": {
                                "function": {
                                  "loc": {
                                    "line": 7,
                                    "col": 17
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
                                              "col": 17
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