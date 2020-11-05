{% if salt['grains.get']('bootstrap') and not salt['grains.get']('vaultwritten')%}
{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot + '/map.bootstrap.jinja' import consulbootstrap with context -%}
{%- set tenant_name = salt['pillar.get']('tenant_name') -%}


{%- if salt['file.file_exists' ]('/etc/consul.d/outputs/consul_agent_token.json.out') %}
{%- import_json '/etc/consul.d/outputs/consul_agent_token.json.out' as agent_json -%}
{%- set vault_content_agent = agent_json.SecretID -%}
vault-write-agent-token:
  module.run:
    - vault.write_secret:
      - path: 'kv/data/tenants/lab_k8s_teeuwes/bootstrap/moduletest/consul_agent_token'
      - data:
          id: {{ vault_content_agent }}
{% endif %}

{%- if salt['file.file_exists' ]('/etc/consul.d/outputs/consul_anon_token.json.out') %}
{%- import_json '/etc/consul.d/outputs/consul_anon_token.json.out' as anon_json -%}
{%- set vault_content_anon = anon_json.SecretID -%}
vault-write-anon-token:
  module.run:
    - vault.write_secret:
      - path: 'kv/data/tenants/lab_k8s_teeuwes/bootstrap/moduletest/consul_anon_token'
      - data:
          id: {{ vault_content_anon }}
{% endif %}

{%- if salt['file.file_exists' ]('/etc/consul.d/outputs/consul_vault_token.json.out') %}
{%- import_json '/etc/consul.d/outputs/consul_vault_token.json.out' as vault_json -%}
{%- set vault_content_vault = vault_json.SecretID -%}
vault-write-vault-token:
  module.run:
    - vault.write_secret:
      - path: 'kv/data/tenants/lab_k8s_teeuwes/bootstrap/moduletest/consul_vault_token'
      - data:
          id: {{ vault_content_vault }}
{% endif %}

{%- if salt['vault.read_secret']('kv/data/tenants/lab_k8s_teeuwes/bootstrap/moduletest/consul_vault_token') %}
set-bootstrap-grain:
  grains.present:
    - name: vaultwritten
    - value: True
{% endif %}

{% endif %}
