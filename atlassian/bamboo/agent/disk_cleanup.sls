# This will rm files older than 1 month
{%- set build_dir = "/opt/atlassian/bamboo-agent/bamboo-agent-home/xml-data/build-dir/" %}
{%- set days = salt['pillar.get']('bamboo_agent:disk_cleanup:cache_days', '30') %}
{%- set minute = salt['pillar.get']('bamboo_agent:disk_cleanup:cron_minute', '0') %}
{%- set hour = salt['pillar.get']('bamboo_agent:disk_cleanup:cron_hour', '0') %}

cleanup-build_dir:
  cron.present:
    - name: 'find {{ build_dir }} -type f -ctime +{{ days }} -daystart -exec rm "{}" \;'
    - identifier: cleanup-build-dir
    - user: root
    - minute: '{{ minute }}'
    - hour: '{{ hour }}'
