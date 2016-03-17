{#- formula for backing up and restoring important files to s3 bucket -#}

{%- set app = salt['pillar.get']('atlassian:bitbucket:app', 'bitbucket') %}
{%- set version = salt['pillar.get']('atlassian:bitbucket:version', '4.4.1') %}

{%- set db_user = salt['pillar.get']('atlassian:bitbucket:db:user', 'bitbucket') %}
{%- set db_pass = salt['pillar.get']('atlassian:bitbucket:db:pass', 'bitbucket') %}
{%- set db_name = salt['pillar.get']('atlassian:bitbucket:db:name', 'bitbucket') %}
{%- set db_host = salt['pillar.get']('atlassian:bitbucket:db:host', 'localhost') %}

{%- set home_dir = '/opt/atlassian/' ~ app ~ '/current' %}
{%- set data_dir = '/opt/atlassian/' ~ app ~ '/data' %}

{%- set aws_creds = '/usr/local/etc/bucket-info.csv' %}

{%- set cron_minute = salt['pillar.get']('atlassian:bitbucket:backup:minute', '0') %}
{%- set cron_hour = salt['pillar.get']('atlassian:bitbucket:backup:hour', '*') %}
{%- set cron_daymonth = salt['pillar.get']('atlassian:bitbucket:backup:daymonth', '*') %}
{%- set cron_month = salt['pillar.get']('atlassian:bitbucket:backup:month', '*') %}
{%- set cron_dayweek = salt['pillar.get']('atlassian:bitbucket:backup:dayweek', '*') %}

s3-backup:
  file.managed:
    - name: /usr/local/bin/s3-backup.sh
    - source: salt://atlassian/files/bitbucket/s3-backup.sh
    - user: root
    - group: root
    - mode: 750
    - template: jinja
    - context:
        app: {{ app }}
        version: {{ version }}
        db_user: {{ db_user }}
        db_pass: {{ db_pass }}
        db_name: {{ db_name }}
        db_host: {{ db_host }}
        home_dir: {{ home_dir }}
        data_dir: {{ data_dir }}
        aws_creds: {{ aws_creds }}

  cron.present:
    - name: /usr/local/bin/s3-backup.sh
    - identifier: S3_BACKUP
    - user: root
    - minute: '{{ cron_minute }}'
    - hour: '{{ cron_hour }}'
    - daymonth: '{{ cron_daymonth }}'
    - month: '{{ cron_month }}'
    - dayweek: '{{ cron_dayweek }}'
    - comment: "Hourly backup of bitbucket database and data directory"

s3-restore:
  file.managed:
    - name: /usr/local/bin/s3-restore.sh
    - source: salt://atlassian/files/bitbucket/s3-restore.sh
    - user: root
    - group: root
    - mode: 750
    - template: jinja
    - context:
        app: {{ app }}
        db_user: {{ db_user }}
        db_pass: {{ db_pass }}
        db_name: {{ db_name }}
        db_host: {{ db_host }}
        home_dir: {{ home_dir }}
        data_dir: {{ data_dir }}
        aws_creds: {{ aws_creds }}

s3-migrate:
  file.managed:
    - name: /usr/local/bin/s3-migrate.sh
    - source: salt://atlassian/files/bitbucket/s3-migrate.sh
    - user: root
    - group: root
    - mode: 750
    - template: jinja
    - context:
        app: {{ app }}
        home_dir: {{ home_dir }}
        data_dir: {{ data_dir }}
        aws_creds: {{ aws_creds }}
