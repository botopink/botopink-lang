```json
{
  "decls": [
    {
      "interface": {
        "name": "Test",
        "id": 1,
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "extends": [],
        "fields": [],
        "trailingComma": false,
        "methods": [
          {
            "name": "run",
            "annotations": [],
            "genericParams": [],
            "params": [],
            "returnType": null,
            "body": [
              {
                "expr": {
                  "call": {
                    "loc": {
                      "line": 3,
                      "col": 9
                    },
                    "kind": {
                      "call": {
                        "receiver": null,
                        "callee": "min",
                        "is_builtin": true,
                        "is_tagged": false,
                        "optional": false,
                        "args": [
                          {
                            "label": null,
                            "value": {
                              "identifier": {
                                "loc": {
                                  "line": 3,
                                  "col": 14
                                },
                                "kind": {
                                  "ident": "a"
                                }
                              }
                            },
                            "comments": []
                          },
                          {
                            "label": null,
                            "value": {
                              "identifier": {
                                "loc": {
                                  "line": 3,
                                  "col": 17
                                },
                                "kind": {
                                  "ident": "b"
                                }
                              }
                            },
                            "comments": []
                          }
                        ],
                        "trailing": []
                      }
                    }
                  }
                },
                "emptyLinesBefore": 0
              },
              {
                "expr": {
                  "call": {
                    "loc": {
                      "line": 4,
                      "col": 9
                    },
                    "kind": {
                      "call": {
                        "receiver": null,
                        "callee": "max",
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
                                  "col": 14
                                },
                                "kind": {
                                  "ident": "x"
                                }
                              }
                            },
                            "comments": []
                          },
                          {
                            "label": null,
                            "value": {
                              "identifier": {
                                "loc": {
                                  "line": 4,
                                  "col": 17
                                },
                                "kind": {
                                  "ident": "y"
                                }
                              }
                            },
                            "comments": []
                          }
                        ],
                        "trailing": []
                      }
                    }
                  }
                },
                "emptyLinesBefore": 0
              },
              {
                "expr": {
                  "call": {
                    "loc": {
                      "line": 5,
                      "col": 9
                    },
                    "kind": {
                      "call": {
                        "receiver": null,
                        "callee": "as",
                        "is_builtin": true,
                        "is_tagged": false,
                        "optional": false,
                        "args": [
                          {
                            "label": null,
                            "value": {
                              "identifier": {
                                "loc": {
                                  "line": 5,
                                  "col": 13
                                },
                                "kind": {
                                  "ident": "Int"
                                }
                              }
                            },
                            "comments": []
                          },
                          {
                            "label": null,
                            "value": {
                              "identifier": {
                                "loc": {
                                  "line": 5,
                                  "col": 18
                                },
                                "kind": {
                                  "ident": "value"
                                }
                              }
                            },
                            "comments": []
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
            "is_default": true,
            "is_declare": false,
            "isPub": false
          }
        ]
      }
    }
  ]
}
```