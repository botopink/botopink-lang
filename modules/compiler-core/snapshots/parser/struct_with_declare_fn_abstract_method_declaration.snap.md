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
                }
              ],
              "returnType": null,
              "body": [],
              "is_default": false,
              "is_declare": false,
              "isPub": false
            }
          },
          {
            "method": {
              "name": "withdraw",
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
                "named": "number"
              },
              "body": null,
              "is_default": false,
              "is_declare": true,
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