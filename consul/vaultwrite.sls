{% if not salt['grains.get']('bootstrap') %}
{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot + '/map.bootstrap.jinja' import consulbootstrap with context -%}
{%- set tenant_name = salt['pillar.get']('tenant_name') -%}

{%- if salt['file.directory_exists' ]('/etc/consul.d/outputs') %}
{%- import_json '/etc/consul.d/outputs/consul_agent_token.json.out' as agent_json -%}
{%- set vault_content_agent = agent_json.SecretID -%}
{%- import_json '/etc/consul.d/outputs/consul_anon_token.json.out' as anon_json -%}
{%- set vault_content_anon = anon_json.SecretID -%}
{%- import_json '/etc/consul.d/outputs/consul_vault_token.json.out' as vault_json -%}
{%- set vault_content_vault = vault_json.SecretID -%}

vault-write-agent-token:
  module.run:
    - vault.write_secret:
      - path: 'kv/data/tenants/lab_k8s_teeuwes/bootstrap/moduletest/consul_agent_token'
      - data:
          id: {{ vault_content_agent }}

vault-write-anon-token:
  module.run:
    - vault.write_secret:
      - path: 'kv/data/tenants/lab_k8s_teeuwes/bootstrap/moduletest/consul_anon_token'
      - data:
          id: {{ vault_content_anon }}

vault-write-vault-token:
  module.run:
    - vault.write_secret:
      - path: 'kv/data/tenants/lab_k8s_teeuwes/bootstrap/moduletest/consul_vault_token'
      - data:
          id: {{ vault_content_vault }}

{% endif %}
{% endif %}
