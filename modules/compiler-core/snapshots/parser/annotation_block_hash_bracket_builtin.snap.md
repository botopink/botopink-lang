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
        "name": "length",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [
          {
            "name": "external",
            "args": [
              ".Erlang(\"string:length($0)\")",
              ".JavaScript(\"./gleam_stdlib.mjs\", \"string_length\")"
            ],
            "is_builtin": false
          }
        ],
        "genericParams": [],
        "params": [
          {
            "name": "s",
            "typeRef": {
              "named": "string"
            },
            "typeName": "",
            "modifier": "none",
            "destruct": null,
            "default": null
          }
        ],
        "returnType": {
          "named": "i32"
        },
        "typeGuardParam": null,
        "body": []
      }
    },
    {
      "use": {
        "imports": [
          {
            "segments": [
              "compiler"
            ],
            "activate": false,
            "alias": null
          }
        ],
        "source": {
          "module": "std"
        },
        "package": null,
        "activationOnly": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null
      }
    }
  ]
}
```