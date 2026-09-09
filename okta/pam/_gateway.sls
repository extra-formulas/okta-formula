{%- set default_sources = {'module' : ['okta', 'pam'], 'defaults' : True, 'pillar' : True, 'grains' : ['os_family']} %}
{% from "extra_formulas_common/load_config.jinja" import config as okta_pam with context -%}

{% if okta_pam.use is defined -%}

{% if okta_pam.use|to_bool -%}

okta-pam-gateway-installed:
  pkg.installed:
    - name: {{ okta_pam.gateway_package_name }}
    - require:
      - test: okta-pam-pre-install-done
    - require_in:
      - test: okta-pam-install-completed

{% if okta_pam.gateway_config is defined -%}
okta-pam-gateway-config-file:
  file.serialize:
    - name: {{ okta_pam.config_dir }}/sft-gatewayd.yaml
    - dataset: {{ okta_pam.gateway_config|json }}
    - serializer: yaml
    - makedirs: true
    - require:
      - test: okta-pam-install-completed
    - watch_in:
      - test: okta-pam-configuration-set
{%- endif %}

okta-pam-gateway-running:
  service.running:
    - name: {{ okta_pam.gateway_service_name }}
    - enable: True
    - watch:
      - test: okta-pam-configuration-set
    - require_in:
      - test: okta-pam-related-services-running

okta-pam-host-enrolled:
  file.managed:
    - name: {{ okta_pam.gateway_enrollment_dir }}/enrollment.token
    - contents: {{ okta_pam.gateway_enrollment_token }}
    - show_changes: False
    - onlyif:
      - test ! -f {{ okta_pam.gateway_enrollment_dir }}/device.token
    - require:
      - test: okta-pam-related-services-running
    - require_in:
      - test: okta-pam-related-services-configured

{%- else -%}

okta-pam-gateway-stopped:
  service.dead:
    - name: {{ okta_pam.gateway_service_name }}
    - enable: False
    - require_in:
      - test: okta-pam-related-services-stopped

okta-pam-gateway-removed:
  pkg.removed:
    - name: {{ okta_pam.gateway_package_name }}
    - require:
      - test: okta-pam-related-services-stopped
    - require_in:
      - test: okta-pam-uninstall-completed

okta-pam-gateway-unenrolled:
  file.absent:
    - name: {{ okta_pam.gateway_enrollment_dir }}
    - require:
      - test: okta-pam-uninstall-completed
    - require_in:
      - test: okta-pam-configuration-removed

okta-pam-config-deleted:
  file.absent:
    - name: {{ okta_pam.config_dir }}
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
