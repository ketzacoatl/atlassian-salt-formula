{# the intention with this formula, is to run this on the master, not the web node #}
{%- set dbname = salt['pillar.get']('atlassian:jira:db:name', 'jira') %}
{%- set user = salt['pillar.get']('atlassian:jira:db:user', 'jira') %}
{%- set pass = salt['pillar.get']('atlassian:jira:db:pass', 'jira') %}
{%- set host = salt['pillar.get']('atlassian:jira:db:host', 'localhost') %}

{%- set db_user = salt['pillar.get']('db_super:user', 'super') %}
{%- set db_pass = salt['pillar.get']('db_super:pass', 'FOOBAR') %}

jira-db:
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
        - pkg: jira-db
  postgres_database.present:
    - name: {{ dbname }}
    - owner: {{ db_user }}
    - encoding: 'UTF8'
    # connection info to create this resource
    - db_user: {{ db_user }}
    - db_password: "{{ db_pass }}"
    - db_host: {{ host }}
    - require:
        - postgres_user: jira-db
  cmd.run:
    - name: "echo \"please run the following: psql --host {{ host }} --dbname {{ dbname }} --username {{ db_user }} -c 'GRANT ALL PRIVILEGES ON DATABASE {{ dbname }} TO {{ user }};'\""
    - require:
        - postgres_database: jira-db
