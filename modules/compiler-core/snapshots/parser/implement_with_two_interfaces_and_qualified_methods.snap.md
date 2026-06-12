```json
{
  "decls": [
    {
      "implement": {
        "name": "CameraPowerCharger",
        "isPub": false,
        "shorthand": false,
        "genericParams": [],
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "interfaces": [
          {
            "named": "UsbCharger"
          },
          {
            "named": "SolarCharger"
          }
        ],
        "target": "SmartCamera",
        "methods": [
          {
            "qualifier": "UsbCharger",
            "name": "Conectar",
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
            "body": [
              {
                "expr": {
                  "call": {
                    "loc": {
                      "line": 3,
                      "col": 17
                    },
                    "kind": {
                      "call": {
                        "receiver": {
                          "identifier": {
                            "loc": {
                              "line": 3,
                              "col": 9
                            },
                            "kind": {
                              "ident": "Console"
                            }
                          }
                        },
                        "callee": "WriteLine",
                        "is_builtin": false,
                        "is_tagged": false,
                        "optional": false,
                        "args": [
                          {
                            "label": null,
                            "value": {
                              "binaryOp": {
                                "loc": {
                                  "line": 3,
                                  "col": 64
                                },
                                "op": "add",
                                "lhs": {
                                  "literal": {
                                    "loc": {
                                      "line": 3,
                                      "col": 27
                                    },
                                    "kind": {
                                      "stringLit": "Conectado via USB. Bateria atual: "
                                    }
                                  }
                                },
                                "rhs": {
                                  "identifier": {
                                    "loc": {
                                      "line": 3,
                                      "col": 71
                                    },
                                    "kind": {
                                      "identAccess": {
                                        "receiver": {
                                          "identifier": {
                                            "loc": {
                                              "line": 3,
                                              "col": 66
                                            },
                                            "kind": {
                                              "ident": "self"
                                            }
                                          }
                                        },
                                        "member": "batteryLevel",
                                        "optional": false
                                      }
                                    }
                                  }
                                }
                              }
                            },
                            "comments": []
                          }
                        ],
                        "trailing": []
                      }
                    }
                  }
                },
                "emptyLinesBefore": 0
              }
            ]
          },
          {
            "qualifier": "SolarCharger",
            "name": "Conectar",
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
            "body": [
              {
                "expr": {
                  "call": {
                    "loc": {
                      "line": 6,
                      "col": 17
                    },
                    "kind": {
                      "call": {
                        "receiver": {
                          "identifier": {
                            "loc": {
                              "line": 6,
                              "col": 9
                            },
                            "kind": {
                              "ident": "Console"
                            }
                          }
                        },
                        "callee": "WriteLine",
                        "is_builtin": false,
                        "is_tagged": false,
                        "optional": false,
                        "args": [
                          {
                            "label": null,
                            "value": {
                              "binaryOp": {
                                "loc": {
                                  "line": 6,
                                  "col": 73
                                },
                                "op": "add",
                                "lhs": {
                                  "literal": {
                                    "loc": {
                                      "line": 6,
                                      "col": 27
                                    },
                                    "kind": {
                                      "stringLit": "Conectado via Painel Solar. Bateria atual: "
                                    }
                                  }
                                },
                                "rhs": {
                                  "identifier": {
                                    "loc": {
                                      "line": 6,
                                      "col": 80
                                    },
                                    "kind": {
                                      "identAccess": {
                                        "receiver": {
                                          "identifier": {
                                            "loc": {
                                              "line": 6,
                                              "col": 75
                                            },
                                            "kind": {
                                              "ident": "self"
                                            }
                                          }
                                        },
                                        "member": "batteryLevel",
                                        "optional": false
                                      }
                                    }
                                  }
                                }
                              }
                            },
                            "comments": []
                          }
                        ],
                        "trailing": []
                      }
                    }
                  }
                },
                "emptyLinesBefore": 0
              }
            ]
          }
        ]
      }
    }
  ]
}
```