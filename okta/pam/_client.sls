{%- set default_sources = {'module' : ['okta', 'pam'], 'defaults' : True, 'pillar' : True, 'grains' : ['os_family']} %}
{% from "extra_formulas_common/load_config.jinja" import config as okta_pam with context -%}

{% if okta_pam.use is defined -%}

{% if okta_pam.use|to_bool -%}

# Do installation

{%- else -%}

# Do uninstallation

{%- endif %}

{%- else -%}

formula-okta_pam-is-disabled:
  test.show_notification:
    - text: |
        The okta.pam module is disabled for this host
        You could enable it by setting the "use" flag in the pillar

{%- endif %}
