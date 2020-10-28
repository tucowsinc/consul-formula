{% if not salt['grains.get']('bootstrap') %}

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot + '/map.bootstrap.jinja' import consul with context -%}

bootstrap-config:
  file.serialize:
    - name: /etc/consul.d/bootstrap.json
    - encoding: utf-8
    - formatter: json
    - dataset: {{ consul.config | json }}
    - user: {{ consul.user }}
    - group: {{ consul.group }}
    - mode: '0640'
    - require:
      - user: consul-user
    {%- if consul.service %}
    - watch_in:
       - service: consul
    {%- endif %}

bootstrap-service:
  service.running:
    - name: consul
    - enable: True

bootstrap-out-dir:
  file.directory:
    - name: /etc/consul.d/outputs/
    - user: {{ consul.user }}
    - group: {{ consul.group }}
    - mode: '0640'

{% for file in salt['cp.list_master'](prefix='{{ tplroot }}/files/policies') %}
bootstrap-file-{{ file }}:
  file.managed:
    - name: /etc/consul.d/policies/{{ file }}
    - makedirs: True
    - source: salt://{{ tplroot }}/files/policies/{{ file }}
{% endfor %}

{% for file in salt['cp.list_master'](prefix='{{ tplroot }}/files/tokens') %}
bootstrap-file-{{ file }}:
  file.managed:
    - name: /etc/consul.d/tokens/{{ file }}
    - makedirs: True
    - source: salt://{{ tplroot }}/files/tokens/{{ file }}
{% endfor %}

{% for file in salt['cp.list_master'](prefix='{{ tplroot }}/files/policies') %}
bootstrap-query-{{ file }}:
  http.query:
    - name:  https://{{ salt['grains.get']('primary_ipaddress') }}//v1/acl/policies
    - port: 8501
    - ca_bundle: /etc/consul.d/certs/ca.crt #probably won't work
    - method: PUT
    - headers: True
    - header_list:
      - 'X-Consul-Token: {{ consul.config.acl.tokens.master }}'
    - text_out="/etc/consul.d/outputs/{{ file }}.out"
    - data_file: /etc/consul.d/policies/{{ file }}
    - status: 200
{% endfor %}

{% for file in salt['cp.list_master'](prefix='{{ tplroot }}/files/tokens') %}
bootstrap-query-{{ file }}:
  http.query:
    - name:  https://{{ salt['grains.get']('primary_ipaddress') }}//v1/acl/token
    - port: 8501
    - ca_bundle: /etc/consul.d/certs/ca.crt #probably won't work
    - method: PUT
    - headers: True
    - header_list:
      - 'X-Consul-Token: {{ consul.config.acl.tokens.master }}'
    - data_file: /etc/consul.d/tokens/{{ file }}
    - text_out="/etc/consul.d/outputs/{{ file }}.out"
    - status: 200
{% endfor %}

{% import_json '/etc/consul.d/outputs/consul_agent_token.json.out' as varagenttoken %}

vault-write-agent-token:
  module.run:
    - vault.write_secret:
      - path: kv/data/tenants/{{ pillar['tenant_name'] }}/bootstrap/consul/consul_agent_token
      - id: {{ varagenttoken.SecretID }}

{% import_json '/etc/consul.d/outputs/consul_anon_token.json.out' as varanontoken %}

vault-write-anon-token:
  module.run:
    - vault.write_secret:
      - path: kv/data/tenants/{{ pillar['tenant_name'] }}/bootstrap/consul/consul_anon_token
      - id: {{ varanontoken.SecretID }}

{% import_json '/etc/consul.d/outputs/consul_vault_token.json.out' as varvaulttoken %}

vault-write-vault-token:
  module.run:
    - vault.write_secret:
      - path: kv/data/tenants/{{ pillar['tenant_name'] }}/bootstrap/consul/consul_vault_token
      - id: {{ varvaulttoken.SecretID }}

set-bootstrap-grain:
  grains.present:
    - name: bootstrap
    - value: true

{% endif %}
