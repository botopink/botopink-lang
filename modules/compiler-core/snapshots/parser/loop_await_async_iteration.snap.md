```json
{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "effect": "future",
        "isDeclare": false,
        "isDefault": false,
        "label": null,
        "name": "consume",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "items",
            "typeRef": {
              "array": {
                "named": "Int"
              }
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "defaultVal": null
          }
        ],
        "returnType": {
          "generic": {
            "name": "Future",
            "args": [
              {
                "named": "Int"
              }
            ],
            "is_builtin": true
          }
        },
        "body": [
          {
            "expr": {
              "loop": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "iter": {
                  "identifier": {
                    "loc": {
                      "line": 2,
                      "col": 17
                    },
                    "kind": {
                      "ident": "items"
                    }
                  }
                },
                "indexRange": null,
                "params": [
                  "item"
                ],
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
                            "callee": "handle",
                            "is_builtin": false,
                            "is_tagged": false,
                            "optional": false,
                            "args": [
                              {
                                "label": null,
                                "value": {
                                  "identifier": {
                                    "loc": {
                                      "line": 3,
                                      "col": 16
                                    },
                                    "kind": {
                                      "ident": "item"
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
                "awaitLoop": true,
                "label": null
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