{
  "decls": [
    {
      "struct": {
        "name": "Account",
        "id": 1,
        "isPub": false,
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
                  "typeName": "Self",
                  "modifier": "none",
                  "typeinfoConstraints": null,
                  "fnType": null,
                  "destruct": null
                },
                {
                  "name": "amount",
                  "typeName": "number",
                  "modifier": "none",
                  "typeinfoConstraints": null,
                  "fnType": null,
                  "destruct": null
                }
              ],
              "returnType": null,
              "body": [
                {
                  "expr": {
                    "loc": {
                      "line": 3,
                      "col": 9
                    },
                    "kind": {
                      "fieldPlusEq": {
                        "receiver": {
                          "loc": {
                            "line": 3,
                            "col": 9
                          },
                          "kind": {
                            "ident": "self"
                          }
                        },
                        "field": "_balance",
                        "value": {
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
              ],
              "is_default": false,
              "is_declare": false,
              "isPub": false
            }
          }
        ]
      }
    }
  ]
}