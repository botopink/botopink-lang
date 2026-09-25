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
          "array": {
            "named": "i32"
          }
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
                    "name": "b",
                    "value": {
                      "collection": {
                        "loc": {
                          "line": 2,
                          "col": 13
                        },
                        "kind": {
                          "arrayLit": {
                            "elems": [
                              {
                                "literal": {
                                  "loc": {
                                    "line": 2,
                                    "col": 14
                                  },
                                  "kind": {
                                    "numberLit": "1"
                                  }
                                }
                              },
                              {
                                "literal": {
                                  "loc": {
                                    "line": 2,
                                    "col": 17
                                  },
                                  "kind": {
                                    "numberLit": "2"
                                  }
                                }
                              }
                            ],
                            "spread": "a",
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
                  "line": 3,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "c",
                    "value": {
                      "collection": {
                        "loc": {
                          "line": 3,
                          "col": 13
                        },
                        "kind": {
                          "arrayLit": {
                            "elems": [],
                            "spread": "a",
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
                    "name": "d",
                    "value": {
                      "collection": {
                        "loc": {
                          "line": 4,
                          "col": 13
                        },
                        "kind": {
                          "arrayLit": {
                            "elems": [
                              {
                                "literal": {
                                  "loc": {
                                    "line": 4,
                                    "col": 14
                                  },
                                  "kind": {
                                    "numberLit": "1"
                                  }
                                }
                              }
                            ],
                            "spread": "a",
                            "spreadExpr": null,
                            "comments": [],
                            "commentsPerElem": [],
                            "trailingComma": true
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
                        "ident": "b"
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