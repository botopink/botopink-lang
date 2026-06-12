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
        "name": "indexOf",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [
          {
            "name": "External.Erlang",
            "args": [
              "\"lists\"",
              "\"search\"",
              "true"
            ],
            "is_builtin": true
          },
          {
            "name": "External.Node",
            "args": [
              "\"./gleam_stdlib.mjs\"",
              "\"index_of\""
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
            "default": null
          },
          {
            "name": "item",
            "typeRef": {
              "named": "i32"
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": null
          }
        ],
        "returnType": {
          "named": "i32"
        },
        "body": []
      }
    }
  ]
}
```