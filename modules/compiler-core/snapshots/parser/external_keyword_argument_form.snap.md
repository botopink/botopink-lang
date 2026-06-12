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
        "name": "reverse",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [
          {
            "name": "external",
            "args": [
              "Target.Erlang",
              "\"lists\"",
              "\"reverse(self)\""
            ],
            "is_builtin": true
          }
        ],
        "genericParams": [],
        "params": [
          {
            "name": "self",
            "typeRef": {
              "generic": {
                "name": "Array",
                "args": [
                  {
                    "named": "i32"
                  }
                ],
                "is_builtin": false
              }
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
                "named": "i32"
              }
            ],
            "is_builtin": false
          }
        },
        "body": []
      }
    }
  ]
}
```