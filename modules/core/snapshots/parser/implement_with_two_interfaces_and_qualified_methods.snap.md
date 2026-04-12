{
  "decls": [
    {
      "implement": {
        "name": "CameraPowerCharger",
        "genericParams": [],
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
                "typeName": "Self",
                "modifier": "none",
                "typeinfoConstraints": null,
                "fnType": null,
                "destruct": null
              }
            ],
            "body": [
              {
                "expr": {
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
                            "loc": {
                              "line": 3,
                              "col": 64
                            },
                            "kind": {
                              "add": {
                                "lhs": {
                                  "loc": {
                                    "line": 3,
                                    "col": 27
                                  },
                                  "kind": {
                                    "stringLit": "Conectado via USB. Bateria atual: "
                                  }
                                },
                                "rhs": {
                                  "loc": {
                                    "line": 3,
                                    "col": 66
                                  },
                                  "kind": {
                                    "identAccess": {
                                      "receiver": {
                                        "loc": {
                                          "line": 3,
                                          "col": 66
                                        },
                                        "kind": {
                                          "ident": "self"
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
                      ],
                      "trailing": []
                    }
                  }
                }
              }
            ]
          },
          {
            "qualifier": "SolarCharger",
            "name": "Conectar",
            "params": [
              {
                "name": "self",
                "typeName": "Self",
                "modifier": "none",
                "typeinfoConstraints": null,
                "fnType": null,
                "destruct": null
              }
            ],
            "body": [
              {
                "expr": {
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
                            "loc": {
                              "line": 6,
                              "col": 73
                            },
                            "kind": {
                              "add": {
                                "lhs": {
                                  "loc": {
                                    "line": 6,
                                    "col": 27
                                  },
                                  "kind": {
                                    "stringLit": "Conectado via Painel Solar. Bateria atual: "
                                  }
                                },
                                "rhs": {
                                  "loc": {
                                    "line": 6,
                                    "col": 75
                                  },
                                  "kind": {
                                    "identAccess": {
                                      "receiver": {
                                        "loc": {
                                          "line": 6,
                                          "col": 75
                                        },
                                        "kind": {
                                          "ident": "self"
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
                      ],
                      "trailing": []
                    }
                  }
                }
              }
            ]
          }
        ]
      }
    }
  ]
}