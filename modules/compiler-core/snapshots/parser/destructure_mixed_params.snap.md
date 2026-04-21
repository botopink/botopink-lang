```json
{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "name": "process",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "prefix",
            "typeRef": {
              "named": "string"
            },
            "typeName": "",
            "modifier": "none",
            "typeinfoConstraints": null,
            "fnType": null,
            "destruct": null,
            "defaultVal": null
          },
          {
            "name": "",
            "typeRef": {
              "named": "Person"
            },
            "typeName": "Person",
            "modifier": "none",
            "typeinfoConstraints": null,
            "fnType": null,
            "destruct": {
              "names": {
                "fields": [
                  {
                    "field_name": "name",
                    "bind_name": "name"
                  }
                ],
                "hasSpread": false
              }
            },
            "defaultVal": null
          }
        ],
        "returnType": {
          "named": "string"
        },
        "body": [
          {
            "expr": {
              "controlFlow": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "identifier": {
                      "loc": {
                        "line": 2,
                        "col": 12
                      },
                      "kind": {
                        "ident": "prefix"
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