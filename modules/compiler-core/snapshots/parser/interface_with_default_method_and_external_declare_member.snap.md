```json
{
  "decls": [
    {
      "interface": {
        "name": "List",
        "id": 1,
        "isPub": true,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [
          {
            "name": "T"
          }
        ],
        "extends": [],
        "fields": [],
        "trailingComma": false,
        "methods": [
          {
            "name": "isEmpty",
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
            "returnType": {
              "named": "bool"
            },
            "body": [
              {
                "expr": {
                  "jump": {
                    "loc": {
                      "line": 3,
                      "col": 9
                    },
                    "kind": {
                      "return": {
                        "binaryOp": {
                          "loc": {
                            "line": 3,
                            "col": 28
                          },
                          "op": "eq",
                          "lhs": {
                            "identifier": {
                              "loc": {
                                "line": 3,
                                "col": 21
                              },
                              "kind": {
                                "identAccess": {
                                  "receiver": {
                                    "identifier": {
                                      "loc": {
                                        "line": 3,
                                        "col": 16
                                      },
                                      "kind": {
                                        "ident": "self"
                                      }
                                    }
                                  },
                                  "member": "length",
                                  "optional": false
                                }
                              }
                            }
                          },
                          "rhs": {
                            "literal": {
                              "loc": {
                                "line": 3,
                                "col": 31
                              },
                              "kind": {
                                "numberLit": "0"
                              }
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
            "is_default": true,
            "is_declare": false,
            "isPub": false
          },
          {
            "name": "reverse",
            "annotations": [
              {
                "name": "external",
                "args": [
                  "erlang",
                  "\"lists\"",
                  "\"reverse\""
                ],
                "is_builtin": true
              },
              {
                "name": "external",
                "args": [
                  "node",
                  "\"./bp_stdlib.mjs\"",
                  "\"list_reverse\""
                ],
                "is_builtin": true
              }
            ],
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
            "returnType": {
              "generic": {
                "name": "Array",
                "args": [
                  {
                    "named": "T"
                  }
                ],
                "is_builtin": false
              }
            },
            "body": null,
            "is_default": false,
            "is_declare": true,
            "isPub": false
          }
        ]
      }
    }
  ]
}
```