{%- set group = 'atlassian' %}
{%- set atlassian_home = '/opt/atlassian' %}
{%- set default_path = atlassian_home ~ '/core-dumps' %}
{%- set core_dump_path = salt['pillar.get']('core_dump_store', default_path) %}

core-dump-store:
  file.directory:
    - name: {{ core_dump_path }}
    - makedirs: True
    - user: root
    - group: {{ group }}
    - dir_mode: 770
    - file_mode: 660
    - recurse:
        - user
        - group
        - mode
  cmd.run:
    - name: 'echo "{{ core_dump_path}}/core.%e.%p" > /proc/sys/kernel/core_pattern'
