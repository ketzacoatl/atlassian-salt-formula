{%- set local_port = salt['pillar.get']('atlassian:bamboo:local_port', '8085') -%}

ufw-allow-bamboo:
  file.managed:
    - name: /etc/ufw/applications.d/bamboo.ufw
    - source: salt://atlassian/files/ufw/applications.d/app_config.jinja
    - user: root
    - group: root
    - mode: 0640
    - template: jinja
    - context:
        app: Bamboo
        title: Atlassian Bamboo
        description: Bamboo Continuous Awesome Sauce
        ports: '{{ local_port }}/tcp'
  cmd.run:
    - name: 'ufw allow bamboo'
    - watch:
        - file: ufw-allow-bamboo
