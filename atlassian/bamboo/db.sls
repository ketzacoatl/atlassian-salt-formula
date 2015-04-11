{# the intention with this formula, is to run this on the master, not the web node #}
{%- set dbname = salt['pillar.get']('atlassian:bamboo:db:name', 'bamboo') %}
{%- set user = salt['pillar.get']('atlassian:bamboo:db:user', 'bamboo') %}
{%- set pass = salt['pillar.get']('atlassian:bamboo:db:pass', 'bamboo') %}
{%- set host = salt['pillar.get']('atlassian:bamboo:db:host', 'localhost') %}

{%- set db_user = salt['pillar.get']('db_super:user', 'super') %}
{%- set db_pass = salt['pillar.get']('db_super:pass', 'FOOBAR') %}

bamboo-db:
  pkg.installed:
    - name: postgresql-client
  postgres_user.present:
    - name: {{ user }}
    - password: "{{ pass }}"
    - refresh_password: True
    - createuser: False
    # connection info to create this resource
    - db_user: {{ db_user }}
    - db_password: "{{ db_pass }}"
    - db_host: {{ host }}
    - require:
        - pkg: bamboo-db
  postgres_database.present:
    - name: {{ dbname }}
    - owner: {{ db_user }}
    - encoding: 'UTF8'
    # connection info to create this resource
    - db_user: {{ db_user }}
    - db_password: "{{ db_pass }}"
    - db_host: {{ host }}
    - require:
        - postgres_user: bamboo-db
  cmd.run:
    - name: "echo \"please run the following: psql --host {{ host }} --dbname {{ dbname }} --username {{ db_user }} -c 'GRANT ALL PRIVILEGES ON DATABASE {{ dbname }} TO {{ user }};'\""
    - require:
        - postgres_database: bamboo-db
