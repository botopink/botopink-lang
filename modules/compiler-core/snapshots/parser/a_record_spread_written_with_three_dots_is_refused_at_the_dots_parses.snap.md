```json
{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "effect": null,
        "isDeclare": false,
        "isDefault": false,
        "label": null,
        "name": "f",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "o",
            "typeRef": {
              "named": "P"
            },
            "typeName": "",
            "modifier": "none",
            "destruct": null,
            "default": null
          }
        ],
        "returnType": {
          "named": "P"
        },
        "typeGuardParam": null,
        "body": [
          {
            "expr": {
              "jump": {
                "loc": {
                  "line": 1,
                  "col": 19
                },
                "kind": {
                  "return": {
                    "call": {
                      "loc": {
                        "line": 1,
                        "col": 26
                      },
                      "kind": {
                        "call": {
                          "receiver": null,
                          "callee": "P",
                          "is_builtin": false,
                          "is_tagged": false,
                          "optional": false,
                          "args": [
                            {
                              "label": "...",
                              "value": {
                                "identifier": {
                                  "loc": {
                                    "line": 1,
                                    "col": 30
                                  },
                                  "kind": {
                                    "ident": "o"
                                  }
                                }
                              },
                              "comments": [],
                              "is_default_inj": false
                            },
                            {
                              "label": "a",
                              "value": {
                                "literal": {
                                  "loc": {
                                    "line": 1,
                                    "col": 36
                                  },
                                  "kind": {
                                    "numberLit": "1"
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