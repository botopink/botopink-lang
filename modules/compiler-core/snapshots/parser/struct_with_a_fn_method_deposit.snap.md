```json
{
  "decls": [
    {
      "struct": {
        "name": "Account",
        "id": 1,
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "implement": [],
        "members": [
          {
            "method": {
              "name": "deposit",
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
                },
                {
                  "name": "amount",
                  "typeRef": {
                    "named": "number"
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
                    "binding": {
                      "loc": {
                        "line": 3,
                        "col": 9
                      },
                      "kind": {
                        "assign": {
                          "target": {
                            "fieldAccess": {
                              "receiver": {
                                "identifier": {
                                  "loc": {
                                    "line": 3,
                                    "col": 9
                                  },
                                  "kind": {
                                    "ident": "self"
                                  }
                                }
                              },
                              "field": "_balance"
                            }
                          },
                          "op": "plusAssign",
                          "value": {
                            "identifier": {
                              "loc": {
                                "line": 3,
                                "col": 26
                              },
                              "kind": {
                                "ident": "amount"
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
          }
        ],
        "trailingComma": false
      }
    }
  ]
}
```