```json
{
  "decls": [
    {
      "interface": {
        "name": "Drawable",
        "id": 1,
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "extends": [],
        "fields": [
          {
            "name": "color",
            "typeName": "string"
          }
        ],
        "trailingComma": false,
        "methods": [
          {
            "name": "draw",
            "annotations": [],
            "genericParams": [],
            "params": [
              {
                "name": "self",
                "typeRef": {
                  "named": "Self"
                },
                "typeName": "",
                "modifier": "none",
                "fnType": null,
                "destruct": null,
                "defaultVal": null
              }
            ],
            "returnType": null,
            "body": null,
            "is_default": false,
            "is_declare": false,
            "isPub": false
          },
          {
            "name": "log",
            "annotations": [],
            "genericParams": [],
            "params": [
              {
                "name": "self",
                "typeRef": {
                  "named": "Self"
                },
                "typeName": "",
                "modifier": "none",
                "fnType": null,
                "destruct": null,
                "defaultVal": null
              }
            ],
            "returnType": null,
            "body": [
              {
                "expr": {
                  "call": {
                    "loc": {
                      "line": 5,
                      "col": 17
                    },
                    "kind": {
                      "call": {
                        "receiver": {
                          "identifier": {
                            "loc": {
                              "line": 5,
                              "col": 9
                            },
                            "kind": {
                              "ident": "Console"
                            }
                          }
                        },
                        "callee": "WriteLine",
                        "is_builtin": false,
                        "is_tagged": false,
                        "optional": false,
                        "args": [
                          {
                            "label": null,
                            "value": {
                              "binaryOp": {
                                "loc": {
                                  "line": 5,
                                  "col": 59
                                },
                                "op": "add",
                                "lhs": {
                                  "literal": {
                                    "loc": {
                                      "line": 5,
                                      "col": 27
                                    },
                                    "kind": {
                                      "stringLit": "Rendering object with color: "
                                    }
                                  }
                                },
                                "rhs": {
                                  "identifier": {
                                    "loc": {
                                      "line": 5,
                                      "col": 66
                                    },
                                    "kind": {
                                      "identAccess": {
                                        "receiver": {
                                          "identifier": {
                                            "loc": {
                                              "line": 5,
                                              "col": 61
                                            },
                                            "kind": {
                                              "ident": "self"
                                            }
                                          }
                                        },
                                        "member": "color",
                                        "optional": false
                                      }
                                    }
                                  }
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