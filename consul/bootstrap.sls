{% if not salt['grains.get']('bootstrap') %}

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot + '/map.bootstrap.jinja' import consulbootstrap with context -%}
{%- set tenant_name = salt['pillar.get']('tenant_name') -%}

bootstrap-config:
  file.serialize:
    - name: /etc/consul.d/config.json
    - encoding: utf-8
    - formatter: json
    - dataset: {{ consulbootstrap.config | json }}
    - user: {{ consulbootstrap.user }}
    - group: {{ consulbootstrap.group }}
    - mode: '0640'

output-dir:
  file.directory:
    - name: /etc/consul.d/outputs
    - user: {{ consulbootstrap.user }}
    - group: {{ consulbootstrap.group }}
    - mode: '0750'

{% for file in salt['cp.list_master'](prefix=tplroot ~'/files/policies', saltenv=tenant_name) %}
bootstrap-file-{{ file.split("/")[3] }}:
  file.managed:
    - name: /etc/consul.d/policies/{{ file.split("/")[3] }}
    - makedirs: True
    - source: salt://{{ file }}
{% endfor %}

{% for file in salt['cp.list_master'](prefix=tplroot ~'/files/tokens', saltenv=tenant_name) %}
bootstrap-file-{{ file.split("/")[3] }}:
  file.managed:
    - name: /etc/consul.d/tokens/{{ file.split("/")[3] }}
    - makedirs: True
    - source: salt://{{ file }}
{% endfor %}

{% for file in salt['cp.list_master'](prefix=tplroot ~'/files/policies', saltenv=tenant_name) %}
bootstrap-query-{{ file.split("/")[3] }}:
  http.query:
    - name: "https://{{ salt['grains.get']('primary_ipaddress') }}:8501/v1/acl/policy"
    - ca_bundle: /etc/consul.d/certs/ca.crt
    - method: PUT
    - header_dict: 
        X-Consul-Token: {{ consulbootstrap.master_token }}
    - data_file: /etc/consul.d/policies/{{ file.split("/")[3] }}
    - status: 200
{% endfor %}

{% for file in salt['cp.list_master'](prefix=tplroot ~'/files/tokens', saltenv=tenant_name) %}
bootstrap-query-{{ file.split("/")[3] }}:
  http.query:
    - name: "https://{{ salt['grains.get']('primary_ipaddress') }}:8501/v1/acl/token"
    - ca_bundle: /etc/consul.d/certs/ca.crt
    - method: PUT
    - header_dict: 
        X-Consul-Token: {{ consulbootstrap.master_token }}
    - data_file: /etc/consul.d/tokens/{{ file.split("/")[3] }}
    - text_out: "/etc/consul.d/outputs/{{ file.split("/")[3] }}.out"
    - status: 200
{% endfor %}

set-bootstrap-grain:
  grains.present:
    - name: bootstrap
    - value: True
    - onlyif:
      - test -f /etc/consul.d/outputs/consul_agent_token.json.out
      - test -f /etc/consul.d/outputs/consul_anon_token.json.out
      - test -f /etc/consul.d/outputs/consul_vault_token.json.out
  module.run:
    - state.apply:
    - onlyif:
      - test -f /etc/consul.d/outputs/consul_agent_token.json.out
      - test -f /etc/consul.d/outputs/consul_anon_token.json.out
      - test -f /etc/consul.d/outputs/consul_vault_token.json.out

{% endif %}
