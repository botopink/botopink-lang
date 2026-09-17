```json
{
  "decls": [
    {
      "type_": {
        "name": "A",
        "id": 1,
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "implement": [],
        "shape": {
          "record": [
            {
              "name": "x",
              "typeRef": {
                "named": "i32"
              },
              "default": null,
              "annotations": []
            }
          ]
        },
        "trailingComma": false,
        "methods": []
      }
    },
    {
      "behavior": {
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
      "type_": {
        "name": "B",
        "id": 2,
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "implement": [],
        "shape": {
          "record": [
            {
              "name": "y",
              "typeRef": {
                "named": "i32"
              },
              "default": null,
              "annotations": []
            }
          ]
        },
        "trailingComma": false,
        "methods": []
      }
    },
    {
      "type_": {
        "name": "E",
        "id": 3,
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "implement": [],
        "shape": {
          "enum_": {
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
            "sections": []
          }
        },
        "trailingComma": false,
        "methods": []
      }
    }
  ]
}
```