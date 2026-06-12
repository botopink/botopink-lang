```json
{
  "decls": [
    {
      "record": {
        "name": "GPSCoordinates",
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
            "name": "lat",
            "typeRef": {
              "named": "number"
            },
            "default": null,
            "annotations": []
          },
          {
            "name": "lon",
            "typeRef": {
              "named": "number"
            },
            "default": null,
            "annotations": []
          }
        ],
        "trailingComma": false,
        "methods": [
          {
            "name": "toString",
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
              "named": "string"
            },
            "body": [
              {
                "expr": {
                  "jump": {
                    "loc": {
                      "line": 5,
                      "col": 9
                    },
                    "kind": {
                      "return": {
                        "binaryOp": {
                          "loc": {
                            "line": 5,
                            "col": 46
                          },
                          "op": "add",
                          "lhs": {
                            "binaryOp": {
                              "loc": {
                                "line": 5,
                                "col": 35
                              },
                              "op": "add",
                              "lhs": {
                                "binaryOp": {
                                  "loc": {
                                    "line": 5,
                                    "col": 24
                                  },
                                  "op": "add",
                                  "lhs": {
                                    "literal": {
                                      "loc": {
                                        "line": 5,
                                        "col": 16
                                      },
                                      "kind": {
                                        "stringLit": "Lat: "
                                      }
                                    }
                                  },
                                  "rhs": {
                                    "identifier": {
                                      "loc": {
                                        "line": 5,
                                        "col": 31
                                      },
                                      "kind": {
                                        "identAccess": {
                                          "receiver": {
                                            "identifier": {
                                              "loc": {
                                                "line": 5,
                                                "col": 26
                                              },
                                              "kind": {
                                                "ident": "self"
                                              }
                                            }
                                          },
                                          "member": "lat",
                                          "optional": false
                                        }
                                      }
                                    }
                                  }
                                }
                              },
                              "rhs": {
                                "literal": {
                                  "loc": {
                                    "line": 5,
                                    "col": 37
                                  },
                                  "kind": {
                                    "stringLit": " Lon: "
                                  }
                                }
                              }
                            }
                          },
                          "rhs": {
                            "identifier": {
                              "loc": {
                                "line": 5,
                                "col": 53
                              },
                              "kind": {
                                "identAccess": {
                                  "receiver": {
                                    "identifier": {
                                      "loc": {
                                        "line": 5,
                                        "col": 48
                                      },
                                      "kind": {
                                        "ident": "self"
                                      }
                                    }
                                  },
                                  "member": "lon",
                                  "optional": false
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "emptyLinesBefore": 0
              }
            ],
            "is_default": false,
            "is_declare": false,
            "isPub": true
          }
        ]
      }
    }
  ]
}
```