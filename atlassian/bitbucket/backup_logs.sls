{%- set group = 'atlassian' %}
{%- set atlassian_home = '/opt/atlassian' %}
{%- set app = 'bitbucket' %}
{%- set user = app %}
{%- set home = atlassian_home + '/' + user %}
{%- set version = '4.4.1' %}
{%- set install_to = home + '/release/' + version %}
{%- set active_app = home + '/current' %}
{%- set app_datadir = home + '/data' %}
{%- set backup_root = home + '/backup' %}
{%- set bitbucket_backup_to = backup_root + '/bitbucket_logs' %}
{%- set bitbucket_backup_from = app_datadir + '/log'  %}

bitbucket-log-backup:
  file.directory:
    - name: {{ bitbucket_backup_to }}
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
    - name: 'rsync -avz {{ bitbucket_backup_from }}/* {{ bitbucket_backup_to }}/'
    - identifier: bitbucket-backup-logs
    - user: root
    - minute: 0
    - hour: 0
    - require:
        - file: bitbucket-log-backup
