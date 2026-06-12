```json
{
  "decls": [
    {
      "record": {
        "name": "User",
        "id": 1,
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "implement": [],
        "fields": [
          {
            "name": "name",
            "typeRef": {
              "named": "string"
            },
            "default": null,
            "annotations": []
          }
        ],
        "trailingComma": false,
        "methods": []
      }
    },
    {
      "fn": {
        "isPub": false,
        "effect": null,
        "isDeclare": false,
        "isDefault": false,
        "label": null,
        "name": "main",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [],
        "returnType": null,
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
                    "name": "u",
                    "value": {
                      "call": {
                        "loc": {
                          "line": 3,
                          "col": 20
                        },
                        "kind": {
                          "call": {
                            "receiver": null,
                            "callee": "User",
                            "is_builtin": false,
                            "is_tagged": false,
                            "optional": false,
                            "args": [
                              {
                                "label": "name",
                                "value": {
                                  "literal": {
                                    "loc": {
                                      "line": 3,
                                      "col": 31
                                    },
                                    "kind": {
                                      "stringLit": "ana"
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
                    "mutable": false,
                    "typeAnnotation": {
                      "optional": {
                        "named": "User"
                      }
                    }
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
                      "identifier": {
                        "loc": {
                          "line": 4,
                          "col": 16
                        },
                        "kind": {
                          "identAccess": {
                            "receiver": {
                              "identifier": {
                                "loc": {
                                  "line": 4,
                                  "col": 13
                                },
                                "kind": {
                                  "ident": "u"
                                }
                              }
                            },
                            "member": "name",
                            "optional": true
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