{%- set default_sources = {'module' : ['okta', 'pam'], 'defaults' : True, 'pillar' : True, 'grains' : ['os_family']} %}
{% from "extra_formulas_common/load_config.jinja" import config as okta_pam with context -%}

{% if okta_pam.use is defined -%}

{% if okta_pam.use|to_bool -%}

okta-pam-agent-installed:
  pkg.installed:
    - name: {{ okta_pam.agent_package_name }}
    - require:
      - test: okta-pam-pre-install-done
    - require_in:
      - test: okta-pam-install-completed

{% if okta_pam.agent_config is defined -%}
okta-pam-config-file:
  file.managed:
    - name: {{ okta_pam.asa_config_dir }}/sftd.yaml
    - content: |
      {{ okta_pam.agent_config|yaml(False)|indent(6) }}
    - makedirs: true
    - require:
      - test: okta-pam-install-completed
    - require_in:
      - test: okta-pam-configuration-set
{%- endif %}

okta-pam-agent-running:
  service.running:
    - name: {{ okta_pam.agent_service_name }}
    - enable: True
    - watch:
      - test: okta-pam-configuration-set
    - require_in:
      - test: okta-pam-related-services-running

okta-pam-host-enrolled:
  file.managed:
    - name: {{ okta_pam.agent_enrollment_dir }}/enrollment.token
    - contents: {{ okta_pam.agent_enrollment_token }}
    - onlyif:
      - test ! -f {{ okta_pam.agent_enrollment_dir }}/device.token
    - require:
      - test: okta-pam-related-services-running
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
    - require:
      - test: okta-pam-related-services-stopped
    - require_in:
      - test: okta-pam-uninstall-completed

okta-pam-agent-unenrolled:
  file.absent:
    - name: {{ okta_pam.agent_enrollment_dir }}
    - require:
      - test: okta-pam-uninstall-completed
    - require_in:
      - test: okta-pam-configuration-removed

okta-pam-config-deleted:
  file.absent:
    - name: {{ okta_pam.asa_config_dir }}
    - require:
      - test: okta-pam-uninstall-completed
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
