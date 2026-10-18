```json
{
  "decls": [
    {
      "fn": {
        "isPub": true,
        "effect": null,
        "isDeclare": true,
        "isDefault": false,
        "label": null,
        "name": "absoluteValue",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [
          {
            "name": "external",
            "args": [
              ".Erlang(\"erlang:abs($0)\")"
            ],
            "is_builtin": false
          }
        ],
        "genericParams": [],
        "params": [
          {
            "name": "n",
            "typeRef": {
              "named": "i32"
            },
            "typeName": "",
            "modifier": "none",
            "destruct": null,
            "default": null
          }
        ],
        "returnType": {
          "named": "i32"
        },
        "typeGuardParam": null,
        "body": []
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
        "typeGuardParam": null,
        "body": [
          {
            "expr": {
              "call": {
                "loc": {
                  "line": 5,
                  "col": 5
                },
                "kind": {
                  "call": {
                    "receiver": null,
                    "callee": "absoluteValue",
                    "is_builtin": false,
                    "is_tagged": false,
                    "optional": false,
                    "args": [
                      {
                        "label": null,
                        "value": {
                          "unaryOp": {
                            "loc": {
                              "line": 5,
                              "col": 19
                            },
                            "op": "neg",
                            "expr": {
                              "literal": {
                                "loc": {
                                  "line": 5,
                                  "col": 20
                                },
                                "kind": {
                                  "numberLit": "5"
                                }
                              }
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
        ]
      }
    },
    {
      "use": {
        "imports": [
          {
            "segments": [
              "compiler"
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