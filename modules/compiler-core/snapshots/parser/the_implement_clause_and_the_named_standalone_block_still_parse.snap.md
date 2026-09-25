```json
{
  "decls": [
    {
      "behavior": {
        "name": "A",
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
            "name": "f",
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
                "default": null
              }
            ],
            "returnType": {
              "named": "i32"
            },
            "body": null,
            "is_default": false,
            "is_declare": false,
            "isPub": false
          }
        ]
      }
    },
    {
      "type_": {
        "name": "P",
        "id": 1,
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "implement": [
          {
            "named": "A"
          }
        ],
        "shape": {
          "record": [
            {
              "name": "x",
              "typeRef": {
                "named": "i32"
              },
              "default": null,
              "annotations": []
            }
          ]
        },
        "trailingComma": false,
        "methods": [
          {
            "name": "f",
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
                "default": null
              }
            ],
            "returnType": {
              "named": "i32"
            },
            "body": [
              {
                "expr": {
                  "jump": {
                    "loc": {
                      "line": 2,
                      "col": 56
                    },
                    "kind": {
                      "return": {
                        "identifier": {
                          "loc": {
                            "line": 2,
                            "col": 68
                          },
                          "kind": {
                            "identAccess": {
                              "receiver": {
                                "identifier": {
                                  "loc": {
                                    "line": 2,
                                    "col": 63
                                  },
                                  "kind": {
                                    "ident": "self"
                                  }
                                }
                              },
                              "member": "x",
                              "optional": false
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "emptyLinesBefore": 0
              }
            ],
            "is_default": false,
            "is_declare": false,
            "isPub": false
          }
        ]
      }
    },
    {
      "type_": {
        "name": "Q",
        "id": 2,
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "implement": [],
        "shape": {
          "record": [
            {
              "name": "x",
              "typeRef": {
                "named": "i32"
              },
              "default": null,
              "annotations": []
            }
          ]
        },
        "trailingComma": false,
        "methods": []
      }
    },
    {
      "implement": {
        "name": "Impl",
        "isPub": false,
        "shorthand": true,
        "genericParams": [],
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "interfaces": [
          {
            "named": "A"
          }
        ],
        "target": "Q",
        "methods": [
          {
            "qualifier": null,
            "name": "f",
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
                "default": null
              }
            ],
            "body": [
              {
                "expr": {
                  "jump": {
                    "loc": {
                      "line": 4,
                      "col": 52
                    },
                    "kind": {
                      "return": {
                        "identifier": {
                          "loc": {
                            "line": 4,
                            "col": 64
                          },
                          "kind": {
                            "identAccess": {
                              "receiver": {
                                "identifier": {
                                  "loc": {
                                    "line": 4,
                                    "col": 59
                                  },
                                  "kind": {
                                    "ident": "self"
                                  }
                                }
                              },
                              "member": "x",
                              "optional": false
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
        ]
      }
    }
  ]
}
```