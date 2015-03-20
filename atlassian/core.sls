# common stuff all Atlassian apps need

{% from "atlassian/defaults.jinja" import config with context %}
{%- set atlassian_home = '/opt/atlassian' %}
{%- set atlassian_group = 'atlassian' %}


atlassian:
  file.directory:
    - name: {{ atlassian_home }}
    - user: root
    - group: {{ atlassian_group }}
    - mode: 750
    - require:
        - group: atlassian
  group.present:
    - name: {{ atlassian_group }}
