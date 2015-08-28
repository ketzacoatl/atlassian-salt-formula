# This will rm files older than 1 month
{%- set build_dir = "/opt/atlassian/bamboo-agent/bamboo-agent-home/xml-data/build-dir/" %}
{%- set days = "30" %}

cleanup-build_dir:
  cron.present:
    - name: 'find {{ build_dir }} -ctime +{{ days }} -daystart -exec ls -alh "{}" \;'
    - identifier: cleanup-build-dir
    - user: root
    - minute: 0
    - hour: 0
