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
              ".JavaScript(\"reverse\")",
              ".Erlang(\"lists:reverse($0)\")"
            ],
            "is_builtin": true
          }
        ],
        "genericParams": [],
        "params": [
          {
            "name": "xs",
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
            "destruct": null,
            "default": null
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
        "typeGuardParam": null,
        "body": []
      }
    }
  ]
}
```