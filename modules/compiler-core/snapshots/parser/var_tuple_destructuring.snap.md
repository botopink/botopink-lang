```json
{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "name": "swap",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "x",
            "typeRef": {
              "named": "i32"
            },
            "typeName": "",
            "modifier": "none",
            "typeinfoConstraints": null,
            "fnType": null,
            "destruct": null,
            "defaultVal": null
          },
          {
            "name": "y",
            "typeRef": {
              "named": "i32"
            },
            "typeName": "",
            "modifier": "none",
            "typeinfoConstraints": null,
            "fnType": null,
            "destruct": null,
            "defaultVal": null
          }
        ],
        "returnType": {
          "named": "i32"
        },
        "body": [
          {
            "expr": {
              "binding": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "localBindDestruct": {
                    "pattern": {
                      "tuple_": [
                        "a",
                        "b"
                      ]
                    },
                    "value": {
                      "collection": {
                        "loc": {
                          "line": 2,
                          "col": 19
                        },
                        "kind": {
                          "tupleLit": {
                            "elems": [
                              {
                                "identifier": {
                                  "loc": {
                                    "line": 2,
                                    "col": 21
                                  },
                                  "kind": {
                                    "ident": "x"
                                  }
                                }
                              },
                              {
                                "identifier": {
                                  "loc": {
                                    "line": 2,
                                    "col": 24
                                  },
                                  "kind": {
                                    "ident": "y"
                                  }
                                }
                              }
                            ],
                            "comments": [],
                            "commentsPerElem": []
                          }
                        }
                      }
                    },
                    "mutable": true
                  }
                }
              }
            },
            "emptyLinesBefore": 0
          },
          {
            "expr": {
              "controlFlow": {
                "loc": {
                  "line": 3,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "identifier": {
                      "loc": {
                        "line": 3,
                        "col": 12
                      },
                      "kind": {
                        "ident": "a"
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