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
            "genericParams": [],
            "params": [
              {
                "name": "self",
                "typeRef": {
                  "named": "Self"
                },
                "typeName": "",
                "modifier": "none",
                "typeinfoConstraints": null,
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
            "genericParams": [],
            "params": [
              {
                "name": "self",
                "typeRef": {
                  "named": "Self"
                },
                "typeName": "",
                "modifier": "none",
                "typeinfoConstraints": null,
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
                      "col": 9
                    },
                    "kind": {
                      "call": {
                        "receiver": "Console",
                        "callee": "WriteLine",
                        "args": [
                          {
                            "label": null,
                            "value": {
                              "binaryOp": {
                                "loc": {
                                  "line": 5,
                                  "col": 59
                                },
                                "kind": {
                                  "add": {
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
                                          "col": 61
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
                                            "member": "color"
                                          }
                                        }
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