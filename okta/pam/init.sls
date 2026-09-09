{%- set default_sources = {'module' : ['okta', 'pam'], 'defaults' : False, 'pillar' : True, 'grains' : []} %}
{% from "extra_formulas_common/load_config.jinja" import config as okta_pam with context -%}

{% if okta_pam.use is defined -%}

{% if okta_pam.use|to_bool -%}

okta-pam-pre-install-done: test.nop

okta-pam-install-completed:
  test.nop:
    - require:
      - test: okta-pam-pre-install-done

okta-pam-configuration-set:
  test.nop:
    - require:
      - test: okta-pam-install-completed

okta-pam-related-services-running:
  test.nop:
    - require:
      - test: okta-pam-configuration-set

okta-pam-related-services-configured:
  test.nop:
    - require:
      - test: okta-pam-related-services-running

{%- else -%}

okta-pam-related-services-stopped: test.nop

okta-pam-uninstall-completed:
  test.nop:
    - require:
      - test: okta-pam-related-services-stopped

okta-pam-configuration-removed:
  test.nop:
    - require:
      - test: okta-pam-uninstall-completed

okta-pam-repo-cleaned:
  test.nop:
    - require:
      - test: okta-pam-configuration-removed

{%- endif %}

# Including modular states: repo, agent, and client

{%- set includes = [] %}
{%- set os_family = grains['os_family']|lower %}
{% if os_family == 'redhat' -%}
{%- do includes.append('._repo-redhat') %}
{%- elif os_family == 'debian' -%}
{%- do includes.append('._repo-debian') %}
{%- endif %}
{% if okta_pam.gateway_enrollment_token|default('')|length > 0 -%}
{%- do includes.append('._gateway') %}
{%- endif %}
{% if okta_pam.agent_enrollment_token|default('')|length > 0 -%}
{%- do includes.append('._agent') %}
{%- endif %}
{% if okta_pam.use_client|default(false)|to_bool -%}
{%- do includes.append('._client') %}
{%- endif %}

{% if includes|length > 0 -%}
{{ {'include': includes}|yaml(False) }}
{%- endif %}

{%- else -%}

formula-okta_pam-is-disabled:
  test.show_notification:
    - text: |
        The okta.pam module is disabled for this host
        You could enable it by setting the "use" flag in the pillar

{%- endif %}
