{
  "decls": [
    {
      "record": {
        "name": "Point",
        "id": 1,
        "isPub": false,
        "annotations": [],
        "genericParams": [],
        "fields": [
          {
            "name": "x",
            "typeRef": {
              "named": "number"
            },
            "default": null
          }
        ],
        "methods": [
          {
            "name": "show",
            "genericParams": [],
            "params": [
              {
                "name": "self",
                "typeName": "Self",
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
                    "line": 4,
                    "col": 9
                  },
                  "kind": {
                    "return": {
                      "loc": {
                        "line": 4,
                        "col": 16
                      },
                      "kind": {
                        "identAccess": {
                          "receiver": {
                            "loc": {
                              "line": 4,
                              "col": 16
                            },
                            "kind": {
                              "ident": "self"
                            }
                          },
                          "member": "x"
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
        ]
      }
    }
  ]
}