{# the intention with this formula, is to run this on the master, not the web node #}
{%- set dbname = salt['pillar.get']('atlassian:stash:db:name', 'stash') %}
{%- set user = salt['pillar.get']('atlassian:stash:db:user', 'stash') %}
{%- set pass = salt['pillar.get']('atlassian:stash:db:pass', 'stash') %}
{%- set host = salt['pillar.get']('atlassian:stash:db:host', 'localhost') %}

{%- set db_user = salt['pillar.get']('db_super:user', 'super') %}
{%- set db_pass = salt['pillar.get']('db_super:pass', 'FOOBAR') %}

stash-db:
  pkg.installed:
    - name: postgresql-client
  postgres_user.present:
    - name: {{ user }}
    - password: {{ pass }}
    - refresh_password: True
    - createuser: False
    # connection info to create this resource
    - db_user: {{ db_user }}
    - db_password: {{ db_pass }}
    - db_host: {{ host }}
    - require:
        - pkg: stash-db
  postgres_database.present:
    - name: {{ dbname }}
    - owner: {{ db_user }}
    - encoding: 'UTF8'
    # connection info to create this resource
    - db_user: {{ db_user }}
    - db_password: {{ db_pass }}
    - db_host: {{ host }}
    - require:
        - postgres_user: stash-db
  cmd.run:
    - name: "echo \"please run the following: psql --host {{ host }} --username {{ db_user }} 'GRANT ALL PRIVILEGES ON DATABASE {{ name }} TO {{ user }};'\""
    - require:
        - postgres_database: stash-db
