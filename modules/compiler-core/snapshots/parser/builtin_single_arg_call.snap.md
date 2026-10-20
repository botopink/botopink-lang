```json
{
  "decls": [
    {
      "behavior": {
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
            "returnType": {
              "named": "void"
            },
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
                        "callee": "sizeOf",
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
                                  "col": 17
                                },
                                "kind": {
                                  "ident": "Int"
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
                        "callee": "typeName",
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
                                  "col": 19
                                },
                                "kind": {
                                  "ident": "Bool"
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
                        "callee": "panic",
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
                                  "stringLit": "unreachable"
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
            "is_default": true,
            "is_declare": false,
            "isPub": false
          }
        ]
      }
    },
    {
      "use": {
        "imports": [
          {
            "segments": [
              "failure",
              "panic"
            ],
            "activate": false,
            "alias": null
          }
        ],
        "source": {
          "module": "std"
        },
        "package": null,
        "activationOnly": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null
      }
    }
  ]
}
```