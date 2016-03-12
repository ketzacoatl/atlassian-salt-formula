{#- formula for backing up and restoring important files to s3 bucket -#}
{%- set cron_minute = salt['pillar.get']('atlassian:jira:backup:minute', '0') %}
{%- set cron_hour = salt['pillar.get']('atlassian:jira:backup:hour', '*') %}
{%- set cron_daymonth = salt['pillar.get']('atlassian:jira:backup:daymonth', '*') %}
{%- set cron_month = salt['pillar.get']('atlassian:jira:backup:month', '*') %}
{%- set cron_dayweek = salt['pillar.get']('atlassian:jira:backup:dayweek', '*') %}

s3-backup:
  file.managed:
    - name: /usr/local/bin/s3-backup.sh
    - source: salt://atlassian/files/jira/s3-backup.sh
    - user: root
    - group: root
    - mode: 750
    - template: jinja
  cron.present:
    - name: /usr/local/bin/s3-backup.sh
    - identifier: S3_BACKUP
    - user: root
    - minute: '{{ cron_minute }}'
    - hour: '{{ cron_hour }}'
    - daymonth: '{{ cron_daymonth }}'
    - month: '{{ cron_month }}'
    - dayweek: '{{ cron_dayweek }}'
    - comment: "Hourly backup of jira database and data directory"

s3-restore:
  file.managed:
    - name: /usr/local/bin/s3-restore.sh
    - source: salt://atlassian/files/jira/s3-restore.sh
    - user: root
    - group: root
    - mode: 750
    - template: jinja

s3-migrate:
  file.managed:
    - name: /usr/local/bin/s3-migrate.sh
    - source: salt://atlassian/files/jira/s3-migrate.sh
    - user: root
    - group: root
    - mode: 750
    - template: jinja
