# common core all Atlassian apps need

{%- set home = '/opt/atlassian' %}
{%- set group = 'atlassian' %}


atlassian:
  file.directory:
    - name: {{ home }}
    - user: root
    - group: {{ group }}
    - mode: 750
    - require:
        - group: atlassian
  group.present:
    - name: {{ group }}
