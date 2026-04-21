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
        "members": [
          {
            "method": {
              "name": "deposit",
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
                },
                {
                  "name": "amount",
                  "typeRef": {
                    "named": "number"
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
                    "binding": {
                      "loc": {
                        "line": 3,
                        "col": 9
                      },
                      "kind": {
                        "fieldPlusEq": {
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
                          "field": "_balance",
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