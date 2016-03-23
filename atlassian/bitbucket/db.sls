{# the intention with this formula, is to run this on the master, not the web node #}
{%- set dbname = salt['pillar.get']('atlassian:bitbucket:db:name', 'bitbucket') %}
{%- set user = salt['pillar.get']('atlassian:bitbucket:db:user', 'bitbucket') %}
{%- set pass = salt['pillar.get']('atlassian:bitbucket:db:pass', 'bitbucket') %}
{%- set host = salt['pillar.get']('atlassian:bitbucket:db:host', 'localhost') %}

{%- set db_user = salt['pillar.get']('db_super:user', 'super') %}
{%- set db_pass = salt['pillar.get']('db_super:pass', 'FOOBAR') %}

bitbucket-db:
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
        - pkg: bitbucket-db
  postgres_database.present:
    - name: {{ dbname }}
    - owner: {{ db_user }}
    - encoding: 'UTF8'
    # connection info to create this resource
    - db_user: {{ db_user }}
    - db_password: {{ db_pass }}
    - db_host: {{ host }}
    - require:
        - postgres_user: bitbucket-db
  cmd.run:
    - name: "echo \"please run the following: psql --host {{ host }} --username {{ db_user }} 'GRANT ALL PRIVILEGES ON DATABASE {{ dbname }} TO {{ user }};'\""
    - require:
        - postgres_database: bitbucket-db
