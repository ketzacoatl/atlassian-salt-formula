ufw-allow-crowd:
  file.managed:
    - name: /etc/ufw/applications.d/crowd.ufw
    - source: salt://atlassian/files/ufw/applications.d/app_config.jinja
    - user: root
    - group: root
    - mode: 0640
    - template: jinja
    - context:
        app: Crowd
        title: Atlassian Crowd
        description: Crowd project management
        ports: '8095/tcp'
  cmd.run:
    - name: 'ufw allow crowd'
    - watch:
        - file: ufw-allow-crowd



