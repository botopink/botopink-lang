```json
{
  "decls": [
    {
      "implement": {
        "name": "CameraPowerCharger",
        "genericParams": [],
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "interfaces": [
          "UsbCharger",
          "SolarCharger"
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
                "typeinfoConstraints": null,
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
                      "col": 9
                    },
                    "kind": {
                      "call": {
                        "receiver": "Console",
                        "callee": "WriteLine",
                        "args": [
                          {
                            "label": null,
                            "value": {
                              "binaryOp": {
                                "loc": {
                                  "line": 3,
                                  "col": 64
                                },
                                "kind": {
                                  "add": {
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
                                          "col": 66
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
                                            "member": "batteryLevel"
                                          }
                                        }
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
                "typeinfoConstraints": null,
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
                      "col": 9
                    },
                    "kind": {
                      "call": {
                        "receiver": "Console",
                        "callee": "WriteLine",
                        "args": [
                          {
                            "label": null,
                            "value": {
                              "binaryOp": {
                                "loc": {
                                  "line": 6,
                                  "col": 73
                                },
                                "kind": {
                                  "add": {
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
                                          "col": 75
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
                                            "member": "batteryLevel"
                                          }
                                        }
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