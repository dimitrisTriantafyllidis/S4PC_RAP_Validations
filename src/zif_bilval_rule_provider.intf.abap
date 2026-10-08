INTERFACE zif_bilval_rule_provider
  PUBLIC.

  METHODS get_rules
    IMPORTING checkpoint    TYPE zif_bilval_check=>ty_checkpoint
    RETURNING VALUE(result) TYPE zif_bilval_check=>ty_rules.

  METHODS get_plugins
    IMPORTING checkpoint    TYPE zif_bilval_check=>ty_checkpoint
    RETURNING VALUE(result) TYPE zif_bilval_check=>ty_plugin_cfgs.

ENDINTERFACE.
