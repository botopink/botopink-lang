```json
{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "effect": "task",
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
            "default": null
          }
        ],
        "returnType": {
          "generic": {
            "name": "Task",
            "args": [
              {
                "named": "Int"
              }
            ],
            "is_builtin": true
          }
        },
        "typeGuardParam": null,
        "body": [
          {
            "expr": {
              "loop": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "keyword": "for_",
                "generator": null,
                "iter": {
                  "identifier": {
                    "loc": {
                      "line": 2,
                      "col": 16
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
                "paramsLoc": {
                  "line": 2,
                  "col": 25
                },
                "condition": false,
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