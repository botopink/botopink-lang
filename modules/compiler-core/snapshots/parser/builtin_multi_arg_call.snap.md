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
                      "builtinCall": {
                        "name": "@min",
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
                        ]
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
                      "builtinCall": {
                        "name": "@max",
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
                        ]
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
                      "builtinCall": {
                        "name": "@as",
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
                        ]
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