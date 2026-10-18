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
        "name": "zip",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [
          {
            "name": "external",
            "args": [
              ".Erlang(\"lists:zip($1, $0)\")",
              ".JavaScript(\"./gleam_stdlib.mjs\", \"zip\")"
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
          },
          {
            "name": "other",
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