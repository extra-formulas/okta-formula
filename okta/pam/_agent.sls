{%- set default_sources = {'module' : ['okta', 'pam'], 'defaults' : True, 'pillar' : True, 'grains' : ['os_family']} %}
{% from "extra_formulas_common/load_config.jinja" import config as okta_pam with context -%}

{% if okta_pam.use is defined -%}

{% if okta_pam.use|to_bool -%}

{% if (okta_pam.agent_configs is defined) and (grains['host']|default('')|length > 0) -%}
{%- set host_name = grains['host'].split('.')[0] %}
{% if host_name in okta_pam.agent_configs -%}
okta-pam-config-file:
  file.managed:
    - name: {{ okta_pam.asa_config_dir }}/sftd.yaml
    - content: |
      {{ okta_pam.agent_configs[host_name]|default({})|yaml }}
    - makedirs: true
    - require_in:
      - test: okta-pam-pre-install-done
{%- endif %}
{%- endif %}

okta-pam-agent-installed:
  pkg.installed:
    - name: {{ okta_pam.agent_package_name }}
    - require:
      - test: okta-pam-pre-install-done
    - require_in:
      - test: okta-pam-install-completed

okta-pam-agent-running:
  service.running:
    - name: {{ okta_pam.agent_service_name }}
    - enable: True
    - require_in:
      - test: okta-pam-related-services-running
    - watch:
      - test: okta-pam-related-services-configured

okta-pam-host-enrolled:
  file.managed:
    - name: {{ okta_pam.agent_enrollment_dir }}/enrollment.token
    - contents: {{ okta_pam.agent_enrollment_token }}
    - onlyif:
      - test ! -f {{ okta_pam.agent_enrollment_dir }}/device.token
    - require_in:
      - test: okta-pam-related-services-configured

{%- else -%}

okta-pam-agent-stopped:
  service.dead:
    - name: {{ okta_pam.agent_service_name }}
    - enable: False
    - require_in:
      - test: okta-pam-related-services-stopped

okta-pam-agent-removed:
  pkg.removed:
    - name: {{ okta_pam.agent_package_name }}
    - require_in:
      - test: okta-pam-uninstall-completed

okta-pam-agent-unenrolled:
  file.absent:
    - name: {{ okta_pam.agent_enrollment_dir }}
    - require_in:
      - test: okta-pam-configuration-removed

okta-pam-config-deleted:
  file.absent:
    - name: {{ okta_pam.asa_config_dir }}
    - require_in:
      - test: okta-pam-configuration-removed

{%- endif %}

{%- else -%}

formula-okta_pam-is-disabled:
  test.show_notification:
    - text: |
        The okta.pam module is disabled for this host
        You could enable it by setting the "use" flag in the pillar

{%- endif %}
