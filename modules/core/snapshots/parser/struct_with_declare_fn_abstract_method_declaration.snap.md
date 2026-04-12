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
              "returnType": {
                "named": "number"
              },
              "body": null,
              "is_default": false,
              "is_declare": true,
              "isPub": false
            }
          }
        ]
      }
    }
  ]
}