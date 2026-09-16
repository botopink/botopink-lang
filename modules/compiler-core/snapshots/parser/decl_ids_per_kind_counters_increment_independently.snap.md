```json
{
  "decls": [
    {
      "record": {
        "name": "A",
        "id": 1,
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "implement": [],
        "fields": [
          {
            "name": "x",
            "typeRef": {
              "named": "i32"
            },
            "default": null,
            "annotations": []
          }
        ],
        "trailingComma": false,
        "methods": []
      }
    },
    {
      "interface": {
        "name": "I",
        "id": 1,
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "extends": [],
        "fields": [],
        "trailingComma": false,
        "methods": [
          {
            "name": "go",
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
                "default": null
              }
            ],
            "returnType": null,
            "body": null,
            "is_default": false,
            "is_declare": false,
            "isPub": false
          }
        ]
      }
    },
    {
      "record": {
        "name": "B",
        "id": 2,
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "implement": [],
        "fields": [
          {
            "name": "y",
            "typeRef": {
              "named": "i32"
            },
            "default": null,
            "annotations": []
          }
        ],
        "trailingComma": false,
        "methods": []
      }
    },
    {
      "enum": {
        "name": "E",
        "id": 1,
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "implement": [],
        "variants": [
          {
            "name": "One",
            "fields": [],
            "numeric": false
          },
          {
            "name": "Two",
            "fields": [],
            "numeric": false
          }
        ],
        "trailingComma": false,
        "methods": [],
        "sections": []
      }
    }
  ]
}
```