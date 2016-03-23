# S3 Backup - Backup and Restore using Amazon S3
{% from "atlassian/backup/maps.jinja" import default_version with context %}

{%- set app = salt['pillar.get']('atlassian:backup:app:name') %}
{%- set version = salt['pillar.get']('atlassian:backup:app:version', default_version[app]) %}
{%- set deploy_env = salt['pillar.get']('atlassian:backup:app:deployment_environment') %}

{%- if deploy_env not in ['production', 'staging'] %}
{{ salt.test.exception('DEPLOY_ENV_ERR: For atlassian:backup:app:deployment_environment, please specify "production" or "staging"') }}
{%- endif %}

{%- set db_user = salt['pillar.get']('atlassian:backup:db:user', app) %}
{%- set db_pass = salt['pillar.get']('atlassian:backup:db:pass', app) %}
{%- set db_name = salt['pillar.get']('atlassian:backup:db:name', app) %}
{%- set db_host = salt['pillar.get']('atlassian:backup:db:host', 'localhost') %}

{%- set default_home = '/opt/atlassian/' ~ app ~ '/current' %}
{%- set default_data = '/opt/atlassian/' ~ app ~ '/data' %}
{%- set app_home = salt['pillar.get']('atlassian:backup:config:home', default_home) %}
{%- set app_data = salt['pillar.get']('atlassian:backup:config:data', default_data) %}
{%- set temp_dir = salt['pillar.get']('atlassian:backup:config:temp_dir', '/opt/atlassian/tmp') %}

{%- set s3_bucket = salt['pillar.get']('atlassian:backup:s3:bucket') %}
{%- set s3_profile = salt['pillar.get']('atlassian:backup:s3:profile') %}

{%- set default_exec_path = '/usr/local/bin/s3-backup.sh' %}
{%- set exec_path = salt['pillar.get']('atlassian:backup:exec_path', default_exec_path) %}

{%- set default_cron_id = 'S3_BACKUP' %}
{%- set cron_id = salt['pillar.get']('atlassian:backup:cron:id', default_cron_id) %}
{%- set cron_minute = salt['pillar.get']('atlassian:backup:cron:minute', '0') %}
{%- set cron_hour = salt['pillar.get']('atlassian:backup:cron:hour', '*') %}
{%- set cron_daymonth = salt['pillar.get']('atlassian:backup:cron:daymonth', '*') %}
{%- set cron_month = salt['pillar.get']('atlassian:backup:cron:month', '*') %}
{%- set cron_dayweek = salt['pillar.get']('atlassian:backup:cron:dayweek', '*') %}


s3-backup:
  file.managed:
    - name: {{ exec_path }}
    - source: salt://atlassian/files/backup/s3-backup.sh
    - user: root
    - group: root
    - mode: 700
    - template: jinja
    - context:
      app: {{ app }}
      version: {{ version }}
      deploy_env: {{ deploy_env }}
      db_user: {{ db_user }}
      db_pass: {{ db_pass }}
      db_name: {{ db_name }}
      db_host: {{ db_host }}
      app_home: {{ app_home }}
      app_data: {{ app_data }}
      temp_dir: {{ temp_dir }}
      s3_bucket: {{ s3_bucket }}
      s3_profile: {{ s3_profile }}

  cron.present:
    - name: {{ exec_path }} -m backup
    - identifier: {{ cron_id }}
    - user: root
    - minute: '{{ cron_minute }}'
    - hour: '{{ cron_hour }}'
    - daymonth: '{{ cron_daymonth }}'
    - month: '{{ cron_month }}'
    - dayweek: '{{ cron_dayweek }}'
    - comment: "Automated backup of {{ app }} database and configuration"
