{%- set group = 'atlassian' %}
{%- set atlassian_home = '/opt/atlassian' %}
{%- set app = 'stash' %}
{%- set user = app %}
{%- set home = atlassian_home + '/' + user %}
{%- set version = '3.7.1' %}
{%- set install_to = home + '/release/' + version %}
{%- set active_app = home + '/current' %}
{%- set app_datadir = home + '/data' %}
{%- set backup_root = home + '/backup' %}
{%- set stash_backup_to = backup_root + '/stash_logs' %}
{%- set stash_backup_from = app_datadir + '/log'  %}

stash-log-backup:
  file.directory:
    - name: {{ stash_backup_to }}
    - makedirs: True
    - user: root
    - group: root
    - mode: 750
    - file_mode: 640
    - recurse:
        - user
        - group
        - mode
  cron.present:
    - name: 'rsync -avz {{ stash_backup_from }}/* {{ stash_backup_to }}/'
    - identifier: stash-backup-logs
    - user: root
    - minute: 0
    - hour: 0
    - require:
        - file: stash-log-backup
