{%- set default_sources = {'module' : ['okta', 'pam'], 'defaults' : True, 'pillar' : True, 'grains' : ['os_family']} %}
{% from "extra_formulas_common/load_config.jinja" import config as okta_pam with context -%}

{% if okta_pam.use is defined -%}

{% if okta_pam.use|to_bool -%}

okta-pam-gpg-key:
  rpm_.imported_gpg_key:
    - key_path: {{ okta_pam.repo_gpgkey }}

okta-pam-repo-installed:
  pkgrepo.managed:
    - name: {{ okta_pam.repo_name }}
    - humanname: {{ okta_pam.repo_humanname }}
    - baseurl: {{ okta_pam.repo_baseurl }}
    - gpgcheck: 1
    - repo_gpgcheck: 1
    - gpgkey: {{ okta_pam.repo_gpgkey }}
    - require:
      - okta-pam-gpg-key
    - require_in:
      - test: okta-pam-pre-install-done

{%- else -%}

okta-pam-repo-removed:
  pkgrepo.absent:
    - name: {{ okta_pam.repo_name }}
    - require:
      - test: okta-pam-configuration-removed
    - require_in:
      - test: okta-pam-repo-cleaned

{%- endif %}

{%- else -%}

formula-okta_pam-is-disabled:
  test.show_notification:
    - text: |
        The okta.pam module is disabled for this host
        You could enable it by setting the "use" flag in the pillar

{%- endif %}
