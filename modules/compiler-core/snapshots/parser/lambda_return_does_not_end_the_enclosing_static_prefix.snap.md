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
        "name": "Counter",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [],
        "returnType": null,
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
                    "name": "doubled",
                    "value": {
                      "useHook": {
                        "loc": {
                          "line": 2,
                          "col": 19
                        },
                        "kind": {
                          "inner": {
                            "call": {
                              "loc": {
                                "line": 2,
                                "col": 23
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
                                            "jump": {
                                              "loc": {
                                                "line": 2,
                                                "col": 33
                                              },
                                              "kind": {
                                                "return": {
                                                  "literal": {
                                                    "loc": {
                                                      "line": 2,
                                                      "col": 40
                                                    },
                                                    "kind": {
                                                      "numberLit": "2"
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
                                  ]
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
                    "name": "c",
                    "value": {
                      "useHook": {
                        "loc": {
                          "line": 3,
                          "col": 13
                        },
                        "kind": {
                          "inner": {
                            "call": {
                              "loc": {
                                "line": 3,
                                "col": 17
                              },
                              "kind": {
                                "call": {
                                  "receiver": null,
                                  "callee": "state",
                                  "is_builtin": false,
                                  "is_tagged": false,
                                  "optional": false,
                                  "args": [
                                    {
                                      "label": null,
                                      "value": {
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
                                      "comments": [],
                                      "is_default_inj": false
                                    }
                                  ],
                                  "trailing": []
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
          }
        ]
      }
    }
  ]
}
```